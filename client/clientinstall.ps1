<#
    .Synopsis
       Create and Windows CLient and join the domain 'talespin' with a Windows2016 DFS on a Windows 2019 OS
    .DESCRIPTION
       This toolis for training only.Intended only for personal use. Not to be run in Production environment.
    .EXAMPLE
       There are currently no parameters for the script. Just run this script
    .OUTPUTS
       [String]
    .NOTES
       Written by @khannaanurag
     
    .FUNCTIONALITY
       Download the files needed to create a domain and create a domain
       By Default the name of the directory is talespin.local
       last updated on 20240813
    #>

Clear-host
write-host "Running Stage 0 - Starting installation of Client"
write-host "This tool should not be run in production"
write-host "This process would take between 10-15 minutes"
Write-Host "********************"
Write-Host "Please ensure you have taken a snapshot of the Virtual Machine"

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

#Define variables, by default the script uses the C"\adsec directory
$myDownloadUrl = "https://github.com/Oceanduck/adsec/raw/main/client/client.zip"
$zipFile = "c:\adsec\temp\client.zip"
$workingDir = "C:\adsec"
$tempDir ="C:\adsec\temp"

New-Item -ItemType Directory -Force -Path $tempDir
Invoke-WebRequest $myDownloadUrl -OutFile $tempDir\client.zip

sleep 3 
#Download the required archive

try {
    Expand-Archive $zipFile -DestinationPath $tempDir -Force 
    Write-Host "`t[+] zipfile Successfully downloaded expanded" -ForegroundColor Green
    }   
 catch {
    Write-Warning -Message $("Failed to open zip file RDP. Error: "+ $_.Exception.Message)
    Break;
}

Write-Host "`t[+] Now installing Chocolatey packet manager." -ForegroundColor Green
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))


#Setting up the stage 1 script execution
try {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    Set-Location -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    New-ItemProperty -Name client1 -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -PropertyType String -Value "Powershell -ep bypass -File C:\adsec\temp\client1.ps1"
  }
  catch {
     Write-Warning -Message $("Failed to set the registry to run stage 1. Error: "+ $_.Exception.Message)
     Start-Sleep 5
     Break;
  }
  
  #Restart the Computer
  try {
     Write-Host "Rebooting the system  in 30 seconds, the installation will continue after reboot. Please login with Administrator login once the system reboots"
     read-host “Press ENTER to continue...”
     Restart-Computer  -ErrorAction Stop
  }
  catch {
     Write-Warning -Message $("Failed to Restart the Computer. Error: "+ $_.Exception.Message)
     Break;
  }
