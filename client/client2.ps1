
$workingDir = "C:\adsec" 

#pass Credentials for a normal user
Add-Computer -DomainName talespin.local 

#Download and Install mkdocs
Write-Host "Downloading and installing mkdocs for wiki ..."
python pip install mkdocs 
python pip install mkdocs-material

# Create a service to run mkdocs
python -m mkdocs new C:\adsec\adsec-wiki


#Download markdown files from github
Get mkdocs.yml  files

# powershell -ep bypass "python -m mkdocs serve -f C:\adsec\adsec-wiki\mkdocs.yml" 

$params = @{
    Name = "adsec-wiki"
    BinaryPathName = 'cmd /c "python -m mkdocs serve -f C:\adsec\adsec-wiki\mkdocs.yml"'
    DisplayName = "adsec-wiki"
    StartupType = "Automatic"
    Description = "Service to run the adsec wiki"
  }
New-Service @params
Start-Service -Name "adsec-wiki"


#Create a directory 
C:\adsec\tools

New-Item -ItemType Directory -Force -Path $tempDir
Invoke-WebRequest $myDownloadUrl -OutFile c:\adsec\temp\init.zip
Expand-Archive $zipFile -DestinationPath $tempDir -Force 

dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all
wsl.exe --install
wsl.exe --update
wsl --set-default-version 2
wsl --set-version kali-linux 2
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Invoke-WebRequest -Uri https://aka.ms/wsl-kali-linux-new -OutFile Kali.appx -UseBasicParsing
Add-AppxPackage .\Kali.appx
kali config --default-user root


Expand-Archive $zipFile -DestinationPath $tempDir -Force 

https://github.com/GhostPack/Rubeus/archive/refs/heads/master.zip 
https://github.com/PowerShellMafia/PowerSploit/archive/refs/heads/master.zip 
https://github.com/gentilkiwi/mimikatz/archive/refs/heads/master.zip 