<#
    .Synopsis
       Create and Active Directory domain 'talespin' with a Windows2016 DFS
    .DESCRIPTION
       This toolis for training only.  Intended only for personal use. Not to be run in Production environment.
    .EXAMPLE
       There are currently no parameters for the script. Just run this script
    .OUTPUTS
       [String]
    .NOTES
       Written by @khannaanurag
       
       I take no responsibility for any issues caused by this script.  I am not responsible if this gets run in a production domain. 
    .FUNCTIONALITY
       Creates a domain
    #>

# Introduction 
Clear-host
write-host "Running Stage 1 - Configuring the Server"
write-host "This tool should not be run in production"

#Define variables to configure the network
$computerName = "dc1"
$IPv4Address = "192.168.8.71"
$IPv4Prefix = "24"
$IPv4GW = "192.168.8.1"
$IPv4DNS = "8.8.8.8"
$ipIF = (Get-NetAdapter).ifIndex
$enablerdp = 'yes'
$disableiesecconfig = 'yes'
$workingDir = "C:\adsec"
$tempDir ="C:\adsec\temp"

#Function to Download 
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
      Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0 -ErrorAction Stop | Out-Null
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

try{
   if ($disableiesecconfig -eq "yes") {
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}' -name IsInstalled -Value 0 -ErrorAction Stop
      Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}' -name IsInstalled -Value 0 -ErrorAction Stop
      Write-Host "IE Enhanced Security Configuration successfully disabled for Admin and User" -ForegroundColor Green
   }
}
catch{
      Write-Warning -Message $("Failed to disable Ie Security Configuration. Error: "+ $_.Exception.Message)
      Break;
      }
  
If ($disableiesecconfig -ne "yes")
      {
      Write-Host "IE Enhanced Security Configuration remains enabled" -ForegroundColor Green
      }    


#Rename the computer
try {
   Rename-Computer -ComputerName $env:COMPUTERNAME -NewName $computerName -ErrorAction Stop
   Write-Host "ServerName has been changed to $($computerName)" -ForegroundColor Green
}
catch {
   Write-Warning -Message $("Failed to disable Ie Security Configuration. Error: "+ $_.Exception.Message)
   Break;
}

#Setting up the stage 2 script execution
try {
   New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
   Set-Location -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
   New-ItemProperty -Name adsec2 -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -PropertyType String -Value "Powershell C:\adsec\temp\dc2.ps1"
}
catch {
   Write-Warning -Message $("Failed to set the registry to run stage 1. Error: "+ $_.Exception.Message)
   Break;
}

#Restart the Computer
try {
   Write-Host "Rebooting the system, the installation will continue after reboot. Please login with Administrator login once the system reboots"
   Start-Sleep 3
   Restart-Computer  -ErrorAction Stop
}
catch {
   Write-Warning -Message $("Failed to Restart the Computer. Error: "+ $_.Exception.Message)
   Break;
}

#Disable the server manager pop up
New-ItemProperty -Path HKCU:\Software\Microsoft\ServerManager -Name DoNotOpenServerManagerAtLogon -PropertyType DWORD -Value "0x1" –Force