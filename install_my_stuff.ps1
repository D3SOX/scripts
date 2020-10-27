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
choco install vcredist-all directx chromium discord dotnetcore powertoys everything nomacs 7zip kate vlc eartrumpet

# TODO: fix this
<#
# Activate Windows
# Download script
Start-BitsTransfer -Source "https://github.com/ekistece/vlmcsd-autokms/releases/download/1.1/vlmcsd-autokms-1.1.zip" -Destination "vlmcsd-autokms-1.1.zip"
# Extract archive (TODO: check if this works)
Expand-Archive "vlmcsd-autokms-1.1.zip" -DestinationPath "$PSScriptRoot"
# Copy to C drive
copy ./vlmcsd-autokms-1.1/vlmcsd64/ C:\
# Start script
echo "If the key is not in the list get from https://docs.microsoft.com/en-US/windows-server/get-started/kmsclientkeys"
start "C:\vlmcsd64\install.bat"
#>

# Start debloat script
iex ((New-Object System.Net.WebClient).DownloadString('https://git.io/debloat'))
