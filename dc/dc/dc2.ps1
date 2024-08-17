
Clear-host
write-host "Running Stage 2 - Installing Domain Services"
Start-Sleep 3
write-host "This tool should not be run in production"

#Configure the varaiable for the domain
$domainName  = "talespin.local"
$netBIOSname = "talespin"
$mode  = "WinThreshold"

$SafePassPlain = "Password@123"
$SafePass = ConvertTo-SecureString -string $SafePassPlain -AsPlainText -force
#Install ADDS

try {
    Install-WindowsFeature -Name AD-Domain-Services -ErrorAction Stop
    Install-WindowsFeature -Name RSAT-ADDS -ErrorAction Stop
    Install-ADDSForest -DomainName $domainName -ForestMode $mode -Domainmode $mode -SafeModeAdministratorPassword $SafePass -NoRebootOnCompletion -force
    Write-Host "ADDS Configured"
}
catch {
    Write-Warning -Message $("Failed to configure ADDS. Error: "+ $_.Exception.Message)
    Break;
}

#Setting up the stage 3 script execution
try {
   Set-Location -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
   New-ItemProperty -Name adsec3 -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -PropertyType String -Value "Powershell C:\adsec\temp\dc3.ps1"
}
catch {
   Write-Warning -Message $("Failed to set the registry to run stage 3. Error: "+ $_.Exception.Message)
   Break;
}

#Restart the Computer
try {
    Restart-Computer -ErrorAction Stop
    Write-Host "Rebooting the system now, the installation will continue after reboot."
    Start-Sleep 3
 }
 catch {
    Write-Warning -Message $("Failed to Restart the Computer. Error: "+ $_.Exception.Message)
    Break;
 }

