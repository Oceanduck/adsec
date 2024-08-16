$workingDir = "C:\adsec" 
$tempDir = "C:\adsec\temp"
$IPv4Address =  "192.168.8.81"
$IPv4Prefix = "24"
$IPv4GW = "192.168.8.1"
$IPv4DNS = "192.168.8.71"
$enablerdp = 'yes'
$disableiesecconfig = 'yes'
$workingDir = "C:\adsec"

Write-Host "Downloading and configuring the Wiki"
Invoke-WebRequest "https://github.com/Oceanduck/adsec/raw/main/wiki.7z" -OutFile $workingDir\wiki.7z
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

#Check connectivity to the domain controller
Start-Sleep 5
try {
  Test-Connection -ComputerName dc1.talespin.local 
}
catch {
  Write-Warning -Message $("Failed to ping the Domain Controller "+ $_.Exception.Message)
}

$random = Get-Random -Maximum 999 -Minimum 100
$computerName = "Client"+$random


#Rename the computer
try {
  Rename-Computer -ComputerName $env:COMPUTERNAME -NewName $computerName -ErrorAction Stop
  Write-Host "Systemname has been changed to $($computerName)" -ForegroundColor Green
}
catch {
  Write-Warning -Message $("Failed to disable Ie Security Configuration. Error: "+ $_.Exception.Message)
  Break;
}

Write-Host "Please ensure the dc1 system is up and running." -ForegroundColor Red 
Read-Host “Press ENTER to continue...”


#pass Credentials for a normal user
$username = "Tailspin\Administrator"
$password = ConvertTo-SecureString "Password@123" -AsPlainText -Force
$credential = New-Object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

try {
  Add-Computer -DomainName talespin.local -Credential $credential
}
catch {
  Add-Computer -DomainName talespin.local -Credential $credential -ComputerName -ClientX
}


$workingDir = "C:\adsec"
Set-ItemProperty -path "HKCU:\Control Panel\Desktop\" -name wallpaper -value $tempDir\wall.jpg
rundll32.exe user32.dll, UpdatePerUserSystemParameters


#Restart the Computer
try {
  Write-Host "Rebooting the system in 10 seconds"
  Start-Sleep 10
  Restart-Computer  -ErrorAction Stop
}
catch {
  Write-Warning -Message $("Failed to Restart the Computer. Error: "+ $_.Exception.Message)
  Break;
}