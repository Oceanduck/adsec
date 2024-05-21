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
       Download the files needed to create a domain and create a domain

       By Default the name of the directory is talespin.local
    #>

#Define variables, by default the script uses the C"\adsec directory
$myDownloadUrl = "https://github.com/Oceanduck/adsec/blob/main/init.zip"
$zipFile = "c:\adsec\temp\init.zip"
$workingDir = "C:\adsec"
$tempDir ="C:\adsec\temp"


#Download the required archive
New-Item -ItemType Directory -Force -Path $tempDir
Invoke-WebRequest $myDownloadUrl -OutFile c:\adsec\temp\init.zip
Expand-Archive $zipFile -DestinationPath $tempDir -Force 

#Execute stage 1
Powershell.exe -executionpolicy bypass -File  "$tempDir\1.ps1"

