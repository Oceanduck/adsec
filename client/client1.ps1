
# Introduction 
Clear-host
write-host "Running Stage 1 - Configuring the Client"
write-host "This tool should not be run in production"

#Define variables to configure the network
$computerName = "client1"
$IPv4Address =  "192.168.8.81"
$IPv4Prefix = "24"
$IPv4GW = "192.168.8.1"
$IPv4DNS = "192.168.8.1"
$ipIF = (Get-NetAdapter).ifIndex
$enablerdp = 'yes'
$disableiesecconfig = 'yes'
$workingDir = "C:\adsec"

cd $workingDir

#Configure RDP

try {
   if ($enablerdp -eq "yes") {
      Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0 -ErrorAction Stop
      Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction Stop
      Write-Host "RDP Successfully enabled" -ForegroundColor Green
   }   
}
catch {
   Write-Warning -Message $("Failed to enable RDP. Error: "+ $_.Exception.Message)
     Break;
}
if ($enablerdp -ne "yes")
    {
    Write-Host "RDP remains disabled" -ForegroundColor Green
    }
    
#Rename the computer
try {
   Rename-Computer -ComputerName $env:COMPUTERNAME -NewName $computerName -ErrorAction Stop
   Write-Host "Systemname has been changed to $($computerName)" -ForegroundColor Green
}
catch {
   Write-Warning -Message $("Failed to disable Ie Security Configuration. Error: "+ $_.Exception.Message)
   Break;
}



#Download and install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install firefox --version 129.0.0 -y
choco install vscode --version 1.92.1 -y
choco install wireshark --version 4.2.6 -y
choco install bginfo --version 4.32 -y
choco install 7zip --version 24.8.0 -y
choco install nginx --params '"/installLocation:C:\nginx /port:8080"' -y


# Download Attack tools
Invoke-WebRequest "https://github.com/gentilkiwi/mimikatz/releases/download/2.2.0-20220919/mimikatz_trunk.7z" -OutFile "c:\adsec\mimikatz.7z"
Invoke-WebRequest "https://github.com/hashcat/hashcat/releases/download/v6.2.6/hashcat-6.2.6.7z" -OutFile "c:\adsec\hashcat.7z"


#Setting up the stage 2 script execution
try {
  # New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
  # Set-Location -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
   New-ItemProperty -Name client2 -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -PropertyType String -Value "Powershell -ep bypass -File C:\adsec\temp\client2.ps1"
}
catch {
   Write-Warning -Message $("Failed to set the registry to run stage 1. Error: "+ $_.Exception.Message)
   Break;
}

#Restart the Computer
try {
   Write-Host "Rebooting the system  in 30 seconds, the installation will continue after reboot. Please login with Administrator login once the system reboots"
   Write-Host "You may need to press enter"
   read-host “Press ENTER to continue...”
   Restart-Computer  -ErrorAction Stop
}
catch {
   Write-Warning -Message $("Failed to Restart the Computer. Error: "+ $_.Exception.Message)
   Break;
}