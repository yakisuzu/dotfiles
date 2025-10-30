# common
## pcセットアップ
ユーザー名調整  
OSアップデート  
chromeをwebからインストール

## create keygen
`ssh-keygen -t ed25519`  

### mac
`cat ~/.ssh/id_ed25519.pub | pbcopy`  

### win
`more %USERPROFILE%\.ssh\id_ed25519.pub | clip`  

## add github ssh key
webログインし、プロフィールから登録  
https://github.com/yakisuzu.keys  


# mac
## bash
`chsh -s /bin/bash`  

## DL
`git clone git@github.com:yakisuzu/dotfiles.git ~/dotfiles`  

## dotfiles install
`~/dotfiles/install.sh`  

## apps setup
### Homebrew
[Homebrew](https://brew.sh/ja/)  
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# java
brew install corretto@21
# option
brew install corretto@8 corretto@11 corretto@17

brew reinstall openssl
brew install openssh git tree p7zip tig tmux jq coreutils findutils gnu-sed grep wdiff anyenv go asdf appcleaner alfred macvim visual-studio-code@insiders docker slack kindle zoom
# option
brew install maven sbt mysql-client@8.0 chatwork calibre karabiner-elements

# LLM
brew install --cask claude-code
brew install gemini-cli

# completion for bash@3.2
brew install bash-completion

# cloud infra
brew install awscli
brew install --cask google-cloud-sdk

# gcp
curl -o cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.darwin.amd64
chmod +x cloud_sql_proxy && mv cloud_sql_proxy /usr/local/bin/

# 再起動
exit
```

### anyenv
```
# anyenv
anyenv install --init
anyenv install jenv
anyenv install nodenv
anyenv install pyenv

mkdir -p $(anyenv root)/plugins
git clone https://github.com/znz/anyenv-update.git $(anyenv root)/plugins/anyenv-update

# 再起動
exit

# jenv
# install済みjavaのpath確認
/usr/libexec/java_home -V
# javaはbrewでいれ、参照を登録
jenv add $(/usr/libexec/java_home -v 1.8)
jenv add $(/usr/libexec/java_home -v 11)
jenv add $(/usr/libexec/java_home -v 17)
jenv add $(/usr/libexec/java_home -v 21)
# JAVA_HOMEの有効化
jenv enable-plugin export

# nodenv
nodenv install -l | grep '^2.\.'
nodenv install ${LTS}

# pyenv
pyenv install -l | grep '^  2' | tail -3
pyenv install ${2.X}

pyenv install -l | grep '^  3' | tail -3
pyenv install ${3.X}

# 再起動
exit
```

### kubernetes
```
brew install kubernetes-cli kubectx kustomize skaffold

# EKS
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

## IAMの利用で必須
## どこで実行してもいい
go get -u -v github.com/kubernetes-sigs/aws-iam-authenticator/cmd/aws-iam-authenticator
```

### Ricty
```
brew install font-ricty-diminished
```


## after setting
### システム環境設定  
- デスクトップとDock  
  - ON: Dockを自動的に表示/非表示  
  - OFF: 最近使ったアプリケーションをDockに表示  
- ロック画面  
  - 使用していない場合はスクリーンセーバを開始：5分後  
  - スクリーンセーバの開始後またはディスプレイがオフになったあとにパスワードを要求：1時間後  
- キーボード  
  - キーボード  
    - キーリピート: 最速  
    - リピート入力認識までの時間: 最短  
    - キーボードショートカット  
      - Spotlight  
        - OFF: Spotlight検索を表示(command+space)  
      - ファンクションキー  
        - ON: F1、F2などのキーを標準のファンクションキーとして使用  
      - 修飾キー  
        - Caps Lockキー: Command  
          - キーボードを選択してそれぞれ設定  
  - テキスト入力  
    - 入力ソース編集  
      - すべての入力ソース  
        - OFF: 文頭を自動的に大文字にする  
        - OFF: スペースバーを2回押してピリオドを入力  
        - OFF: スマート引用符とスマートダッシュを使用  
      - 日本語  
        - ON: 半角カタカナ  
        - OFF: ライブ変換  
        - OFF: タイプミスを修正  
        - 候補表示：  
          - フォント: Ricty Diminished Bold  
        - "¥"キーで入力する文字: \（バックスラッシュ）  
- トラックパッド  
  - ポイントとクリック  
    - OFF: 調べる＆データ検出  
- 日付と時刻  
- Touch ID  


### ターミナル
- 一般  
  - 起動時に開く：Pro  
- プロファイル  
  - 左メニュー  
    - Proをデフォルトに  
  - テキスト  
    - Ricty Diminished Bold 18pt.  
  - ウインドウ  
    - ウインドウサイズ: 150 - 40  
  - シェル  
    - コマンドを実行：tmux  
    - シェルの終了時：シェルが正常に終了した場合は閉じる  


## Finder
- 詳細  
  - ON: すべてのファイル名拡張子を表示  


## Karabiner-Elements
- Simple Modifications (HHKB)  

| 刻印      | 変更前                      | 変更後        |
| ---      | ---                        | ---          |
| HHKBマーク | grave_accent_and_tilde(\`) | left_command |
| (/)      | international5             | 英数キー       |
| ()       | international4             | かなキー       |
| Kana     | international2             | right_command |

- Simple Modifications (REALFORCE)  
設定なし

- Complex Modifications (Rules)  
karabiner://karabiner/assets/complex_modifications/import?url=https%3A%2F%2Frcmdnk.com%2FKE-complex_modifications%2Fjson%2Fpersonal_rcmdnk.json  
`EISU sends EISU ESC ESC when language is ja`  

- Devices  
  - Advanced  
  Disable the build-in ... でREALFORCEをチェック  

# win
## git setting
- [git](https://github.com/git-for-windows/git/releases/latest)  
- Componensts  
  - Git LFS  
  - Associate .git*  
  - Associate .sh  
  - Use a True Type Font  
  - Check daily for Git  
- Checkout as-is, commit as-is  
- Enable experimental, build-in app -i/-p  

## 管理者として実行（ショートカット > 詳細設定）
- コマンドプロンプト  

## dotfiles install
```
cd %USERPROFILE% && git clone https://github.com/yakisuzu/dotfiles.git
.\dotfiles\install.bat
powershell -ExecutionPolicy unrestricted %USERPROFILE%\dotfiles\bin\update_path.ps1
```

## bash setting
### msys2
[msys2](https://www.msys2.org/)  
```
pacman -Syuu
pacman -Suu
```

### bash on windows (win10)
```
sudo sed -i -e 's%http://.*.ubuntu.com%http://ftp.jaist.ac.jp/pub/Linux%g' /etc/apt/sources.list
sudo apt update
sudo apt upgrade
sudo apt install p7zip-full
```

## apps setup
- winの場合、アップデート/アンインストールは、パッケージマネージャではなく、各アプリが責任を持つ  
- インストーラーを使い、"プログラムの追加と削除"からアンインストールできるようにする  
- 自動化すると、動かないパッケージ、古いパッケージがたまにある  

### DL list
#### link
- [Ctrl2Cap](http://download.sysinternals.com/files/Ctrl2Cap.zip)  
  - `.\ctrl2cap.exe /install`  
- [Stickies](http://www.zhornsoftware.co.uk/support/kb00013-7.1e.exe)  
- [Docker](https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe)  

#### site
- [OpenSSH](https://github.com/PowerShell/Win32-OpenSSH/releases/latest)  
  - `mv OpenSSH-Win64/ /c/Program\ Files/`  
- [xdoc2txt](http://ebstudio.info/home/xdoc2txt.html)  
  - `mv xdoc2txt.exe ~/dotfiles/bin/`  
- [jq](https://stedolan.github.io/jq/download/)  
  - `mv jq-win64.exe ~/dotfiles/bin/jq.exe`  
- [vim](https://github.com/koron/vim-kaoriya/releases/latest)  
  - `mv vim81-kaoriya-win64/ /c/Program\ Files/vim-kaoriya`  
- [nvm-windows](https://github.com/coreybutler/nvm-windows/releases/latest)  
  - DL `nvm-setup.zip` and install  
  - `nvm list available`  
  - `nvm install ${LTS} && nvm use ${LTS}`  
- [ConEmu](https://github.com/Maximus5/ConEmu/releases/latest)  
- [JetBrains TOOLBOX](https://www.jetbrains.com/toolbox-app/)  

#### win7
- [WMF5.1](https://go.microsoft.com/fwlink/?linkid=839523)  

## 管理者として実行（ショートカット > 詳細設定）
- gvim  
- ConEmu  


# IntelliJ IDEA
## setting repository
https://github.com/yakisuzu/intellij-settings.git  

## plugins
- AWS CloudFormation  
- File Watchers  
- Go  
- Python  
- IdeaVim  
- Kubernetes  
- Lombok  
- Makefile Support  
- NodeJS  
- Prettier  
- Scala  
- Vue.js  
