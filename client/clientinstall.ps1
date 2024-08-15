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

#Check Running as Administrator
function Check-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        return $false
    } else {
        return $true
    }
}
#Check Tamper Protection
function Check-DefenderAndTamperProtection {
    $defender = Get-WmiObject -Namespace "root\Microsoft\Windows\Defender" -Class MSFT_MpPreference
    if ($defender.DisableRealtimeMonitoring) {
        if (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -ea 0) {
            if ($(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection").TamperProtection -eq 5) {
                return $false
            } else {
                return $true
            }
        }
    } else {
        return $false
    }

}    

if (Check-Admin) {
    Write-Host "`t[+] Script Running as an Admin" -ForegroundColor Green
    } 
else {
    Write-Host "`t[-] Script not running as an Admin. Script will exit" -ForegroundColor Red
    sleep 3
    exit
}

if (Check-DefenderAndTamperProtection) {
    Write-Host "`t[+] Windows Defender and Tamper Protection are disabled" -ForegroundColor Green
    } 
else {
    Write-Host "`t[-] Windows Defender and Tamper Protection are enabled. Script will exit" -ForegroundColor Red
    sleep 3
    exit
}

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