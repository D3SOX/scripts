# Get admin rights
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# Fix time problems with dualbooting with Linux
start "use_utc_time.reg"

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Chocolatey config
choco feature enable -n allowGlobalConfirmation
# Install my applications
choco install vcredist-all brave hackfont jetbrainsmono neovim git jdk8 7zip lockhunter python python2 vscodium jetbrainstoolbox etcher everything kate vlc discord teamspeak teamviewer anydesk winscp audacity spotify telegram signal nodejs office365proplus

# Activate Office 365
start "Applications/office_365_proplus_activator.cmd"

# Activate Windows
# Download script
(New-Object System.Net.WebClient).DownloadFile("https://github.com/ekistece/vlmcsd-autokms/releases/download/1.1/vlmcsd-autokms-1.1.zip", "vlmcsd-autokms-1.1.zip")
# Extract archive (TODO: check if this works)
Expand-Archive "vlmcsd-autokms-1.1.zip" -DestinationPath "$PSScriptRoot"
# Copy to C drive
copy "vlmcsd-autokms-1.1/vlmcsd64/" "C:\"
# Start script
echo "If the key is not in the list get from https://docs.microsoft.com/en-US/windows-server/get-started/kmsclientkeys"
start "C:\vlmcsd64\install.bat"

# Start debloat script
iex ((New-Object System.Net.WebClient).DownloadString('https://git.io/debloat'))
