# ==============================
# 
# Install Chocolatey and DotNetCore
#
# ==============================

WriteHeader "Install Chocolatey, DotNetCore and more software"

$dateStamp = Get-Date -Format yyyy-MM-dd-HH-mm-ss
$logFile = "choco-install-log-$env:COMPUTERNAME-$dateStamp.log"
$logFile = Join-Path $installLogFolder $logFile

# Install Chocolatey
WriteDebug "Install Chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install Chocolatey Packages
WriteDebug "Install Chocolatey Packages"

$softlistPath = Join-Path $PSScriptRoot "software-list.json"

if (Test-Path -Path $softlistPath){
	WriteDebug "A software list file is present at: $softlistPath"
}
else {
	WriteError "No file exists at $softlistPath"
	Return
}

$softwareToInstall = Get-Content -Path $softlistPath -ErrorAction Stop | ConvertFrom-Json

ForEach($choco in $softwareToInstall.chocoItems) {
	if (Confirm "Should chocolatey install $($choco.item)")
	{
		choco install $choco.item -y --log-file=$logFile
	}
}

WriteDone