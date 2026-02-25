# ADSec Labs - Tools & Resources

Public repository containing tools, scripts, and resources for the Active Directory Security (ADSec) course labs.

## Overview

This repository provides students with necessary tools and files referenced throughout the ADSec course labs. All tools are provided for **educational purposes only** as part of authorized security training exercises.

## Repository Structure

```
adsec-labs/
├── powershell/              # PowerShell modules and scripts
│   ├── Microsoft.ActiveDirectory.Management.dll
│   └── Powermad.ps1
├── tools/                   # Attack tools and binaries
│   ├── Rubeus.zip
│   └── SpoolSample.exe
├── scripts/                 # Python and automation scripts
│   └── as_req_roast.py
├── pcaps/                   # Network capture files
│   └── louie-asreq.pcapng
├── wordlists/              # Password lists for cracking
│   └── passwords.txt
└── README.md
```

## Repository Contents

### PowerShell Modules & Scripts

#### Microsoft.ActiveDirectory.Management.dll
- **Purpose**: Active Directory PowerShell module for AD enumeration and management
- **Usage**:
  ```powershell
  Import-Module .\powershell\Microsoft.ActiveDirectory.Management.dll
  Get-ADUser -Filter *
  ```
- **Labs**: Used across multiple enumeration labs

#### Powermad.ps1
- **Purpose**: PowerShell tool for Active Directory security testing
- **Features**: Machine account manipulation, DNS operations
- **Usage**:
  ```powershell
  Import-Module .\powershell\Powermad.ps1
  ```
- **Reference**: [Kevin-Robertson/Powermad](https://github.com/Kevin-Robertson/Powermad)

### Tools & Binaries

#### Rubeus.zip
- **Purpose**: C# toolset for raw Kerberos interaction and abuse
- **Features**: Ticket manipulation, Kerberoasting, AS-REP roasting
- **Usage**: Extract and run from command line
- **Reference**: [GhostPack/Rubeus](https://github.com/GhostPack/Rubeus)

#### SpoolSample.exe
- **Purpose**: PoC for coercing Windows hosts to authenticate to other machines
- **Usage**: Printer bug exploitation for relay attacks
- **Reference**: [leechristensen/SpoolSample](https://github.com/leechristensen/SpoolSample)

### Python Scripts

#### as_req_roast.py
- **Purpose**: Extract AS-REQ encrypted timestamps from PCAP files for offline cracking
- **Dependencies**: scapy
- **Usage**:
  ```bash
  python3 scripts/as_req_roast.py [pcap_file] [FQDN]
  # Example:
  python3 scripts/as_req_roast.py pcaps/louie-asreq.pcapng talespin.lab
  ```
- **Output**: Hashcat-compatible format for AS-REP roasting

### Lab Files

#### louie-asreq.pcapng
- **Purpose**: Network capture containing Kerberos AS-REQ authentication traffic
- **Used in**: Lab 5 - AS-REQ Roasting
- **Contains**: Pre-authentication requests with encrypted timestamps

#### passwords.txt
- **Purpose**: Password list for hash cracking exercises
- **Size**: 2,121 passwords
- **Contains**:
  - Lab environment passwords
  - Common weak passwords
  - Training-specific password patterns
- **Used in**: Password cracking labs (AS-REP roasting, Kerberoasting)

## Installation & Setup

### Quick Start

```bash
# Clone the repository
git clone https://github.com/Oceanduck/adsec-labs.git
cd adsec-labs

# For Python scripts, install dependencies
pip3 install scapy

# PowerShell modules can be imported directly
Import-Module .\powershell\Microsoft.ActiveDirectory.Management.dll
Import-Module .\powershell\Powermad.ps1
```

### Python Dependencies

```bash
pip3 install scapy
```

### Windows Environment

Most tools are designed to run on Windows machines within the ADSec lab environment. Ensure you have:
- PowerShell 5.1 or higher
- .NET Framework 4.5 or higher
- Administrative privileges (for certain operations)

## Lab Environment

These tools are designed to work with the ADSec lab environment:
- **Domain**: talespin.lab
- **Domain Controller**: dc1.talespin.lab (192.168.100.11)

See the [ADSec Wiki](https://github.com/Oceanduck/adsec-wiki) for complete lab setup instructions.

## Usage Examples

### AS-REQ Roasting

```bash
# Extract hash from PCAP
python3 scripts/as_req_roast.py pcaps/louie-asreq.pcapng talespin.lab > hash.txt

# Crack with hashcat
hashcat -m 19900 hash.txt wordlists/passwords.txt
```

### Active Directory Enumeration

```powershell
# Import AD module
Import-Module .\powershell\Microsoft.ActiveDirectory.Management.dll

# Enumerate users
Get-ADUser -Filter * -Properties *

# Find SPNs
Get-ADUser -Filter {ServicePrincipalName -ne "$null"} -Properties ServicePrincipalName
```

### Kerberos Attacks

```powershell
# Extract Rubeus first
Expand-Archive -Path .\tools\Rubeus.zip -DestinationPath .\tools\

# Kerberoasting with Rubeus
.\tools\Rubeus.exe kerberoast /outfile:hashes.txt

# AS-REP roasting
.\tools\Rubeus.exe asreproast /outfile:asrep_hashes.txt
```

## Security & Legal Notice

⚠️ **EDUCATIONAL USE ONLY**

- These tools are provided **exclusively** for use in the ADSec course lab environment
- All tools must only be used on systems you own or have explicit authorization to test
- Unauthorized use of these tools against systems you do not own is **illegal**
- Students must comply with all applicable laws and the course Code of Conduct

## Lab Downloads

For individual lab files referenced in specific exercises, use the following download commands:

```bash
# AS-REQ Roasting Lab (Lab 5)
wget -O /tmp/louie-asreq.zip https://github.com/Oceanduck/adsec-labs/raw/refs/heads/main/louie-asreq.zip
unzip /tmp/louie-asreq.zip -d /home/adsec/tools/
```

## Course Resources

- **Course Wiki**: [adsec-wiki](https://github.com/Oceanduck/adsec-wiki) (Private - Lab exercises and documentation)
- **Lab Environment**: [adsec-ansible](https://github.com/Oceanduck/adsec-ansible) (Private - Infrastructure automation)
- **Course Website**: [rudrasec.io](https://rudrasec.io)

## Support

For questions or issues:
- Check the [ADSec Wiki](https://github.com/Oceanduck/adsec-wiki) for lab-specific guidance
- Contact your instructor
- Report tool issues via GitHub Issues

## License

These tools are aggregated from various open-source projects. Please refer to individual tool repositories for specific licensing:
- Rubeus: BSD 3-Clause License
- Powermad: BSD 3-Clause License
- SpoolSample: Public Domain

This repository is maintained for educational purposes as part of the Rudrasec ADSec training course.

---

**Rudrasec Pty Ltd** | Active Directory Security Training
