
$workingDir = "C:\adsec" 

Write-Host "Downloading and configuring the Wiki"
Invoke-WebRequest "https://github.com/Oceanduck/adsec/raw/main/wiki.7z" -OutFile $workingDir\wiki.7z
7z.exe x $workingDir\wiki.7z -o"C:\nginx\nginx-1.27.0\html\" -y



#Configure the Network
try {
  $adapter = Get-NetAdapter | ? {$_.Status -eq "up"}
  $adapter | New-NetIPAddress -IPAddress $IPv4Address -PrefixLength $IPv4Prefix -DefaultGateway $IPv4GW -ErrorAction Stop | Out-Null
  $adapter | Set-DNSClientServerAddress -ServerAddresses $IPv4DNS -ErrorAction Stop
  Write-Host "IP Address successfully set to $($IPv4Address), subnet $($IPv4Prefix), default gateway $($IPv4GW) and DNS Server $($IPv4DNS)" -ForegroundColor Green   
}
catch {
  Write-Warning -Message $("Failed to apply network settings. Error: "+ $_.Exception.Message)
  Break;>
}

#pass Credentials for a normal user
Add-Computer -DomainName talespin.local 

$workingDir = "C:\adsec"
Set-ItemProperty -path "HKCU:\Control Panel\Desktop\" -name wallpaper -value $workingDir\wall.jpg
rundll32.exe user32.dll, UpdatePerUserSystemParameters




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