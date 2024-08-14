
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

function downloadFile($url, $targetFile)
{
"Downloading $url"
$uri = New-Object "System.Uri" "$url"
$request = [System.Net.HttpWebRequest]::Create($uri)
$request.set_Timeout(15000) #15 second timeout
$response = $request.GetResponse()
$totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
$responseStream = $response.GetResponseStream()
$targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
$buffer = new-object byte[] 10KB
$count = $responseStream.Read($buffer,0,$buffer.length)
$downloadedBytes = $count
    while ($count -gt 0)
{
[System.Console]::CursorLeft = 0
[System.Console]::Write("Downloaded {0}K of {1}K", [System.Math]::Floor($downloadedBytes/1024), $totalLength)
$targetStream.Write($buffer, 0, $count)
$count = $responseStream.Read($buffer,0,$buffer.length)
$downloadedBytes = $downloadedBytes + $count
}
"`nFinished Download"
$targetStream.Flush()
    $targetStream.Close()
    $targetStream.Dispose()
    $responseStream.Dispose()
}

#Configure the Network
try {
   New-NetIPAddress -InterfaceIndex $ipIF -IPAddress $IPv4Address -PrefixLength $IPv4Prefix -DefaultGateway $IPv4GW -ErrorAction Stop | Out-Null
   Set-DNSClientServerAddress -ServerAddresses $IPv4DNS -interfaceIndex $ipIF -ErrorAction Stop
   Write-Host "IP Address successfully set to $($IPv4Address), subnet $($IPv4Prefix), default gateway $($IPv4GW) and DNS Server $($IPv4DNS)" -ForegroundColor Green   
}
catch {
   Write-Warning -Message $("Failed to apply network settings. Error: "+ $_.Exception.Message)
   Break;>
}

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

#Check connectivity to the domain controller

try {
   Test-Connection -ComputerName dc1.talespin.local 
}
catch {
   Write-Warning -Message $("Failed to set ping the Domain Controller "+ $_.Exception.Message)
}

Rename-Computer -NewName $computerName

# Download and install Chrome

Write-Host "Downloading and installing Chrome..."
$chromeInstallerPath = "$env:TEMP\ChromeSetup.exe"
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile $chromeInstallerPath
Write-Host "Installing Chrome..."
Start-Process -FilePath $chromeInstallerPath -Args "/silent /install" -Wait
Remove-Item $chromeInstallerPath

# Download and install VSC
Write-Host "Downloading and installing Visual Studio Code..."
$vscodeInstallerPath = "$env:TEMP\VSCodeSetup.exe"
Invoke-WebRequest -Uri "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user" -OutFile $vscodeInstallerPath
Write-Host "Installing Visual Studio Code..."
Start-Process -FilePath $vscodeInstallerPath -Args "/silent /mergetasks=!runcode" -Wait
Remove-Item $vscodeInstallerPath

# Download and install Python
Write-Host "Downloading Python..."
$latestPythonVersion = (Invoke-WebRequest -Uri "https://www.python.org/downloads/windows/").Content | Select-String -Pattern 'Latest Python (\d+) Release - Python (\d+\.\d+\.\d+)' | % { $_.Matches.Groups[2].Value }
$pythonInstallerPath = "$env:TEMP\PythonInstaller.exe"
Invoke-WebRequest -Uri "https://www.python.org/ftp/python/$latestPythonVersion/python-$latestPythonVersion-amd64.exe" -OutFile $pythonInstallerPath
Write-Host "Installing Python..."
Start-Process -FilePath $pythonInstallerPath -Args "/quiet InstallAllUsers=1 PrependPath=1" -Wait
Remove-Item $pythonInstallerPath

# Download and install Wireshark
Write-Host "Downloading and installing Wireshark..."
$wiresharkInstallerPath = "$env:TEMP\Wireshark.exe"
Invoke-WebRequest -Uri "https://2.na.dl.wireshark.org/win64/Wireshark-4.2.6-x64.exes" -OutFile $wiresharkInstallerPath
Write-Host "Installing Wireshark..."
Start-Process -FilePath $wiresharkInstallerPath -Args "/NCRC /S /desktopicon=yes" 
Remove-Item $wiresharkInstallerPath

# Download Attack tools
#mimikatz
#Rubeus
#spoolservice

#Setting up the stage 2 script execution
try {
   New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
   Set-Location -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
   New-ItemProperty -Name adsec2 -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -PropertyType String -Value "Powershell C:\adsec\temp\client2.ps1"
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