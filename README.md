
[MaskRay/ccls](https://github.com/MaskRay/ccls) をビルドする

自分の scoop bucket 用にバイナリを用意．なので Windows の分のバイナリしかないよ

Apache License 2.0 はバイナリをソースなしで再配布可能

なお，このREADME，install.ps1 は [WTFPL](http://www.wtfpl.net/) にします．


# 問題点

公式の ccls の LICENSE が現時点で テンプレートのまま名前が書かれていなくて
これ有効なのか？って無限回言っている


# ビルド手順

準備

```powershell
scoop bucket add lumc https://github.com/LumaKernel/my-scoop-bucket.git
scoop install git cmake ninja llvm-clang-lld
```

clone とかはスクリプトがやってくれる．

バージョンはここで -> https://github.com/MaskRay/ccls/tags

自分で MSVC の Developer 環境になるようにしてください (適当)


```powershell
# scoop のパスを一番手前に ぶっこむなら
# $env:Path = "C:\ProgramData\scoop\shims;$env:UserProfile\scoop\shims;$env:Path"

rmdir build -Recurse -Force
./install.ps1 -version 0.20190823.5 -dest build

# 成功したら build をリリース
```

ビルド目安時間 : 2分


アーキテクチャのチェック

```bash
# MSYS2 とか WSL で
file ./build/bin/ccls.exe
```


32 bit版の gcc を入れたら 32bit 版も手に入るんじゃないかなあおそらく

```powershell
scoop install gcc -a 32bit
```

---

## 参考

- [WIndowsでcclsの64bit版を手に入れる方法](https://qiita.com/akinobufujii/items/5f0f729be620830dae28)

