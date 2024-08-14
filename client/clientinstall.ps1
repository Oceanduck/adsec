<#
Create a Windows CLient - and join the talespin domain
#>

Clear-host
write-host "Running Stage 0 - Starting installation of Client"
write-host "This tool should not be run in production"
write-host "this process would take betwen 10-15 minutes"
Read-Host -Prompt "Press any key to continue or CTRL+C to quit. Once you continue the system will be renamed, ip address set, connected to the talespin domain and tools downloaded " | Out-Null

#Define variables, by default the script uses the C"\adsec directory
$myDownloadUrl = "https://github.com/Oceanduck/adsec/blob/main/client/client.zip"
$zipFile = "c:\adsec\temp\client.zip"
$workingDir = "C:\adsec"
$tempDir ="C:\adsec\temp"

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

#Download the required archive
New-Item -ItemType Directory -Force -Path $tempDir
downloadFile $myDownloadUrl "c:\adsec\client.zip"
Expand-Archive $zipFile -DestinationPath $tempDir -Force 

#Execute stage 1
Write-Host "Executing stage 1"
Powershell.exe -executionpolicy bypass -File  "$tempDir\client1.ps1"