# common
## create keygen
`ssh-keygen`  

### mac
`cat ~/.ssh/id_rsa.pub | pbcopy`

## add github ssh key
webログインし、プロフィールから登録  


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
brew tap homebrew/cask-versions
brew cask install java
brew reinstall openssl
brew install openssh git tree p7zip maven tig tmux
brew cask install appcleaner alfred adobe-acrobat-reader macvim docker java8

# dependencies python3
brew install readline xz openssl@1.1

# completion for bash@3.2
brew install bash-completion

# cloud infra
brew install awscli
brew cask install google-cloud-sdk
```

#### after setting
システム環境設定 > キーボード  
alt+spaceを外す  

### anyenv
```
git clone https://github.com/riywo/anyenv ~/.anyenv
anyenv install jenv
anyenv install nodenv
anyenv install pyenv
anyenv install goenv
anyenv install rbenv

mkdir -p $(anyenv root)/plugins
git clone https://github.com/znz/anyenv-update.git $(anyenv root)/plugins/anyenv-update

# 通常の使い方
nodenv install -l
nodenv install ${LTS}
nodenv global ${LTS}

# python@3.Xは依存あり
CONFIGURE_OPTS="--with-openssl=$(brew --prefix openssl@1.1)" pyenv install ${3.X}

# install済みjavaのpath確認
/usr/libexec/java_home
# javaはbrewでいれ、参照を登録
jenv add /Library/Java/JavaVirtualMachines/jdk1.8.0_202.jdk/Contents/Home/
jenv add /Library/Java/JavaVirtualMachines/openjdk-11.0.1.jdk/Contents/Home/
```

### kubernetes
```
brew install kubernetes-cli kubectx

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


# win
## git setting
[git](https://github.com/git-for-windows/git/releases/latest)  

## dotfiles install
```
cd %USERPROFILE% && git clone https://github.com/yakisuzu/dotfiles.git  
.\dotfiles\install.bat  
powershell -ExecutionPolicy unrestricted %USERPROFILE%\dotfiles\utility\set_path.ps1  
```

## bash setting
### msys2
[msys2](http://sourceforge.net/projects/msys2/files/latest/download)  
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
[Ctrl2Cap](http://download.sysinternals.com/files/Ctrl2Cap.zip)  
[Stickies](http://www.zhornsoftware.co.uk/support/kb00013-7.1e.exe)  
[Docker](https://download.docker.com/win/stable/Docker%20for%20Windows%20Installer.exe)  

#### site
[OpenSSH](https://github.com/PowerShell/Win32-OpenSSH/releases/latest)  
[vim](https://github.com/koron/vim-kaoriya/releases/latest)  
[ConEmu](https://github.com/Maximus5/ConEmu/releases/latest)  
[xdoc2txt](http://ebstudio.info/home/xdoc2txt.html)  
[Intellij IDEA](https://www.jetbrains.com/idea/download/download-thanks.html?platform=windows)  
[NVM](https://github.com/coreybutler/nvm-windows/releases/latest)  
[jq](https://stedolan.github.io/jq/download/)  

#### win7
[WMF5.1](https://go.microsoft.com/fwlink/?linkid=839523)  

## admin setting
- gvim  
- ConEmu  
