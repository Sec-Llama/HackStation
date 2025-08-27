# **HackStation Project**

**Developed by:** P1N3APPL3 @Sec-Llama

# HackStation 
## Universal Penetration Testing Arsenal Installer

```
██╗  ██╗ █████╗  ██████╗██╗  ██╗███████╗████████╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
██║  ██║██╔══██╗██╔════╝██║ ██╔╝██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
███████║███████║██║     █████╔╝ ███████╗   ██║   ███████║   ██║   ██║██║   ██║██╔██╗ ██║
██╔══██║██╔══██║██║     ██╔═██╗ ╚════██║   ██║   ██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
██║  ██║██║  ██║╚██████╗██║  ██╗███████║   ██║   ██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
```

**One script to rule them all. Zero dependency hell. Maximum reliability.**

---

## What's This About?

Tired of broken pentesting setups? Package conflicts? Tools that work on your buddy's box but not yours? 

HackStation is a bulletproof installer that gets you from vanilla Debian/Ubuntu to full-stack penetration testing environment with **100% reliability**. No more debugging installation scripts at 3 AM.

### The Problem
- Manual tool installation is time-consuming and error-prone
- Different tools require different installation methods (apt, pip, go, gems, git)
- Network failures break installations halfway through
- Version conflicts between dependencies
- Tools work on Kali but break on vanilla Ubuntu
- No easy way to verify all tools are actually working

### The Solution
**HackStation delivers:**
- **Multiple fallback methods** for every tool (2-4 installation paths each)
- **Robust retry mechanisms** with exponential backoff
- **100% verification** - every tool is tested after installation
- **Recovery mode** - automatically fixes failed installations
- **Universal compatibility** - works on Ubuntu/Debian/RPi (ARM/x86_64)
- **Zero maintenance** - handles all the boring stuff automatically

---

## Arsenal Included

### Reconnaissance & OSINT
- **amass** - Attack surface mapping
- **theHarvester** - Email/subdomain harvesting  
- **nmap** - Network discovery
- **masscan** - High-speed port scanner
- **whois/dnsutils** - Domain intelligence

### Web Application Testing  
- **ffuf** - Fast web fuzzer
- **dirsearch** - Directory bruteforcer
- **nikto** - Web vulnerability scanner
- **sqlmap** - SQL injection automation
- **whatweb** - Web application fingerprinting
- **wpscan** - WordPress security scanner

### Password Attacks
- **hydra** - Network login cracker
- **medusa** - Parallel bruteforcer  
- **john** - Password hash cracker
- **hashcat** - Advanced password recovery

### Network Analysis
- **tcpdump/tshark** - Packet capture/analysis
- **bettercap** - Network attacks & MitM
- **netcat/socat** - Network swiss army knife

### Advanced Exploitation
- **impacket** - Windows protocol attacks
- **netexec** - Network execution (CrackMapExec successor)
- **sublist3r** - Subdomain enumeration
- **httpx** - HTTP toolkit

### Intelligence Resources
- **SecLists** - Comprehensive wordlists
- **PayloadsAllTheThings** - Exploit payloads database

### Infrastructure
- **ngrok** - Secure tunneling for callbacks

---

## Installation

### Quick Start (Recommended)
```bash
# Clone and run
git clone https://github.com/yourusername/hackstation.git
cd hackstation
chmod +x hackstation.sh
sudo ./hackstation.sh --all
```

### Targeted Installation
```bash
# Install specific tool groups
sudo ./hackstation.sh --group Recon_OSINT
sudo ./hackstation.sh --group Web_Hacking

# Install individual tools
sudo ./hackstation.sh --tool amass
sudo ./hackstation.sh --tool bettercap

# Verify everything works
sudo ./hackstation.sh --check
```

### Recovery Mode
```bash
# Something broken? Fix it automatically
sudo ./hackstation.sh --recover
```

---

## Advanced Features

### Bulletproof Reliability
- **Retry Logic**: Each operation attempted 3x with exponential backoff
- **Multiple Methods**: Every tool has 2-4 different installation paths
- **Network Resilience**: Handles GitHub API limits, DNS failures, timeouts
- **Version Fallbacks**: If latest fails, tries stable versions
- **Architecture Support**: x86_64, ARM64, ARMv7 automatically detected

### Installation Methods Per Tool
- **Go tools**: `go install` → GitHub releases → apt fallback
- **Python tools**: `pipx` → `pip3` → manual git installation  
- **Ruby gems**: system gem → user gem → Docker wrapper
- **Binary releases**: Latest API → version fallbacks → architecture variants

### Comprehensive Logging
All operations logged to `/var/log/hackstation.log`:
```bash
# Monitor installation in real-time  
tail -f /var/log/hackstation.log

# Check what failed
grep "FAILED" /var/log/hackstation.log
```

### System Optimization
- PATH management across all shell sessions
- Environment persistence (survives reboots)
- Dependency resolution improvements
- Tool directories setup (`/opt/tools`, `/opt/wordlists`)

---

## Tool Groups

| Group | Tools | Purpose |
|-------|-------|---------|
| `Essentials` | tmux, htop, git, python3 | Basic utilities |
| `Recon_OSINT` | nmap, amass, theHarvester | Target reconnaissance |  
| `Web_Hacking` | ffuf, nikto, sqlmap, wpscan | Web app security |
| `Password_Cracking` | hydra, john, hashcat | Credential attacks |
| `Network_Analysis` | tcpdump, bettercap | Network security |
| `Utilities` | netcat, socat, jq | General purpose |
| `Wordlists_Tunnels` | SecLists, ngrok | Support resources |
| `Advanced` | impacket, netexec, httpx | Advanced techniques |

---

## Usage Examples

### Full Environment Setup
```bash
# Complete penetration testing environment
sudo ./hackstation.sh --all
# Installs everything + system optimization + verification
```

### Targeted Workflows  
```bash
# Web application testing setup
sudo ./hackstation.sh --group Web_Hacking
sudo ./hackstation.sh --group Wordlists_Tunnels

# Network penetration testing
sudo ./hackstation.sh --group Network_Analysis  
sudo ./hackstation.sh --group Password_Cracking

# Reconnaissance phase
sudo ./hackstation.sh --group Recon_OSINT
```

### Verification & Troubleshooting
```bash
# Check installation status
sudo ./hackstation.sh --check

# Fix any failures  
sudo ./hackstation.sh --recover

# System optimization
sudo ./hackstation.sh --optimize
```

---

## Requirements

### Supported Systems
- **Ubuntu** 18.04+ (LTS recommended)
- **Debian** 10+ (Buster+)  
- **Raspberry Pi OS** (ARM support)
- **Architecture**: x86_64, ARM64, ARMv7

### Prerequisites
- Root access (sudo)
- Internet connection
- 2GB+ free disk space
- Basic build tools (installed automatically)

### Resource Usage
- **Disk Space**: ~1.5GB (tools + wordlists)
- **RAM**: 1GB+ recommended during installation
- **Time**: 15-30 minutes (depending on network speed)

---

## Technical Details

### Installation Strategy
1. **Network verification** - Ensures connectivity before starting
2. **System preparation** - Updates packages, installs dependencies
3. **Tool installation** - Each tool attempted via multiple methods
4. **Verification phase** - Every tool tested for functionality  
5. **Recovery attempts** - Failed tools re-attempted with alternatives
6. **System optimization** - PATH fixes, environment setup
7. **Final verification** - Success rate calculation and reporting

### Error Handling
```bash
retry() {
  local max_attempts=3
  local delay=5
  local attempt=1
  
  while [ $attempt -le $max_attempts ]; do
    if eval "$cmd"; then return 0; fi
    sleep $delay
    ((attempt++))
    delay=$((delay * 2))  # Exponential backoff
  done
  return 1
}
```

### Verification System  
Each tool has comprehensive checks:
```bash
CHECK[amass]="command -v amass && amass -version"
CHECK[bettercap]="command -v bettercap && bettercap -version"  
CHECK[impacket]="python3 -c 'import impacket; print(impacket.__version__)'"
```

---

## Contributing

### Adding New Tools
1. Add installation function: `install_newtool()`
2. Add verification check: `CHECK[newtool]="..."`
3. Add to appropriate group: `GROUP_Something+=(newtool)`
4. Test on clean system

### Improving Reliability
- Add more installation methods for existing tools
- Improve error detection and recovery
- Add support for new architectures/distributions
- Optimize installation order and dependencies

### Reporting Issues
Include in bug reports:
- Operating system and version
- Architecture (x86_64, ARM64, etc.)
- Full log file: `/var/log/hackstation.log`
- Command that failed
- Network environment (proxy, firewall, etc.)

---

## Security Notice

**This tool installs penetration testing software. Use responsibly and legally.**

- Only use on systems you own or have explicit permission to test
- Check local laws regarding security testing tools
- Some tools may trigger antivirus/EDR solutions
- Intended for security professionals, researchers, and authorized testing

**The authors are not responsible for any misuse of this software.**

---

## License

MIT License - Use it, modify it, share it.

See [LICENSE](LICENSE) for full details.

---

## Acknowledgments

Built on the shoulders of giants. Thanks to all the tool developers who make security research possible:

- OWASP Amass Team
- ProjectDiscovery  
- SecLists contributors
- Impacket developers
- bettercap team
- And countless others in the infosec community

---

**Happy Hacking! Stay Legal.**

Made with ⚡ by security professionals, for security professionals.
