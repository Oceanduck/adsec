# ADSec Labs - Scripts

This directory contains utility scripts for setting up and managing the ADSec lab environment.

## Scripts

### setup-adsecvm.sh

**Purpose:** Configure the adsecvm (Ubuntu) system for running Ansible and student lab work.

**What it does:**
- Creates `/home/adsec/labs/` directory structure (lab1-lab11)
- Installs required packages (hashcat, python3, ssh tools)
- Configures helpful shell aliases and functions
- Creates documentation and system info files
- Prepares the VM for Ansible execution

**Usage:**

```bash
# 1. Download the script to adsecvm
wget https://github.com/Oceanduck/adsec-labs/raw/main/scripts/setup-adsecvm.sh

# OR if you have git:
git clone https://github.com/Oceanduck/adsec-labs.git
cd adsec-labs/scripts/

# 2. Make it executable
chmod +x setup-adsecvm.sh

# 3. Run as adsec user
./setup-adsecvm.sh

# 4. Reload shell configuration
source ~/.bashrc
```

**Requirements:**
- Ubuntu 20.04 or later
- User: `adsec`
- Sudo privileges for package installation

**After Setup:**

The script creates helpful aliases:
- `labs` - Navigate to labs directory
- `tools` - Navigate to tools directory
- `lab X` - Navigate to specific lab folder (e.g., `lab 5`)
- `crack [mode] [file]` - Quick hashcat wrapper

**Example:**
```bash
# Navigate to lab 5
lab 5

# Crack a hash
crack 18200 asrep-hashes.txt
```

## Directory Structure After Setup

```
/home/adsec/
├── labs/                      # Lab working directories
│   ├── lab1/
│   ├── lab2/
│   ├── lab3/
│   ├── lab4/
│   ├── lab5/
│   ├── lab6/
│   ├── lab7/
│   ├── lab8/
│   ├── lab9/
│   ├── lab10/
│   ├── lab11/
│   └── README.md              # Lab usage instructions
├── tools/                     # Tools directory
│   ├── impacket/              # Python attack tools (installed by Ansible)
│   ├── hashcat                # Password cracker
│   └── passwords.txt          # Password wordlist (2,121 passwords)
├── SYSTEM_INFO.txt            # System information
└── .adsecvm-setup-complete    # Setup completion marker
```

## Integration with Lab Workflow

1. **Lab 0A**: Students run `setup-adsecvm.sh` on the adsecvm
2. **Lab 0B**: Students clone adsec-ansible and run playbooks from adsecvm
3. **Lab 1-11**: Students use `/home/adsec/labs/labX/` directories for outputs

## Troubleshooting

**Script fails with "must be run as adsec user"**
```bash
su - adsec
./setup-adsecvm.sh
```

**Package installation fails**
```bash
sudo apt-get update
sudo apt-get upgrade
./setup-adsecvm.sh
```

**Aliases not working**
```bash
source ~/.bashrc
```

## Support

For issues or questions: training@rudrasec.io

