Clear-host
write-host "Running Stage 3 - Configuring Active Directory"
write-host "This tool should not be run in production"

#Configure the varaiable for the domain
$ntpserver1 = '0.au.pool.ntp.org'
$ntpserver2 = '1.au.pool.ntp.org'

# Network Variables
$globalsubnet = '192.168.8.0/24' # Global Subnet will be used in DNS Reverse Record and AD Sites and Services Subnet
$subnetlocation = 'CapeSuzette'

#Variables for Directory
$workingDir = "C:\adsec"
$tempDir ="C:\adsec\temp"

# Add DNS Reverse Record
Try{
    Add-DnsServerPrimaryZone -NetworkId $globalsubnet -DynamicUpdate Secure -ReplicationScope Domain -ErrorAction Stop
    Write-Host "Successfully added in $($globalsubnet) as a reverse lookup within DNS" -ForegroundColor Green
    }
Catch{
     Write-Warning -Message $("Failed to create reverse DNS lookups zone for network $($globalsubnet). Error: "+ $_.Exception.Message)
     Break;
     }

# Add DNS Scavenging
#Set-DnsServerScavenging -ScavengingState $true -ScavengingInterval 7.00:00:00 -Verbose
#Set-DnsServerZoneAging talespin.local -Aging $true -RefreshInterval 7.00:00:00 -NoRefreshInterval 7.00:00:00 -Verbose
#Set-DnsServerZoneAging 8.168.192.in-addr.arpa -Aging $true -RefreshInterval 7.00:00:00 -NoRefreshInterval 7.00:00:00 -Verbose
#Get-DnsServerScavenging

# Create Active Directory Sites and Services Subnet
Try{
    New-ADReplicationSubnet -Name $globalsubnet -Site "Default-First-Site-Name" -Location $subnetlocation -ErrorAction Stop
    Write-Host "Successfully added Subnet $($globalsubnet) with location $($subnetlocation) in AD Sites and Services" -ForegroundColor Green
    }
Catch{
     Write-Warning -Message $("Failed to create Subnet $($globalsubnet) in AD Sites and Services. Error: "+ $_.Exception.Message)
     Break;
     }

# Add NTP settings to PDC
$serverpdc = Get-AdDomainController -Filter * | Where {$_.OperationMasterRoles -contains "PDCEmulator"}
IF ($serverpdc)
    {
    Try{
        Start-Process -FilePath "C:\Windows\System32\w32tm.exe" -ArgumentList "/config /manualpeerlist:$($ntpserver1),$($ntpserver2) /syncfromflags:MANUAL /reliable:yes /update" -ErrorAction Stop
        Stop-Service w32time -ErrorAction Stop
        sleep 2
        Start-Service w32time -ErrorAction Stop
        Write-Host "Successfully set NTP Servers: $($ntpserver1) and $($ntpserver2)" -ForegroundColor Green
        }
    Catch{
          Write-Warning -Message $("Failed to set NTP Servers. Error: "+ $_.Exception.Message)
     Break;
     }
    }

#Add Users to the Domain 

$Users = Import-Csv -Delimiter "," -Path "$tempDir\users.csv"

foreach ($User in $Users) {
  $SAM = $User.Username
  $Displayname = $User.Displayname
  $Firstname = $User.Firstname
  $Lastname = $User.Lastname
  $UPN = $User.Username + "@talespin.local"
  $Password = (ConvertTo-SecureString $User.Password -AsPlainText -Force)
  
  New-ADUser -Name "$Displayname" -DisplayName "$Displayname" -SamAccountName "$SAM" -UserPrincipalName "$UPN" -GivenName "$Firstname" -Surname "$Lastname" -AccountPassword $Password -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true
  Write-Host "Created user: $SAM"
}

#Add Wildcat to domain admin group
Add-ADGroupMember -Identity "Domain Admins" -Members wildcat

Write-Host "The Active Directory has been created"
read-host “Press ENTER to continue...”