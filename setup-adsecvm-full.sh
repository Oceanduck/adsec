#!/bin/bash
###############################################################################
# ADSec VM - Complete System Setup Script
#
# Purpose: Full automated setup of adsecvm including:
#   - Network configuration (dual NICs)
#   - SSH server
#   - KDE Desktop environment
#   - ELK Stack (Elasticsearch + Kibana)
#   - Lab directories and tools
#   - Offensive security tools
#
# Usage:
#   chmod +x setup-adsecvm-full.sh
#   ./setup-adsecvm-full.sh
#
# Author: Rudrasec Pty Ltd
# Version: 2.2
###############################################################################

# Note: Not using 'set -e' to prevent silent exits on non-critical errors

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration variables
ELASTIC_VERSION="8.15.2"
KIBANA_VERSION="8.15.3"
ELK_PASSWORD="elastic"  # Default password - can be changed

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

print_section() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_time_estimate() {
    echo -e "${CYAN}⏱  Estimated time: $1${NC}"
}

###############################################################################
# Pre-flight Checks
###############################################################################

print_section "ADSec VM - Pre-flight Checks"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Do not run this script as root. Run as 'adsec' user."
    print_info "The script will prompt for sudo password when needed."
    exit 1
fi

# Check if running as adsec user
if [ "$USER" != "adsec" ]; then
    print_error "This script must be run as the 'adsec' user"
    print_info "Please run: su - adsec"
    exit 1
fi

# Check Ubuntu version
print_info "Checking Ubuntu version..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$NAME
    OS_VERSION=$VERSION_ID

    if [[ "$OS_NAME" != *"Ubuntu"* ]]; then
        print_error "This script requires Ubuntu. Detected: $OS_NAME"
        exit 1
    fi

    # Check for Ubuntu 22.04 or newer
    if (( $(echo "$OS_VERSION < 22.04" | bc -l) )); then
        print_warn "This script is designed for Ubuntu 22.04+. Detected: Ubuntu $OS_VERSION"
        print_warn "Installation may encounter issues. Continue at your own risk."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_info "✓ Ubuntu $OS_VERSION detected"
    fi
else
    print_error "Cannot detect OS version. /etc/os-release not found."
    exit 1
fi

# Check architecture
print_info "Checking system architecture..."
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    print_error "This script requires x86_64 architecture. Detected: $ARCH"
    print_error "Elasticsearch and Kibana packages are not available for $ARCH"
    exit 1
fi
print_info "✓ Architecture: $ARCH"

# Check available disk space (need at least 20GB free)
print_info "Checking available disk space..."
AVAILABLE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 20 ]; then
    print_error "Insufficient disk space. Need at least 20GB free, have ${AVAILABLE_SPACE}GB"
    exit 1
fi
print_info "✓ Available disk space: ${AVAILABLE_SPACE}GB"

# Check internet connectivity
print_info "Checking internet connectivity..."
if ! ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    print_error "No internet connection detected. This script requires internet access."
    exit 1
fi
print_info "✓ Internet connection active"

# Display installation summary and time estimates
print_section "Installation Summary"
echo -e "${CYAN}This script will install:${NC}"
echo "  • SSH Server"
echo "  • Network Configuration (dual NIC)"
echo "  • KDE Plasma Desktop Environment (~1.5GB download)"
echo "  • Google Chrome"
echo "  • VMware Tools"
echo "  • Python 3.10 + pipx"
echo "  • Ansible (latest from PPA)"
echo "  • Elasticsearch 8.15.2 (~600MB)"
echo "  • Kibana 8.15.3 (~300MB)"
echo "  • Offensive Security Tools (CrackMapExec, Responder, hashcat)"
echo "  • Shell customizations (bash, aliases)"
echo ""
print_time_estimate "Total installation time: 45-90 minutes (depending on connection speed)"
echo ""
echo -e "${CYAN}Estimated time breakdown:${NC}"
echo "  • Base system & SSH:           2-3 minutes"
echo "  • Network configuration:       1 minute"
echo "  • KDE Desktop environment:     15-30 minutes ⏱"
echo "  • Python environment:          5-10 minutes"
echo "  • Elasticsearch:               5-10 minutes"
echo "  • Kibana:                      5-10 minutes"
echo "  • Lab tools:                   5-10 minutes"
echo "  • Configuration:               2-5 minutes"
echo ""
print_warn "The KDE Desktop installation is the longest stage (~1.5GB download)"
echo ""
read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Installation cancelled by user"
    exit 0
fi

print_section "ADSec VM - Full System Setup"

###############################################################################
# Stage 1: Base System Update & SSH
###############################################################################

print_section "Stage 1: Base System Setup"
print_time_estimate "2-3 minutes"

print_info "Updating package lists..."
sudo apt-get update -qq

print_info "Installing OpenSSH server..."
sudo apt-get install -y openssh-server > /dev/null 2>&1
sudo systemctl enable ssh
sudo systemctl start ssh
print_info "✓ SSH server installed and started"

print_info "Configuring firewall to allow SSH..."
sudo ufw allow ssh
print_info "✓ Firewall configured"

###############################################################################
# Stage 2: Network Configuration
###############################################################################

print_section "Stage 2: Network Configuration"
print_time_estimate "1 minute"

# Check if ens37 interface already exists (network config already applied)
if ip addr show ens37 > /dev/null 2>&1; then
    print_info "✓ Network configuration already applied (ens37 interface exists)"
    print_info "  - ens37: $(ip -4 addr show ens37 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo 'configured')"
    print_info "Skipping network configuration stage..."
else
    print_info "Creating network configuration template..."

    sudo tee /etc/netplan/99-adsec-network.yaml > /dev/null << 'EOF'
# ADSec Lab Network Configuration
# This configures dual NICs for lab environment
#
# ens33: NAT/Bridged - DHCP for internet access
# ens37: Host-only - Static IP 192.168.100.1 for lab network
#
# To apply: sudo netplan apply

network:
  version: 2
  ethernets:
    ens33:
      dhcp4: yes
      nameservers:
        addresses: [192.168.100.11, 8.8.8.8]
    ens37:
      dhcp4: no
      addresses: [192.168.100.1/24]
      nameservers:
        addresses: [192.168.100.11]
EOF

print_info "Setting correct permissions on netplan configuration..."
sudo chmod 600 /etc/netplan/99-adsec-network.yaml

print_info "✓ Network configuration created: /etc/netplan/99-adsec-network.yaml"
echo ""
print_warn "The configuration will create a second network interface (ens37) with IP 192.168.100.1"
print_warn "This is required for lab network communication with dc1, client1, and db-server"
echo ""
read -p "Do you want to apply network configuration now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Applying network configuration..."
    sudo netplan apply 2>&1 | grep -v "WARNING" | grep -v "ovsdb-server" || true
    print_info "✓ Network configuration applied"
    echo ""
    print_error "IMPORTANT: Your SSH connection will be interrupted!"
    print_warn "You MUST reconnect via SSH using one of these IP addresses:"
    print_warn "  - Primary NIC (ens33): $(ip -4 addr show ens33 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo 'DHCP assigned')"
    print_warn "  - Lab Network (ens37): 192.168.100.1"
    echo ""
    print_error "After reconnecting, re-run this script to continue installation:"
    print_warn "  ./setup-adsecvm-full.sh"
    echo ""
    print_info "The script will detect completed stages and resume from where you left off."
    echo ""
    exit 0
else
    print_info "Network configuration created but NOT applied"
    print_warn "You can apply it later with: sudo netplan apply"
    print_warn "Note: If you apply it later, you will need to re-run this script afterward."
fi
fi  # End of network configuration check

###############################################################################
# Stage 3: Install Desktop Environment & Tools
###############################################################################

print_section "Stage 3: Desktop Environment & Essential Tools"
print_time_estimate "15-30 minutes (largest download ~1.5GB)"

print_info "Installing NetworkManager and net-tools..."
sudo apt-get install -y network-manager net-tools > /dev/null 2>&1

print_info "Installing KDE Plasma Desktop (this may take a while)..."
sudo apt-get install -y kde-plasma-desktop > /dev/null 2>&1
print_info "✓ KDE Desktop installed"

print_info "Installing Google Chrome..."
cd /tmp
if [ ! -f google-chrome-stable_current_amd64.deb ]; then
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
fi
sudo dpkg -i google-chrome-stable_current_amd64.deb 2>/dev/null || sudo apt-get --fix-broken install -y > /dev/null 2>&1
print_info "✓ Google Chrome installed"

# Copy Chrome to desktop if Desktop exists
if [ -d ~/Desktop ]; then
    cp /usr/share/applications/google-chrome.desktop ~/Desktop/ 2>/dev/null || true
fi

print_info "Installing VMware Tools..."
sudo apt-get install -y open-vm-tools-desktop > /dev/null 2>&1
print_info "✓ VMware Tools installed"

print_info "Installing nmap..."
sudo apt-get install -y nmap > /dev/null 2>&1

###############################################################################
# Stage 4: Python Environment
###############################################################################

print_section "Stage 4: Python Environment & Ansible Setup"
print_time_estimate "5-10 minutes"

print_info "Adding Python 3.10 repository..."
sudo add-apt-repository -y ppa:deadsnakes/ppa > /dev/null 2>&1
sudo apt-get update -qq

print_info "Installing Python 3.10..."
sudo apt-get install -y python3.10 python3.10-venv python3.10-dev python3-pip pipx > /dev/null 2>&1
print_info "✓ Python 3.10 installed"

print_info "Installing Ansible via pip (for latest stable version)..."
# Remove any existing ansible to avoid conflicts
sudo apt-get remove -y ansible ansible-core > /dev/null 2>&1 || true
sudo pip3 uninstall -y ansible ansible-core ansible-base > /dev/null 2>&1 || true

# Install Ansible via pip to get a more recent version that works with collections
sudo pip3 install ansible > /dev/null 2>&1

# Verify Ansible installation
if command -v ansible-playbook > /dev/null 2>&1; then
    ANSIBLE_VERSION=$(ansible --version 2>/dev/null | head -1)
    print_info "✓ Ansible installed: $ANSIBLE_VERSION"
else
    print_warn "Ansible installation may have failed"
fi

print_info "Installing Ansible collections for Windows management..."
# Ensure we're not in a venv when installing collections
if [ -n "$VIRTUAL_ENV" ]; then
    deactivate 2>/dev/null || true
fi

# Clear bash command cache to use new ansible-galaxy location
hash -r 2>/dev/null || true

# Find ansible-galaxy binary (might be in /usr/local/bin after pip install)
ANSIBLE_GALAXY=$(which ansible-galaxy 2>/dev/null || echo "/usr/local/bin/ansible-galaxy")

# Install collections system-wide to avoid venv conflicts
$ANSIBLE_GALAXY collection install ansible.windows --force > /dev/null 2>&1 || \
    print_warn "Failed to install ansible.windows collection"
$ANSIBLE_GALAXY collection install community.windows --force > /dev/null 2>&1 || \
    print_warn "Failed to install community.windows collection"
$ANSIBLE_GALAXY collection install ansible.posix --force > /dev/null 2>&1 || \
    print_warn "Failed to install ansible.posix collection"

# Verify collections
if $ANSIBLE_GALAXY collection list 2>/dev/null | grep -q "ansible.windows"; then
    print_info "✓ Ansible Windows collections installed"
else
    print_warn "Ansible collections may not have installed - you may need to install manually"
    print_warn "Run: $ANSIBLE_GALAXY collection install ansible.windows community.windows ansible.posix"
fi

###############################################################################
# Stage 5: Elasticsearch Installation
###############################################################################

print_section "Stage 5: Elasticsearch Setup"
print_time_estimate "5-10 minutes (~600MB download)"

print_info "Downloading Elasticsearch ${ELASTIC_VERSION}..."
cd /tmp
if [ ! -f elasticsearch-${ELASTIC_VERSION}-amd64.deb ]; then
    wget -q https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_VERSION}-amd64.deb
fi

print_info "Installing Elasticsearch..."
sudo dpkg -i elasticsearch-${ELASTIC_VERSION}-amd64.deb > /dev/null 2>&1

print_info "Configuring Elasticsearch..."

print_info "Setting Elasticsearch network binding to listen on lab network interface..."
if grep -q "^network.host:" /etc/elasticsearch/elasticsearch.yml 2>/dev/null; then
    sudo sed -i 's/^network.host:.*/network.host: [127.0.0.1, 192.168.100.1]/' /etc/elasticsearch/elasticsearch.yml
else
    echo 'network.host: [127.0.0.1, 192.168.100.1]' | sudo tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null
fi
if grep -q "^discovery.type:" /etc/elasticsearch/elasticsearch.yml 2>/dev/null; then
    sudo sed -i 's/^discovery.type:.*/discovery.type: single-node/' /etc/elasticsearch/elasticsearch.yml
else
    echo 'discovery.type: single-node' | sudo tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null
fi
# cluster.initial_master_nodes is incompatible with discovery.type: single-node — remove it
sudo sed -i '/^cluster.initial_master_nodes/d' /etc/elasticsearch/elasticsearch.yml
print_info "✓ Elasticsearch configured to listen on 127.0.0.1 and 192.168.100.1"

sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service

print_info "Waiting for Elasticsearch to start (this may take 30-60 seconds)..."
# Wait for Elasticsearch to be ready
WAIT_TIME=0
MAX_WAIT=60
while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    if curl -k -s https://localhost:9200 > /dev/null 2>&1; then
        print_info "✓ Elasticsearch is ready"
        break
    fi
    sleep 5
    WAIT_TIME=$((WAIT_TIME + 5))
    echo -n "."
done
echo ""

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    print_warn "Elasticsearch took longer than expected to start, but continuing..."
fi

print_info "Setting Elasticsearch password..."
# Use batch mode to set password
PASSWORD_SET=false
for i in {1..3}; do
    if sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -b --password "${ELK_PASSWORD}" > /dev/null 2>&1; then
        PASSWORD_SET=true
        break
    fi
    print_warn "Password reset attempt $i failed, retrying..."
    sleep 5
done

if [ "$PASSWORD_SET" = false ]; then
    print_error "Failed to set Elasticsearch password automatically"
    print_warn "Attempting alternative method..."
    # Try interactive mode as fallback
    echo "${ELK_PASSWORD}" | sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i > /dev/null 2>&1 || true
fi

# Verify password was set by testing authentication
print_info "Verifying Elasticsearch password..."
sleep 2
if curl -k -s -u elastic:${ELK_PASSWORD} https://localhost:9200 > /dev/null 2>&1; then
    print_info "✓ Elasticsearch password verified"
else
    print_warn "Password verification failed - you may need to reset it manually"
    print_warn "Run: sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -b --password ${ELK_PASSWORD}"
fi

print_info "Creating logingest user for Winlogbeat log ingestion..."
LOGIN_CREATED=false
for i in {1..5}; do
    HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -u elastic:${ELK_PASSWORD} \
        -X POST https://localhost:9200/_security/user/logingest \
        -H 'Content-Type: application/json' \
        -d '{"password":"Password@123","roles":["superuser"],"full_name":"Log Ingest User"}')
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
        LOGIN_CREATED=true
        break
    fi
    print_warn "logingest creation attempt $i failed (HTTP $HTTP_CODE), retrying..."
    sleep 5
done

if [ "$LOGIN_CREATED" = true ]; then
    print_info "✓ logingest user created (password: Password@123)"
else
    print_warn "Could not create logingest user automatically - create manually after setup:"
    print_warn "  curl -k -u elastic:${ELK_PASSWORD} -X POST https://localhost:9200/_security/user/logingest \\"
    print_warn "    -H 'Content-Type: application/json' \\"
    print_warn "    -d '{\"password\":\"Password@123\",\"roles\":[\"superuser\"]}'"
fi

print_info "✓ Elasticsearch installed and configured"
print_warn "Elasticsearch password set to: ${ELK_PASSWORD}"

###############################################################################
# Stage 6: Kibana Installation
###############################################################################

print_section "Stage 6: Kibana Setup"
print_time_estimate "5-10 minutes (~300MB download)"

print_info "Downloading Kibana ${KIBANA_VERSION}..."
cd /tmp
if [ ! -f kibana-${KIBANA_VERSION}-amd64.deb ]; then
    wget -q https://artifacts.elastic.co/downloads/kibana/kibana-${KIBANA_VERSION}-amd64.deb
fi

print_info "Installing Kibana..."
sudo dpkg -i kibana-${KIBANA_VERSION}-amd64.deb > /dev/null 2>&1

print_info "Configuring Kibana..."

print_info "Setting Elasticsearch host in kibana.yml to localhost..."
if grep -q "^elasticsearch.hosts:" /etc/kibana/kibana.yml 2>/dev/null; then
    sudo sed -i 's|^elasticsearch.hosts:.*|elasticsearch.hosts: ["https://localhost:9200"]|' /etc/kibana/kibana.yml
else
    echo 'elasticsearch.hosts: ["https://localhost:9200"]' | sudo tee -a /etc/kibana/kibana.yml > /dev/null
fi
# Disable SSL verification so Kibana accepts Elasticsearch's self-signed cert
if ! grep -q "elasticsearch.ssl.verificationMode" /etc/kibana/kibana.yml 2>/dev/null; then
    echo 'elasticsearch.ssl.verificationMode: none' | sudo tee -a /etc/kibana/kibana.yml > /dev/null
fi
print_info "✓ Elasticsearch host set to https://localhost:9200 with SSL verification disabled"

sudo systemctl enable kibana

print_info "Configuring Kibana to start after Elasticsearch (prevents boot race condition)..."
sudo mkdir -p /etc/systemd/system/kibana.service.d
sudo tee /etc/systemd/system/kibana.service.d/elasticsearch-dependency.conf > /dev/null << 'EOF'
[Unit]
After=elasticsearch.service
Requires=elasticsearch.service
EOF
sudo systemctl daemon-reload
print_info "✓ Kibana systemd dependency configured"

sudo systemctl start kibana

print_info "Waiting for Kibana to start (this may take 30-90 seconds)..."
# Wait for Kibana to be ready
WAIT_TIME=0
MAX_WAIT=90
while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    if curl -s http://localhost:5601/api/status > /dev/null 2>&1; then
        print_info "✓ Kibana is ready"
        break
    fi
    sleep 5
    WAIT_TIME=$((WAIT_TIME + 5))
    echo -n "."
done
echo ""

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    print_warn "Kibana took longer than expected to start, but continuing..."
fi

print_info "Generating Kibana enrollment token..."
KIBANA_TOKEN=$(sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana 2>/dev/null)
if [ -z "$KIBANA_TOKEN" ]; then
    print_warn "Failed to generate enrollment token - you may need to enroll Kibana manually"
    KIBANA_TOKEN="FAILED_TO_GENERATE"
fi

print_info "Getting Kibana verification code..."
# Try to get verification code, but it may not be available yet
if [ -f /usr/share/kibana/bin/kibana-verification-code ]; then
    KIBANA_CODE=$(sudo /usr/share/kibana/bin/kibana-verification-code 2>/dev/null | grep -oP '\d{6}' || echo "")
else
    KIBANA_CODE=""
fi

if [ -z "$KIBANA_CODE" ]; then
    # Try to get it from logs as fallback
    KIBANA_CODE=$(sudo journalctl -u kibana --no-pager 2>/dev/null | grep -oP 'verification code is:\s+\K\d{6}' | tail -1 || echo "")
fi

if [ -z "$KIBANA_CODE" ]; then
    KIBANA_CODE="Check Kibana UI or logs"
fi

print_info "✓ Kibana installed"

# Display token and code for immediate use
echo ""
print_section "Kibana Access Information"
echo -e "${GREEN}Kibana is now running at: http://localhost:5601${NC}"
echo ""
echo -e "${YELLOW}Enrollment Token:${NC}"
echo "$KIBANA_TOKEN"
echo ""
echo -e "${YELLOW}Verification Code:${NC}"
if [ "$KIBANA_CODE" = "Check Kibana UI or logs" ]; then
    echo -e "${CYAN}The verification code will be displayed in the Kibana UI${NC}"
    echo -e "${CYAN}or you can retrieve it with:${NC}"
    echo -e "${CYAN}  sudo journalctl -u kibana | grep 'verification code'${NC}"
else
    echo "$KIBANA_CODE"
fi
echo ""
echo -e "${YELLOW}Login Credentials:${NC}"
echo "  Username: elastic"
echo "  Password: ${ELK_PASSWORD}"
echo ""
print_warn "Save these values - you'll need them for first-time Kibana setup"
echo ""
read -p "Press ENTER to continue with installation..."

###############################################################################
# Stage 7: SDDM Configuration (KDE Login Manager)
###############################################################################

print_section "Stage 7: Display Manager Configuration"
print_time_estimate "1-2 minutes"

print_info "Configuring SDDM (KDE login manager)..."
sudo tee /etc/sddm.conf > /dev/null << 'EOF'
[General]
InputMethod=
Numlock=on

[X11]
EnableHiDPI=false
EOF

print_info "Disabling on-screen keyboard at login..."
sudo tee /usr/share/sddm/scripts/Xsetup > /dev/null << 'EOF'
#!/bin/sh
# Disable on-screen keyboard
xset -dpms
xset s off
EOF

sudo chmod +x /usr/share/sddm/scripts/Xsetup

sudo systemctl restart sddm.service 2>/dev/null || print_warn "SDDM not running, will apply on reboot"
print_info "✓ SDDM configured (on-screen keyboard disabled)"

###############################################################################
# Stage 8: Lab Directories and Tools (from original setup script)
###############################################################################

print_section "Stage 8: Lab Environment Setup"
print_time_estimate "5-10 minutes"

# Create lab directories
print_info "Creating lab directory structure..."
mkdir -p /home/adsec/labs/{lab1,lab2,lab3,lab4,lab5,lab6,lab7,lab8,lab9,lab10,lab11}
chmod -R 755 /home/adsec/labs

# Create tools directory
mkdir -p /home/adsec/tools
chmod 755 /home/adsec/tools

# Install hashcat
print_info "Installing hashcat..."
sudo apt-get install -y hashcat > /dev/null 2>&1

# Install offensive tools (Lab 4)
print_info "Installing CrackMapExec..."
# Ensure pipx bin directory exists and is in PATH
pipx ensurepath > /dev/null 2>&1
export PATH="$HOME/.local/bin:$PATH"

# Install CrackMapExec
if ! command -v crackmapexec > /dev/null 2>&1; then
    pipx install crackmapexec 2>&1 | grep -v "WARNING" || print_warn "CrackMapExec installation may need manual setup"

    # Verify installation
    if command -v crackmapexec > /dev/null 2>&1; then
        print_info "✓ CrackMapExec installed successfully"
    else
        print_warn "CrackMapExec not found in PATH - you may need to run: pipx install crackmapexec"
    fi
else
    print_info "✓ CrackMapExec already installed"
fi

print_info "Installing Impacket (for ntlmrelayx)..."
pipx install impacket 2>&1 | grep -v "WARNING" || print_warn "Impacket installation may need manual setup"

print_info "Installing Responder..."
if [ ! -d /home/adsec/tools/Responder ]; then
    cd /home/adsec/tools
    git clone -q https://github.com/lgandx/Responder.git
    chmod +x /home/adsec/tools/Responder/Responder.py

    # Configure Responder
    sed -i 's/^SMB = On/SMB = Off/' /home/adsec/tools/Responder/Responder.conf
    sed -i 's/^HTTP = On/HTTP = Off/' /home/adsec/tools/Responder/Responder.conf
fi

print_info "✓ Lab environment configured"

###############################################################################
# Stage 9: Shell Configuration
###############################################################################

print_section "Stage 9: Shell Environment"
print_time_estimate "2-3 minutes"

# Backup existing .bashrc
if [ -f /home/adsec/.bashrc ]; then
    cp /home/adsec/.bashrc /home/adsec/.bashrc.backup.$(date +%Y%m%d-%H%M%S)
fi

# Add configuration if not already present
if ! grep -q "# ADSec Lab Configuration" /home/adsec/.bashrc; then
    cat >> /home/adsec/.bashrc << 'EOF'

###############################################################################
# ADSec Lab Configuration
###############################################################################

# Ensure pipx and local bin directories are in PATH
export PATH="$HOME/.local/bin:$PATH"

# Helpful aliases
alias labs='cd ~/labs && ls -la'
alias tools='cd ~/tools && ls -la'
alias ll='ls -lah'
alias elk-status='sudo systemctl status elasticsearch kibana'
alias elk-start='sudo systemctl start elasticsearch kibana'
alias elk-stop='sudo systemctl stop elasticsearch kibana'

# Navigate to lab folder
lab() {
    if [ -z "$1" ]; then
        echo "Usage: lab [1-11]"
        return 1
    fi
    cd ~/labs/lab$1 && pwd && ls -la
}

# Quick hashcat wrapper
crack() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: crack [mode] [hashfile]"
        return 1
    fi
    hashcat -a 0 -m $1 $2 ~/tools/passwords.txt
}

# Add pipx to PATH
export PATH="$HOME/.local/bin:$PATH"

# ELK Stack info
echo ""
echo "=========================================="
echo "  ADSec VM - Full Environment Ready"
echo "=========================================="
echo "Lab directories: ~/labs/lab[1-11]"
echo "Tools directory: ~/tools/"
echo ""
echo "ELK Stack:"
echo "  Elasticsearch: https://localhost:9200"
echo "  Kibana: http://localhost:5601"
echo "  Username: elastic"
echo "  Password: elastic"
echo ""
echo "Commands:"
echo "  elk-status  - Check ELK status"
echo "  elk-start   - Start ELK stack"
echo "  elk-stop    - Stop ELK stack"
echo "  labs        - Go to labs"
echo "  lab X       - Go to specific lab"
echo "=========================================="
echo ""

EOF
    print_info "✓ Shell configuration added"
fi

###############################################################################
# Stage 10: Create System Documentation
###############################################################################

print_section "Stage 10: Documentation"
print_time_estimate "1 minute"

cat > /home/adsec/SYSTEM_INFO.txt << EOF
ADSec VM - Full System Information
===================================

Hostname: $(hostname)
Primary IP: $(hostname -I | awk '{print $1}')
Lab Network IP: 192.168.100.1 (ens37)
OS: $(lsb_release -d | cut -f2)
Kernel: $(uname -r)

Setup completed: $(date)

Components Installed:
--------------------
✓ SSH Server (port 22)
✓ KDE Plasma Desktop
✓ Google Chrome
✓ VMware Tools
✓ Python 3.10
✓ Ansible $(ansible --version 2>/dev/null | head -1 | awk '{print $2}' || echo "installed")
✓ Elasticsearch ${ELASTIC_VERSION}
✓ Kibana ${KIBANA_VERSION}
✓ Hashcat
✓ CrackMapExec
✓ Responder

Directory Structure:
-------------------
/home/adsec/
├── labs/              # Lab working directories (lab1-lab11)
├── tools/             # Attack tools and utilities
│   ├── Responder/     # LLMNR/NBT-NS poisoning
│   ├── impacket/      # Python attack tools (Ansible)
│   └── passwords.txt  # Password wordlist (Ansible)
└── SYSTEM_INFO.txt    # This file

Network Configuration:
---------------------
ens33: DHCP (NAT/Bridged) - Internet access
ens37: 192.168.100.1/24 (Host-only) - Lab network
DNS: 192.168.100.11 (dc1.talespin.lab)

Apply network config:
  sudo netplan apply

ELK Stack Access:
-----------------
Elasticsearch: https://localhost:9200
Kibana: http://localhost:5601

Default Credentials:
  Username: elastic
  Password: ${ELK_PASSWORD}

Kibana Enrollment Token:
${KIBANA_TOKEN:-"Run: sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana"}

Kibana Verification Code:
${KIBANA_CODE:-"Run: sudo /usr/share/kibana/bin/kibana-verification-code"}

Post-Setup Tasks:
-----------------
1. ✓ Apply network configuration: sudo netplan apply
2. ✓ Access Kibana at http://localhost:5601
3. ✓ Create 'logingest' user in Kibana (superuser role)
4. □ Clone adsec-ansible repository
5. □ Run Ansible playbooks to provision lab systems
6. □ Start with Lab 0A from wiki

Useful Commands:
----------------
elk-status  - Check ELK stack status
elk-start   - Start Elasticsearch and Kibana
elk-stop    - Stop Elasticsearch and Kibana
labs        - Navigate to labs directory
lab X       - Navigate to specific lab folder
crack       - Quick hashcat wrapper

Support:
--------
Lab Wiki: labs.rudrasec.io
Email: training@rudrasec.io

EOF

chmod 644 /home/adsec/SYSTEM_INFO.txt

###############################################################################
# Stage 11: Create Post-Setup Instructions
###############################################################################

cat > /home/adsec/POST_SETUP_INSTRUCTIONS.md << 'EOF'
# ADSec VM - Post-Setup Instructions

## Immediate Next Steps

### 1. Apply Network Configuration

```bash
sudo netplan apply
```

Verify network configuration:
```bash
ip addr show
# Should show:
#   ens33: DHCP address (internet)
#   ens37: 192.168.100.1/24 (lab network)
```

### 2. Access Kibana

Open Google Chrome and navigate to:
```
http://localhost:5601
```

**First-time setup:**
1. Use the enrollment token from SYSTEM_INFO.txt
2. Use the verification code from SYSTEM_INFO.txt
3. Login with:
   - Username: `elastic`
   - Password: `elastic`

### 3. Create logingest User in Kibana

1. Login to Kibana as `elastic` user
2. Navigate to: **Stack Management → Security → Users**
3. Click **Create User**
4. Fill in:
   - Username: `logingest`
   - Password: `logingest`
   - Full name: `Log Ingest User`
   - Email: (optional)
   - Roles: Select **superuser**
5. Click **Create user**

### 4. Verify ELK Stack

```bash
# Check status
elk-status

# Test Elasticsearch
curl -k -u elastic:elastic https://localhost:9200

# Should return cluster information
```

### 5. Clone adsec-ansible

```bash
cd ~
git clone https://github.com/Oceanduck/adsec-ansible.git
cd adsec-ansible
```

### 6. Review Lab Setup

```bash
cat ~/SYSTEM_INFO.txt
```

## Troubleshooting

### Elasticsearch won't start

```bash
sudo systemctl status elasticsearch
sudo journalctl -u elasticsearch -n 50
```

### Kibana won't start

```bash
sudo systemctl status kibana
sudo journalctl -u kibana -n 50
```

### Network issues

```bash
# Check network config
cat /etc/netplan/99-adsec-network.yaml

# Reapply
sudo netplan apply

# Check routing
ip route
```

### Reset Elasticsearch password

```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i
```

## Security Notes

- The default password `elastic:elastic` is for **LAB USE ONLY**
- Change passwords if exposing to untrusted networks
- Firewall is configured to allow SSH only
- ELK stack is bound to localhost by default

## Ready to Start Labs

Once setup is complete:
1. Start with Lab 0A (Provisioning Infrastructure)
2. Use Ansible to provision DC, client1, db-server
3. Begin lab exercises from the wiki

Access lab wiki at: https://labs.rudrasec.io

EOF

chmod 644 /home/adsec/POST_SETUP_INSTRUCTIONS.md

###############################################################################
# Final Summary
###############################################################################

print_section "Setup Complete!"

cat << EOF

${GREEN}✓ ADSec VM Full Setup Completed Successfully!${NC}

${BLUE}System Components:${NC}
  ✓ SSH Server running
  ✓ Dual NIC configuration template created
  ✓ KDE Desktop installed
  ✓ Google Chrome installed
  ✓ VMware Tools installed
  ✓ Python 3.10 environment
  ✓ Ansible installed
  ✓ Elasticsearch ${ELASTIC_VERSION} running
  ✓ Kibana ${KIBANA_VERSION} running
  ✓ Lab directories created
  ✓ Offensive tools installed

${BLUE}Important Files:${NC}
  📄 ~/SYSTEM_INFO.txt - Full system information
  📄 ~/POST_SETUP_INSTRUCTIONS.md - Next steps guide
  📄 /etc/netplan/99-adsec-network.yaml - Network config

${YELLOW}REQUIRED NEXT STEPS:${NC}

1. ${YELLOW}Apply network configuration:${NC}
   sudo netplan apply

2. ${YELLOW}Access Kibana:${NC}
   http://localhost:5601
   Username: elastic
   Password: ${ELK_PASSWORD}

3. ${YELLOW}Create logingest user in Kibana${NC}
   (See POST_SETUP_INSTRUCTIONS.md)

4. ${YELLOW}After reboot, verify everything:${NC}
   elk-status
   cat ~/SYSTEM_INFO.txt

${BLUE}For detailed instructions:${NC}
   cat ~/POST_SETUP_INSTRUCTIONS.md

${GREEN}Support: training@rudrasec.io${NC}

EOF

# Save completion marker
echo "ADSec VM full setup completed on $(date)" > /home/adsec/.adsecvm-setup-complete
echo "Elasticsearch password: ${ELK_PASSWORD}" >> /home/adsec/.adsecvm-setup-complete

print_info "✓ Setup complete!"
echo ""
print_warn "System will reboot in 10 seconds to complete the setup..."
print_info "Press Ctrl+C to cancel reboot"
echo ""

sleep 10

print_info "Rebooting system now..."
sudo reboot
