
Param([parameter(mandatory)][string]$version, $dest="build")

if ( Test-Path $dest ) {
  Throw "$dest already exists"
}

$timestamp = Get-Date -Format FileDateTime

function Make-Tmp {

  &{
    pushd $psscriptroot
      if ( test-path "./.tmp/$timestamp" ) {
        throw "failed to make temporally directory"
      }
      mkdir "./.tmp/$timestamp"
    popd
  } | Out-Null
  
  return "$PSScriptRoot/.tmp/$timestamp"
}

function Clear-Tmp {
  rmdir "$PSScriptRoot/.tmp/$timestamp" -Recurse -Force
}

$tmpdir = Make-Tmp

pushd $PSScriptRoot
  if ( -not (Test-Path install.ps1) ) {
    Throw "Cannot find install.ps1 itself"
  }
popd

git clone https://github.com/MaskRay/ccls.git "`"$tmpdir`""

pushd $tmpdir
  git reset --hard
  git clean -fdx
  git checkout "$version"
  if ($? -ne $True) {
    Clear-Tmp
    Throw "checking-out to version $version was failed!"
  }
popd

if ( Test-Path $dest ) {
  Clear-Tmp
  Throw "$dest cannot be used as a destination"
}

mkdir $dest

pushd $dest
  cp "$tmpdir/LICENSE" . -Force

  $scoopdir = "$env:UserProfile/scoop"
  $globaldir = "C:/ProgramData/scoop"

  $stopwatch = [Diagnostics.Stopwatch]::StartNew()

  cmake "-H$tmpdir" "-B." -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_PREFIX_PATH="$scoopdir/apps/llvm-self-build/current/Release;$scoopdir/apps/llvm-self-build/current/Release/tools/clang;$scoopdir/apps/llvm-self-build/current;$scoopdir/apps/llvm-self-build/current/tools/clang;$globaldir/apps/llvm-self-build/current/Release;$globaldir/apps/llvm-self-build/current/Release/tools/clang;$globaldir/apps/llvm-self-build/current;$globaldir/apps/llvm-self-build/current/tools/clang"
  ninja

  $stopwatch.Stop()
  $elapsedSec = [int]($stopwatch.Elapsed.TotalSeconds)
  $elapsedMin = [int]($elapsedSec / 60)
  $elapsedHour = [int]($elapsedMin / 60)
  $elapsedSec %= 60
  $elapsedMin %= 60

  echo "build time : $elapsedHour hr $elapsedMin min $elapsedSec sec"
popd

Clear-Tmp

