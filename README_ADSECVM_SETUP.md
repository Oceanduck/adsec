# ADSec VM Configuration Script

## TODO: Create adsecvm setup script

**Purpose:** Automate the configuration of the adsecvm (Ubuntu) system for student lab work.

**Script Location:** `adsec-labs/scripts/setup-adsecvm.sh`

## Requirements

### Directory Structure

Create the following directory structure on adsecvm:

```
/home/adsec/
├── labs/           # Working directory for students to copy lab outputs
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
│   └── lab11/
├── tools/          # Attack tools and utilities (already exists)
│   ├── impacket/
│   ├── hashcat
│   └── passwords.txt
└── .bashrc         # Shell configuration
```

### Script Functionality

The setup script should:

1. **Create directory structure**
   - Create `/home/adsec/labs/` with subdirectories for lab1-lab11
   - Set proper permissions (755 for directories)
   - Set ownership to adsec:adsec

2. **Install required packages** (if not already handled by Ansible)
   - hashcat
   - wireshark/tshark
   - python3 tools
   - scp/openssh-client
   - **Offensive tools (for Lab 4 - NTLM Relay):**
     - CrackMapExec (CME) - SMB signing scanner
     - Responder - LLMNR/NBT-NS poisoning
     - Impacket suite (ntlmrelayx) - Already in tools/impacket/

3. **Configure shell environment**
   - Add helpful aliases to .bashrc
   - Set PATH variables
   - Add welcome message with lab directory info

4. **Download/verify tools**
   - Verify hashcat installation
   - Download password lists if needed
   - Check impacket installation

5. **Create README in labs directory**
   - Explain purpose of each lab folder
   - Provide quick reference commands

## Example Script Structure

```bash
#!/bin/bash
# setup-adsecvm.sh
# ADSec VM Configuration Script

# Create lab directories
mkdir -p /home/adsec/labs/{lab1,lab2,lab3,lab4,lab5,lab6,lab7,lab8,lab9,lab10,lab11}
chown -R adsec:adsec /home/adsec/labs
chmod -R 755 /home/adsec/labs

# Create README
cat > /home/adsec/labs/README.md << 'EOF'
# ADSec Lab Working Directories

Each lab folder is for storing outputs, hashes, and files from the corresponding lab exercise.

## Quick Commands

- Copy files from Windows: `scp user@client1:/path/to/file ./labX/`
- Run hashcat: `hashcat -m [mode] hashfile wordlist`
- Check tools: `ls ~/tools/`

EOF

# Add helpful aliases
cat >> /home/adsec/.bashrc << 'EOF'

# ADSec Lab Aliases
alias labs='cd ~/labs'
alias tools='cd ~/tools'
alias ll='ls -lah'

EOF

echo "ADSec VM setup complete!"
echo "Lab directories created in /home/adsec/labs/"
```

## Integration with Ansible

**Option 1:** Add this script to adsec-ansible playbooks
- Create new role: `roles/adsecvm-student-setup/`
- Add task to create lab directories

**Option 2:** Standalone script in adsec-labs repository
- Students run manually after Ansible provisioning
- Simpler, more flexible

## Status

- [x] Create setup script → `scripts/setup-adsecvm.sh`
- [x] Create script documentation → `scripts/README.md`
- [ ] Test on clean adsecvm
- [ ] Document in Lab 0A/0B
- [ ] Add to adsec-labs repository (GitHub)
- [ ] Update lab wiki references

## Implementation Details

**Decision:** Standalone script (not Ansible role)

**Rationale:**
- adsecvm is the control machine that runs Ansible
- Must be set up BEFORE running Ansible playbooks
- Standalone script is simpler and more flexible
- Students run once during Lab 0A setup

**Script Location:** `adsec-labs/scripts/setup-adsecvm.sh`

**Features Implemented:**
- Lab directory structure creation
- Package installation (hashcat, python3, ssh tools)
- Shell customization (aliases, functions, welcome message)
- Documentation (README, SYSTEM_INFO)
- Verification and error checking

## Lab 4 Requirements - Replacing Kali with adsecvm

**Note:** Lab 4 (NTLM Relay & Responder) currently uses Kali Linux. To eliminate the need for Kali, the following tools must be installed on adsecvm:

### Tools Required for Lab 4:

1. **CrackMapExec**
   - Purpose: Scan network for SMB signing vulnerabilities
   - Command: `crackmapexec smb 192.168.100.0/24 --gen-relay-list relay-targets.txt`
   - Install: `pip3 install crackmapexec` or `pipx install crackmapexec`

2. **Responder**
   - Purpose: LLMNR/NBT-NS/MDNS poisoning
   - Command: `responder -I eth0 -v`
   - Install: `git clone https://github.com/lgandx/Responder.git` or `apt install responder`
   - Config: Needs Responder.conf with SMB=Off and HTTP=Off

3. **Impacket (ntlmrelayx)**
   - Purpose: Relay NTLM authentication
   - Command: `impacket-ntlmrelayx -t 192.168.100.31 -smb2support`
   - Note: Already handled in tools/impacket/ directory

### Implementation Options:

**Option 1:** Add to setup-adsecvm.sh
- Install CrackMapExec and Responder during initial setup
- Pre-configure Responder.conf

**Option 2:** Separate "offensive tools" script
- Create `setup-offensive-tools.sh` for Lab 4 prerequisites
- Students run before Lab 4
- Keeps base setup minimal

**Recommendation:** Option 1 - Install all tools upfront so adsecvm is ready for all labs without needing Kali.

### TODO:
- [ ] Add CrackMapExec installation to setup script
- [ ] Add Responder installation to setup script
- [ ] Pre-configure Responder.conf (SMB/HTTP off)
- [ ] Update Lab 4 wiki to reference adsecvm instead of Kali
- [ ] Test Lab 4 completely on adsecvm

---

**Created:** 2026-02-28
**Updated:** 2026-02-28
**Status:** ✅ Script created, pending testing | ⚠️ Lab 4 tools pending

