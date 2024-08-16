
# Introduction 
Clear-host
write-host "Running Stage 1 - Configuring the Client"
write-host "This tool should not be run in production"

#Define variables to configure the network

$IPv4Address =  "192.168.8.81"
$IPv4Prefix = "24"
$IPv4GW = "192.168.8.1"
$IPv4DNS = "192.168.8.71"
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
    
#Disable the server manager pop up
New-ItemProperty -Path HKCU:\Software\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -PropertyType DWORD -Value "0x1" –Force

#Download and install Chocolatey
choco install googlechrome --version 127.0.6533.100 -y --ignore-checksums 
choco install wireshark --version 4.2.6 -y
choco install 7zip --version 24.8.0 -y
choco install notepadplusplus --version 8.6.9 -y
choco install nginx --version 1.27.0 --params '"/installLocation:C:\nginx /port:8080"' -y


# Download Attack tools
Invoke-WebRequest "https://github.com/gentilkiwi/mimikatz/releases/download/2.2.0-20220919/mimikatz_trunk.7z" -OutFile "$workingDir\mimikatz.7z"
Invoke-WebRequest "https://github.com/hashcat/hashcat/releases/download/v6.2.6/hashcat-6.2.6.7z" -OutFile "$workingDir\hashcat.7z"

7z.exe x $workingDir\mimikatz.z7 -o"C:\adsec\mimikatz\" -y
7z.exe x $workingDir\hashcat.7z -o"C:\adsec\hashcat\" -y


Write-Host "Downloading and configuring the Wiki"
Invoke-WebRequest "https://github.com/Oceanduck/adsec/raw/main/wiki.7z" -OutFile $workingDir\wiki.7z
Start-Sleep 5
7z.exe x $workingDir\wiki.7z -o"C:\nginx\nginx-1.27.0\html\" -y
Start-Sleep 5

#Configure the Network
try {
  $adapter = Get-NetAdapter | ? {$_.Status -eq "up"}
  $adapter | New-NetIPAddress -IPAddress $IPv4Address -PrefixLength $IPv4Prefix -DefaultGateway $IPv4GW -ErrorAction Stop | Out-Null
  $adapter | Set-DNSClientServerAddress -ServerAddresses $IPv4DNS -ErrorAction Stop
  Write-Host "IP Address successfully set to $($IPv4Address), subnet $($IPv4Prefix), default gateway $($IPv4GW) and DNS Server $($IPv4DNS)" -ForegroundColor Green   
}
catch {
  Write-Warning -Message $("Failed to apply network settings. Error: "+ $_.Exception.Message)
}

#Rename the computer
$random = Get-Random -Maximum 999 -Minimum 100
$computerName = "Client"+$random
try {
  Rename-Computer -ComputerName $env:COMPUTERNAME -NewName $computerName -ErrorAction Stop
  Write-Host "Systemname has been changed to $($computerName)" -ForegroundColor Green
}
catch {
  Write-Warning -Message $("Failed to disable Ie Security Configuration. Error: "+ $_.Exception.Message)
  Break;
}

#Setting up the stage 2 script execution
try {
  New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
  Set-Location -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
  New-ItemProperty -Name client2 -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -PropertyType String -Value "Powershell -ep bypass -File C:\adsec\temp\client2.ps1"
}
catch {
   Write-Warning -Message $("Failed to set the registry to run stage 1. Error: "+ $_.Exception.Message)
   Start-Sleep 10
   Break;
}

#Restart the Computer
try {
   Write-Host "Rebooting the system  in 30 seconds, the installation will continue after reboot"
   Restart-Computer
}
catch {
   Write-Warning -Message $("Failed to Restart the Computer. Error: "+ $_.Exception.Message)
   Start-Sleep 10
   Break;
}