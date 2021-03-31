# common
## chromeをwebから

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
## DL
`git clone git@github.com:yakisuzu/dotfiles.git ~/dotfiles`  

## dotfiles install
`~/dotfiles/install.sh`  

## apps setup
### Homebrew
[Homebrew](https://brew.sh/index_ja)  
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
#brew tap homebrew/cask-versions
brew tap AdoptOpenJDK/openjdk
brew cask install adoptopenjdk11 adoptopenjdk8
brew reinstall openssl
brew install openssh git tree p7zip maven sbt tig tmux anyenv jq coreutils gnu-sed
brew cask install appcleaner alfred adobe-acrobat-reader macvim docker slack jetbrains-toolbox kindle mysqlworkbench

brew cask install chatwork calibre karabiner-elements

# dependencies python3
brew install readline xz openssl@1.1

# completion for bash@3.2
brew install bash-completion

# cloud infra
brew install awscli
brew cask install google-cloud-sdk

# gcp
curl -o cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.darwin.amd64
chmod +x cloud_sql_proxy && mv cloud_sql_proxy /usr/local/bin/
```

### anyenv
```
anyenv install --init
anyenv install goenv
anyenv install jenv
anyenv install nodenv
anyenv install pyenv
anyenv install rbenv

mkdir -p $(anyenv root)/plugins
git clone https://github.com/znz/anyenv-update.git $(anyenv root)/plugins/anyenv-update

# goenv
goenv install -l | tail -3
goenv install ${1.X}

# jenv
# install済みjavaのpath確認
/usr/libexec/java_home -V
# javaはbrewでいれ、参照を登録
jenv add $(/usr/libexec/java_home -v 1.8)
jenv add $(/usr/libexec/java_home -v 11)
# JAVA_HOMEの有効化
jenv enable-plugin export

# nodenv
nodenv install -l | grep '^10\.' | tail -3
nodenv install -l | grep '^12\.' | tail -3
nodenv install ${LTS}

# pyenv
pyenv install -l | grep '^  2' | tail -3
pyenv install ${2.X}

pyenv install -l | grep '^  3' | tail -3
pyenv install ${3.X}

# rbenv
rbenv install -l | grep '^2' | tail -3
rbenv install ${2.X}
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
brew tap sanemat/font
brew install ricty
cp -f /usr/local/opt/ricty/share/fonts/Ricty*.ttf ~/Library/Fonts/
fc-cache -vf
```

### DL list


## after setting
### システム環境設定  
- Dock  
Dockを自動的に表示/非表示  
最近使ったアプリケーションをDockに表示しない  

- セキュリティとプライバシー  
スリープとスクリーンセーバの解除にパスワードを要求 開始後：5分後  

- キーボード  
  - キーボード  
  キーリピート、認識までの時間を最速に  
  右下の修飾キー => Caps LockをCommandに  
    - ファンクションとタッチバーについてはモデルで設定が異なる  
    外部キーボードのF1、F2などのキーを標準のファンクションキーとして使用  
    TouchBarに表示する項目: F1、F2などのキー  
    Fnキーを押して: ControlStripを表示  
  - ユーザ辞書  
  文頭を自動的に大文字にしない  
  スマート引用符とスマートダッシュを使用を外す  
  - ショートカット  
  Spotlightのcommand+spaceを外す  
  - 入力ソース  
  半角カナ追加  
  ライブ変換、タイプミスを外す  
  フォントはRicty Regular  
  ¥は\  

- トラックパッド  
調べる＆データ検出をオフに  

- 日付と時刻  
日付のオプション：日付を表示をオン  

- Touch ID  


### ターミナル
起動時に開く：Pro  
Proをデフォルトに  
Ricty Bold 18pt.  
ウインドウサイズ 240 - 60  
コマンドを実行：tmux  
シェルの終了時：シェルが正常に終了した場合は閉じる  

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
- BashSupport  
- File Watchers  
- Go  
- Python  
- IdeaVim  
- Ideolog  
- Kubernetes  
- Lombok  
- Makefile Support  
- NodeJS  
- Prettier  
- Scala  
- Vue.js  
- EnvFile  

