#!/bin/bash
###############################################################################
# ADSec VM Setup Script
#
# Purpose: Configure the adsecvm (Ubuntu) for running Ansible and student labs
#
# This script:
# - Creates lab working directories
# - Installs required packages
# - Sets up helpful shell environment
# - Prepares the system for Ansible execution
#
# Usage:
#   chmod +x setup-adsecvm.sh
#   ./setup-adsecvm.sh
#
# Author: Rudrasec Pty Ltd
# Version: 1.0
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as adsec user
if [ "$USER" != "adsec" ]; then
    print_error "This script must be run as the 'adsec' user"
    print_info "Please run: su - adsec"
    exit 1
fi

print_info "Starting ADSec VM configuration..."

###############################################################################
# 1. Create Lab Directory Structure
###############################################################################

print_info "Creating lab directory structure..."

# Create main labs directory and subdirectories
mkdir -p /home/adsec/labs/{lab1,lab2,lab3,lab4,lab5,lab6,lab7,lab8,lab9,lab10,lab11}
chmod -R 755 /home/adsec/labs

print_info "Lab directories created:"
ls -l /home/adsec/labs/

###############################################################################
# 2. Create Labs README
###############################################################################

print_info "Creating labs README..."

cat > /home/adsec/labs/README.md << 'EOF'
# ADSec Lab Working Directories

Each lab folder is for storing outputs, hashes, pcaps, and files from the corresponding lab exercise.

## Lab Overview

- **lab1-lab3**: AD Reconnaissance & DACL Abuse
- **lab4**: NTLM Relay & Responder
- **lab5**: AS-REQ Roasting
- **lab6**: AS-REP Roasting
- **lab7**: Kerberoasting
- **lab8**: Golden Ticket
- **lab9**: Silver Ticket
- **lab10**: Unconstrained Delegation
- **lab11**: Constrained Delegation

## Common Commands

### Copy files from Windows
```bash
# From client1
scp adsec@client1:/path/to/file.txt ~/labs/lab5/

# Example: Copy hash file
scp baloo@192.168.100.21:C:/adsec/hashes.txt ~/labs/lab7/
```

### Hashcat Commands
```bash
# Identify hash type
hashcat hashfile.txt --identify

# Crack hash (using passwords.txt from tools directory)
hashcat -a 0 -m [mode] hashfile.txt ~/tools/passwords.txt

# Show cracked passwords
hashcat -m [mode] hashfile.txt --show
```

### Useful Paths
- **Tools directory**: ~/tools/
- **Password wordlist**: ~/tools/passwords.txt (2,121 passwords)
- **Impacket tools**: ~/tools/impacket/ (installed by Ansible)

**Note:** The passwords.txt file contains 2,121 passwords in the format `Word#Number` (e.g., Pirate#1, Kingkong#3) for use in lab cracking exercises.

## Tips

- Keep each lab's files in its respective folder for organization
- Use descriptive filenames: `lab5-asreq-hashes.txt` not `output.txt`
- Check the lab wiki for specific instructions

EOF

chmod 644 /home/adsec/labs/README.md

###############################################################################
# 3. Install Required Packages
###############################################################################

print_info "Checking and installing required packages..."

# Update package list
print_info "Updating package list (requires sudo)..."
sudo apt-get update -qq

# List of required packages
PACKAGES=(
    "hashcat"
    "python3"
    "python3-pip"
    "sshpass"
    "openssh-client"
    "curl"
    "wget"
    "git"
    "net-tools"
    "vim"
    "tree"
)

for package in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $package"; then
        print_info "$package is already installed"
    else
        print_info "Installing $package..."
        sudo apt-get install -y "$package" > /dev/null 2>&1
    fi
done

###############################################################################
# 4. Configure Shell Environment
###############################################################################

print_info "Configuring shell environment..."

# Backup existing .bashrc
if [ -f /home/adsec/.bashrc ]; then
    cp /home/adsec/.bashrc /home/adsec/.bashrc.backup.$(date +%Y%m%d)
fi

# Add ADSec-specific configuration to .bashrc
if ! grep -q "# ADSec Lab Configuration" /home/adsec/.bashrc; then
    cat >> /home/adsec/.bashrc << 'EOF'

###############################################################################
# ADSec Lab Configuration
###############################################################################

# Helpful aliases
alias labs='cd ~/labs && ls -la'
alias tools='cd ~/tools && ls -la'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# Show current lab directory
lab() {
    if [ -z "$1" ]; then
        echo "Usage: lab [1-11]"
        echo "Example: lab 5"
        return 1
    fi
    cd ~/labs/lab$1 && pwd && ls -la
}

# Quick hashcat wrapper
crack() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: crack [mode] [hashfile]"
        echo "Example: crack 18200 asrep-hashes.txt"
        return 1
    fi
    hashcat -a 0 -m $1 $2 ~/tools/passwords.txt
}

# Welcome message
echo ""
echo "=========================================="
echo "  ADSec VM - Lab Environment Ready"
echo "=========================================="
echo "Lab directories: ~/labs/lab[1-11]"
echo "Tools directory: ~/tools/"
echo ""
echo "Quick commands:"
echo "  labs     - Go to labs directory"
echo "  tools    - Go to tools directory"
echo "  lab X    - Go to specific lab folder"
echo "  crack    - Quick hashcat wrapper"
echo ""
echo "For help: cat ~/labs/README.md"
echo "=========================================="
echo ""

EOF
    print_info "Shell configuration added to .bashrc"
else
    print_warn "ADSec configuration already exists in .bashrc"
fi

###############################################################################
# 5. Verify Tools Directory
###############################################################################

print_info "Verifying tools directory..."

if [ ! -d /home/adsec/tools ]; then
    print_info "Creating tools directory..."
    mkdir -p /home/adsec/tools
    chmod 755 /home/adsec/tools
else
    print_info "Tools directory exists"
fi

###############################################################################
# 6. Create System Information File
###############################################################################

print_info "Creating system information file..."

cat > /home/adsec/SYSTEM_INFO.txt << EOF
ADSec VM System Information
===========================

Hostname: $(hostname)
IP Address: $(hostname -I | awk '{print $1}')
OS: $(lsb_release -d | cut -f2)
Kernel: $(uname -r)

Setup completed: $(date)

Directory Structure:
-------------------
/home/adsec/
├── labs/           # Lab working directories (lab1-lab11)
├── tools/          # Attack tools and utilities
│   ├── impacket/   # Python attack tools (installed by Ansible)
│   ├── hashcat     # Password cracker
│   └── passwords.txt  # Password wordlist for cracking (2,121 passwords)
└── SYSTEM_INFO.txt # This file

Next Steps:
-----------
1. Review /home/adsec/labs/README.md for usage instructions
2. Clone adsec-ansible repository
3. Run Ansible playbooks to configure DC, client1, and db-server
4. Start lab exercises from the wiki

Useful Commands:
----------------
labs    - Navigate to labs directory
tools   - Navigate to tools directory
lab X   - Navigate to specific lab folder (X = 1-11)
crack   - Quick hashcat wrapper

Documentation:
--------------
Lab Wiki: labs.rudrasec.io (requires authentication)
Support: training@rudrasec.io

EOF

chmod 644 /home/adsec/SYSTEM_INFO.txt

###############################################################################
# 7. Final Verification
###############################################################################

print_info "Performing final verification..."

# Check directories
if [ -d /home/adsec/labs ] && [ -d /home/adsec/tools ]; then
    print_info "✓ Directory structure verified"
else
    print_error "✗ Directory structure incomplete"
    exit 1
fi

# Check key packages
if command -v hashcat &> /dev/null; then
    print_info "✓ Hashcat installed: $(hashcat --version | head -1)"
else
    print_warn "✗ Hashcat not found"
fi

if command -v python3 &> /dev/null; then
    print_info "✓ Python3 installed: $(python3 --version)"
else
    print_warn "✗ Python3 not found"
fi

###############################################################################
# 8. Summary
###############################################################################

echo ""
echo "=========================================="
echo "  ADSec VM Setup Complete!"
echo "=========================================="
echo ""
echo "✓ Lab directories created: /home/adsec/labs/"
echo "✓ Tools directory ready: /home/adsec/tools/"
echo "✓ Shell environment configured"
echo "✓ Required packages installed"
echo ""
echo "Next Steps:"
echo "1. Log out and log back in (or run: source ~/.bashrc)"
echo "2. Review system info: cat ~/SYSTEM_INFO.txt"
echo "3. Clone adsec-ansible to set up lab infrastructure"
echo "4. Start with Lab 0A from the wiki"
echo ""
echo "For support: training@rudrasec.io"
echo "=========================================="
echo ""

print_info "Setup log saved to: /home/adsec/setup-adsecvm.log"

# Save completion marker
echo "ADSec VM setup completed on $(date)" > /home/adsec/.adsecvm-setup-complete

exit 0
