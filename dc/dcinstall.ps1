<#
    .Synopsis
       Create and Active Directory domain 'talespin' with a Windows2016 DFS on a Windows 2019 OS
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

Write-Host "Welcome to Active Directory Security Workshop"
write-host "Running Stage 0 - Starting installation"
write-host "This tool should not be run in production."
write-host "This script will configure this server into a Domain Controller. It would reboot multiple times and would need you to provide credentials for the Administrator when it reboots"
write-host "this process would take betwen 15-20 minutes"
Read-Host -Prompt "Press any key to continue or CTRL+C to quit" | Out-Null

#Define variables, by default the script uses the C"\adsec directory
$myDownloadUrl = "https://raw.githubusercontent.com/Oceanduck/adsec/main/dc/dc.zip"
$zipFile = "c:\adsec\temp\dc.zip"
$workingDir = "C:\adsec"
$tempDir ="C:\adsec\temp"

# Function to Download file

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

#Download the required archive from Github
Write-Output "Creating a temporary Directory $tempDir and downloading the Script to create Active Directory."
New-Item -ItemType Directory -Force -Path $tempDir | Select Name
downloadFile $myDownloadUrl "c:\adsec\temp\dc.zip"
Expand-Archive $zipFile -DestinationPath $tempDir -Force 

#Execute stage 1
Write-Host "Executing stage 1"
Start-Sleep 3
Powershell.exe -executionpolicy bypass -File  "$tempDir\dc1.ps1"