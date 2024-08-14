<#
Create a Windows CLient - and join the talespin domain
#>

Clear-host
write-host "Running Stage 0 - Starting installation of Client"
write-host "This tool should not be run in production"
write-host "This process would take between 10-15 minutes"
Write-Host "********************"
Write-Host "Please ensure you have taken a snapshot of the VM"

Read-Host -Prompt "Press any key to continue or CTRL+C to quit. Once you continue the system will be renamed, ip address set, connected to the talespin domain and tools downloaded " | Out-Null
#Requires -RunAsAdministrator

#Define variables, by default the script uses the C"\adsec directory
$myDownloadUrl = "https://github.com/Oceanduck/adsec/raw/main/client/client.zip"
$zipFile = "c:\adsec\temp\client.zip"
$workingDir = "C:\adsec"
$tempDir ="C:\adsec\temp"

Invoke-WebRequest $myDownloadUrl -OutFile $tempDir\client.zip
#Download the required archive
New-Item -ItemType Directory -Force -Path $tempDir
Expand-Archive $zipFile -DestinationPath $tempDir -Force 

#Execute stage 1
Write-Host "Executing stage 1"
Powershell.exe -executionpolicy bypass -File  "$tempDir\client1.ps1"