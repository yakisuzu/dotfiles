# set HOME
[Environment]::SetEnvironmentVariable('HOME', [Environment]::GetEnvironmentVariable('USERPROFILE', [EnvironmentVariableTarget]::Process), [EnvironmentVariableTarget]::User)

# env to var
$SystemDrive = [Environment]::GetEnvironmentVariable('SystemDrive', [EnvironmentVariableTarget]::Process)
$ProgramFiles = [Environment]::GetEnvironmentVariable('ProgramFiles', [EnvironmentVariableTarget]::Process)
$ProgramFiles86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)', [EnvironmentVariableTarget]::Process)

$JAVA_HOME = $ProgramFiles + '\Java\jdk'
[Environment]::SetEnvironmentVariable('JAVA_HOME',$JAVA_HOME, [EnvironmentVariableTarget]::User)

$NVM_HOME = [Environment]::GetEnvironmentVariable('NVM_HOME', [EnvironmentVariableTarget]::Process)
$NVM_SYMLINK = [Environment]::GetEnvironmentVariable('NVM_SYMLINK', [EnvironmentVariableTarget]::Process)

# env setting
Class App {
  [string]$Name
  [string]$Path

  App([string]$Name, [string]$Path) {
    $this.Name = $Name
    $this.Path = $Path
  }
}

$Apps = [App[]](
  [App]::new("vim", $ProgramFiles + "\vim-kaoriya"),
  [App]::new("git", $ProgramFiles + "\Git\cmd"),
  [App]::new("OpenSSH", $ProgramFiles + "\OpenSSH-Win64"),
  [App]::new("ConEmu", $SystemDrive + "\ConEmu"),
  [App]::new("msys2/root", $SystemDrive + "\msys64"),
  [App]::new("msys2/bin", $SystemDrive + "\msys64\usr\bin"),
  [App]::new("java", $JAVA_HOME + "\bin"),
  [App]::new("node/nvm", $NVM_HOME),
  [App]::new("node/node", $NVM_SYMLINK),
  [App]::new("Docker", $ProgramFiles + "\Docker\Docker\Resources\bin"),
  [App]::new("dotfiles", $HOME + "\dotfiles\bin")
)

Write-Output -InputObject $Apps
Write-Output ""

[string[]] $AddAppPaths = @()
$EnvironmentPaths = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::User) -split ";"
$Apps | % {
  # sort add paths
  $PathIndex = [array]::IndexOf($EnvironmentPaths, $_.Path)
  if($PathIndex -ge 0){
    $EnvironmentPaths[$PathIndex] = $null
  }
  if(!($EnvironmentPaths -contains $_.Path)){
    $AddAppPaths += $_.Path
  }
}
# add other EnvironmentPaths
$EnvironmentPaths | % {
  # check delete item
  if($_.Length -ne 0){
    $AddAppPaths += $_
  }
}
[Environment]::SetEnvironmentVariable('PATH', ($AddAppPaths -join ";"), [EnvironmentVariableTarget]::User)

Write-Output AddAppPaths
Write-Output ----------
Write-Output $AddAppPaths

