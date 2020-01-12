
Param(
  [Parameter(mandatory)]
  [string]
  $version,

  $dest="build"
)

if ( Test-Path $dest ) {
  Throw "Path '$dest' already exists"
}

$timestamp = Get-Date -Format FileDateTime

function Make-Tmp {

  &{
    pushd $psscriptroot
    try {
      if ( test-path "./.tmp/$timestamp" ) {
        throw "Failed to make temporally directory"
      }
      mkdir "./.tmp/$timestamp"
    } finally { popd }
  } | Out-Null
 
  return "$PSScriptRoot/.tmp/$timestamp"
}

function Clear-Tmp {
  rmdir "$PSScriptRoot/.tmp/$timestamp" -Recurse -Force
}

function Timer-Start {
  $script:stopwatch = [Diagnostics.Stopwatch]::StartNew()
}

function Timer-Stop-Show {
  $script:stopwatch.Stop()
  $elapsedSec = [int]($script:stopwatch.Elapsed.TotalSeconds)
  $elapsedMin = [int]($elapsedSec / 60)
  $elapsedHour = [int]($elapsedMin / 60)
  $elapsedSec %= 60
  $elapsedMin %= 60

  echo "total time : $elapsedHour hr $elapsedMin min $elapsedSec sec"
}


$tmpdir = Make-Tmp

pushd $PSScriptRoot
try {
  if ( -not (Test-Path install.ps1) ) {
    Throw "Cannot find install.ps1 itself"
  }
} finally { popd }

git clone https://github.com/MaskRay/ccls.git "`"$tmpdir`""

pushd $tmpdir
try {
  git reset --hard
  git clean -fdx
  git checkout "$version"
  git submodule init
  git submodule update
  if ($LASTEXITCODE) {
    Clear-Tmp
    Throw "Checking-out to version $version was failed!"
  }
} finally { popd }

if ( Test-Path $dest ) {
  Clear-Tmp
  Throw "$dest cannot be used as a destination"
}

mkdir $dest

Timer-Start
pushd $dest
try {
  cp "$tmpdir/LICENSE" . -Force

  $scoopdir = "$env:UserProfile/scoop"
  $globaldir = "C:/ProgramData/scoop"

  $LLVMAppName = "llvm-clang"

  $ScoopClangPrefixPaths =
    "apps/$LLVMAppName/current/bin",
    "apps/$LLVMAppName/current/tools/clang",
    "apps/$LLVMAppName/current"

  $ClangPrefixes =
    (( $ScoopClangPrefixPaths | %{ "$scoopdir/$_" } ) +
     ( $ScoopClangPrefixPaths | %{ "$globaldir/$_" } ) `
    ) -join ";"

  echo "Prefixes: `"$ClangPrefixes`""

  cmake "-H$tmpdir" "-B." -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_RC_COMPILER=llvm-rc -DCMAKE_CXX_COMPILER=clang-cl "-DCMAKE_PREFIX_PATH=$ClangPrefixes"
  if ($LASTEXITCODE) {
    Throw "CMake was failed!"
  }
  ninja
  if ($LASTEXITCODE) {
    Throw "Ninja was failed!"
  }
} finally { popd }

Timer-Stop-Show

Clear-Tmp

