$workingDir = "C:\adsec" 
$tempDir = "C:\adsec\temp"
$IPv4Address =  "192.168.8.81"
$IPv4Prefix = "24"
$IPv4GW = "192.168.8.1"
$IPv4DNS = "192.168.8.71"
$enablerdp = 'yes'
$disableiesecconfig = 'yes'
$workingDir = "C:\adsec"


#Check connectivity to the domain controller
Start-Sleep 5
try {
  Test-Connection -ComputerName dc1.talespin.local 
}
catch {
  Write-Warning -Message $("Failed to ping the Domain Controller "+ $_.Exception.Message)
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