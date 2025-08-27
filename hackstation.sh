#!/usr/bin/env bash
# HackStation - Universal Penetration Testing Tool Installer
# Robust error handling, multiple fallbacks, comprehensive logging
# v1.0 (2025-08-27)
set -euo pipefail

if (( EUID != 0 )); then
  echo "[!] Run as root (sudo)."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# ---------- Enhanced Helpers ----------
log()     { printf "\n[+] %s\n" "$*" | tee -a /var/log/hackstation.log; }
warn()    { printf "\n[!] %s\n" "$*" | tee -a /var/log/hackstation.log; }
error()   { printf "\n[✘] %s\n" "$*" | tee -a /var/log/hackstation.log; }
success() { printf "\n[✔] %s\n" "$*" | tee -a /var/log/hackstation.log; }

# Enhanced retry mechanism
retry() {
  local max_attempts=3
  local delay=5
  local attempt=1
  local cmd="$*"
  
  while [ $attempt -le $max_attempts ]; do
    log "Attempt $attempt/$max_attempts: $cmd"
    if eval "$cmd"; then
      return 0
    fi
    warn "Attempt $attempt failed. Retrying in ${delay}s..."
    sleep $delay
    ((attempt++))
    delay=$((delay * 2))  # Exponential backoff
  done
  
  error "All $max_attempts attempts failed for: $cmd"
  return 1
}

# Network connectivity check
check_network() {
  if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    error "No internet connectivity. Please check network connection."
    exit 1
  fi
}

# Create log file
mkdir -p /var/log
touch /var/log/hackstation.log
log "Starting HackStation setup - $(date)"

ARCH="$(uname -m)"
OS="$(. /etc/os-release; echo "${ID:-debian}")"

APT_BASE=(
  ca-certificates apt-transport-https gnupg lsb-release
  build-essential pkg-config
  curl wget git unzip tar jq
  python3 python3-pip python3-venv python3-dev python3-setuptools
  pipx
  nmap masscan whois dnsutils
  ffuf dirsearch nikto sqlmap whatweb
  hydra medusa john hashcat
  tcpdump tshark netcat-traditional socat
  jq xxd coreutils sed gawk
  openssh-server tmux screen htop p7zip-full
  # Additional dependencies often missed
  libssl-dev libffi-dev zlib1g-dev
  software-properties-common
)

# Enhanced tool checks with multiple verification methods
declare -A CHECK=()
declare -A INSTALL_STATUS=()

CHECK[amass]="command -v amass && amass -version"
CHECK[theharvester]="command -v theHarvester && theHarvester -h"
CHECK[wpscan]="command -v wpscan && wpscan --version"
CHECK[bettercap]="command -v bettercap && bettercap -version"
CHECK[impacket]="python3 -c 'import impacket; print(f\"Impacket {impacket.__version__}\")'"
CHECK[netexec]="(command -v nxc && nxc --version) || (command -v crackmapexec && crackmapexec --version)"
CHECK[sublist3r]="command -v sublist3r && python3 -c 'import sublist3r'"
CHECK[httpx]="command -v httpx && httpx -version"
CHECK[seclists]="test -d /opt/SecLists && test -f /opt/SecLists/Discovery/Web-Content/common.txt"
CHECK[payloadsallthethings]="test -d /opt/PayloadsAllTheThings && test -f /opt/PayloadsAllTheThings/README.md"
CHECK[ngrok]="command -v ngrok && ngrok version"

# ---------- Robust System Prep ----------
apt_update_once() {
  log "Updating package lists..."
  retry "apt-get update -y"
  retry "apt-get upgrade -y"
}

install_apt_pkgs() {
  log "Installing base apt packages (${#APT_BASE[@]} items)..."
  apt_update_once
  
  # Install packages individually to catch failures
  local failed_packages=()
  for pkg in "${APT_BASE[@]}"; do
    if retry "apt-get install -y $pkg"; then
      success "Installed: $pkg"
    else
      error "Failed to install: $pkg"
      failed_packages+=("$pkg")
    fi
  done
  
  # Retry failed packages with different methods
  if [ ${#failed_packages[@]} -gt 0 ]; then
    warn "Retrying failed packages with apt-get -f install..."
    retry "apt-get -f install -y"
    for pkg in "${failed_packages[@]}"; do
      retry "apt-get install -y --fix-broken $pkg" || warn "Still failed: $pkg"
    done
  fi
  
  # Setup pipx properly
  retry "python3 -m pipx ensurepath --global" || true
  export PATH="$PATH:/root/.local/bin:/usr/local/go/bin"
  
  # Ensure PATH is persistent
  echo 'export PATH="$PATH:/root/.local/bin:/usr/local/go/bin"' >> /root/.bashrc
  echo 'export PATH="$PATH:/root/.local/bin:/usr/local/go/bin"' >> /etc/profile
}

# ---------- Robust Go Installation ----------
ensure_go() {
  if command -v go >/dev/null 2>&1; then
    local go_version=$(go version | awk '{print $3}' | sed 's/go//')
    log "Go already installed: $go_version"
    return 0
  fi
  
  log "Installing Go via multiple methods..."
  
  # Method 1: Try apt first
  if retry "apt-get install -y golang-go"; then
    if command -v go >/dev/null 2>&1; then
      success "Go installed via apt"
      return 0
    fi
  fi
  
  # Method 2: Official Go tarball with multiple versions
  local go_versions=("1.21.7" "1.21.6" "1.20.14")
  for GO_VER in "${go_versions[@]}"; do
    log "Trying Go version $GO_VER..."
    
    local TOS="linux"
    local TARCH=""
    case "$ARCH" in
      x86_64) TARCH="amd64" ;;
      aarch64|arm64) TARCH="arm64" ;;
      armv7l|armhf) TARCH="armv6l" ;;
      *) TARCH="amd64" ;;
    esac
    
    cd /tmp
    local go_url="https://go.dev/dl/go${GO_VER}.${TOS}-${TARCH}.tar.gz"
    
    if retry "curl -fsSLO '$go_url'"; then
      if retry "rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VER}.${TOS}-${TARCH}.tar.gz"; then
        echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go-path.sh
        chmod +x /etc/profile.d/go-path.sh
        export PATH="$PATH:/usr/local/go/bin"
        
        if command -v go >/dev/null 2>&1; then
          success "Go $GO_VER installed successfully"
          return 0
        fi
      fi
    fi
  done
  
  error "Failed to install Go with all methods"
  return 1
}

export GOPATH=${GOPATH:-/root/go}
mkdir -p "$GOPATH/bin"

# ---------- Enhanced Tool Installers ----------
install_amass() {
  if bash -c "${CHECK[amass]}" >/dev/null 2>&1; then
    success "Amass already installed"
    return 0
  fi
  
  log "Installing Amass with multiple methods..."
  
  # Method 1: Go install
  if ensure_go; then
    if retry "GOBIN='$GOPATH/bin' go install github.com/owasp-amass/amass/v4/...@latest"; then
      if [ -f "$GOPATH/bin/amass" ]; then
        retry "install -m 0755 '$GOPATH/bin/amass' /usr/local/bin/amass"
        if bash -c "${CHECK[amass]}" >/dev/null 2>&1; then
          success "Amass installed via Go"
          return 0
        fi
      fi
    fi
  fi
  
  # Method 2: Try different Go module paths
  local amass_repos=(
    "github.com/owasp-amass/amass/v4/..."
    "github.com/OWASP/Amass/v4/..."
    "github.com/owasp-amass/amass/v3/..."
  )
  
  for repo in "${amass_repos[@]}"; do
    if retry "GOBIN='$GOPATH/bin' go install ${repo}@latest"; then
      if [ -f "$GOPATH/bin/amass" ]; then
        retry "install -m 0755 '$GOPATH/bin/amass' /usr/local/bin/amass"
        if bash -c "${CHECK[amass]}" >/dev/null 2>&1; then
          success "Amass installed from $repo"
          return 0
        fi
      fi
    fi
  done
  
  # Method 3: GitHub releases
  log "Trying Amass GitHub releases..."
  cd /tmp
  local api_urls=(
    "https://api.github.com/repos/owasp-amass/amass/releases/latest"
    "https://api.github.com/repos/OWASP/Amass/releases/latest"
  )
  
  for api_url in "${api_urls[@]}"; do
    if local tag=$(retry "curl -fsSL '$api_url' | jq -r .tag_name"); then
      if [ -n "$tag" ] && [ "$tag" != "null" ]; then
        local download_url="https://github.com/owasp-amass/amass/releases/download/${tag}/amass_linux_amd64.zip"
        if retry "curl -fsSLO '$download_url'"; then
          if retry "unzip -qo amass_linux_amd64.zip"; then
            if [ -f "amass_linux_amd64/amass" ]; then
              retry "install -m 0755 amass_linux_amd64/amass /usr/local/bin/amass"
              if bash -c "${CHECK[amass]}" >/dev/null 2>&1; then
                success "Amass installed from GitHub releases"
                return 0
              fi
            fi
          fi
        fi
      fi
    fi
  done
  
  error "Failed to install Amass with all methods"
  INSTALL_STATUS[amass]="FAILED"
  return 1
}

install_theharvester() {
  if bash -c "${CHECK[theharvester]}" >/dev/null 2>&1; then
    success "theHarvester already installed"
    return 0
  fi
  
  log "Installing theHarvester with multiple methods..."
  
  # Method 1: pipx
  if retry "pipx install theHarvester"; then
    # Create symlink for consistency
    local harvester_path=$(pipx list --include-deps 2>/dev/null | grep -o '/[^[:space:]]*bin/theHarvester' | head -1)
    if [ -n "$harvester_path" ] && [ -f "$harvester_path" ]; then
      retry "ln -sf '$harvester_path' /usr/local/bin/theHarvester" || true
    fi
    
    if bash -c "${CHECK[theharvester]}" >/dev/null 2>&1; then
      success "theHarvester installed via pipx"
      return 0
    fi
  fi
  
  # Method 2: pip3 install
  if retry "pip3 install theHarvester"; then
    if bash -c "${CHECK[theharvester]}" >/dev/null 2>&1; then
      success "theHarvester installed via pip3"
      return 0
    fi
  fi
  
  # Method 3: Git clone and manual install
  log "Trying manual theHarvester installation..."
  cd /opt
  if retry "git clone https://github.com/laramies/theHarvester.git"; then
    cd theHarvester
    if retry "python3 -m pip install -r requirements.txt"; then
      if retry "python3 setup.py install"; then
        retry "ln -sf /opt/theHarvester/theHarvester.py /usr/local/bin/theHarvester"
        if bash -c "${CHECK[theharvester]}" >/dev/null 2>&1; then
          success "theHarvester installed manually"
          return 0
        fi
      fi
    fi
  fi
  
  error "Failed to install theHarvester with all methods"
  INSTALL_STATUS[theharvester]="FAILED"
  return 1
}

install_wpscan() {
  if bash -c "${CHECK[wpscan]}" >/dev/null 2>&1; then
    success "WPScan already installed"
    return 0
  fi
  
  log "Installing WPScan with enhanced Ruby setup..."
  
  # Ensure Ruby is properly installed
  retry "apt-get install -y ruby-full build-essential libcurl4-openssl-dev zlib1g-dev libxml2-dev libxslt1-dev"
  
  # Method 1: System gem install
  if retry "gem install wpscan"; then
    if bash -c "${CHECK[wpscan]}" >/dev/null 2>&1; then
      success "WPScan installed via gem"
      return 0
    fi
  fi
  
  # Method 2: User gem install
  if retry "gem install --user-install wpscan"; then
    # Add user gem path to PATH
    local gem_path=$(ruby -e 'puts Gem.user_dir')/bin
    export PATH="$PATH:$gem_path"
    echo "export PATH=\"\$PATH:$gem_path\"" >> /root/.bashrc
    
    if bash -c "${CHECK[wpscan]}" >/dev/null 2>&1; then
      success "WPScan installed via user gem"
      return 0
    fi
  fi
  
  # Method 3: Docker alternative (create wrapper script)
  if command -v docker >/dev/null 2>&1; then
    log "Creating WPScan Docker wrapper..."
    cat > /usr/local/bin/wpscan << 'DOCKER_WRAPPER'
#!/bin/bash
docker run --rm -it wpscanteam/wpscan "$@"
DOCKER_WRAPPER
    chmod +x /usr/local/bin/wpscan
    
    # Pull the Docker image
    if retry "docker pull wpscanteam/wpscan"; then
      success "WPScan installed via Docker wrapper"
      return 0
    fi
  fi
  
  error "Failed to install WPScan with all methods"
  INSTALL_STATUS[wpscan]="FAILED"
  return 1
}

install_bettercap() {
  if bash -c "${CHECK[bettercap]}" >/dev/null 2>&1; then
    success "Bettercap already installed"
    return 0
  fi
  
  log "Installing Bettercap from GitHub releases with fallbacks..."
  
  cd /tmp
  
  # Multiple API endpoints and versions
  local api_endpoints=(
    "https://api.github.com/repos/bettercap/bettercap/releases/latest"
  )
  local fallback_versions=("v2.32.4" "v2.32.0" "v2.31.1")
  
  # Try latest from API
  for api_url in "${api_endpoints[@]}"; do
    local tag=""
    if tag=$(retry "curl -fsSL '$api_url' | jq -r .tag_name 2>/dev/null"); then
      if [ -n "$tag" ] && [ "$tag" != "null" ]; then
        if try_bettercap_version "$tag"; then
          return 0
        fi
      fi
    fi
  done
  
  # Try fallback versions
  for version in "${fallback_versions[@]}"; do
    if try_bettercap_version "$version"; then
      return 0
    fi
  done
  
  error "Failed to install Bettercap with all methods"
  INSTALL_STATUS[bettercap]="FAILED"
  return 1
}

try_bettercap_version() {
  local tag="$1"
  local version="${tag#v}"
  
  log "Trying Bettercap version $tag..."
  
  # Try different architecture combinations
  local arch_combinations=()
  case "$ARCH" in
    x86_64)
      arch_combinations=("bettercap_linux_amd64_${version}.zip" "bettercap_linux_x86_64_${version}.zip")
      ;;
    aarch64|arm64)
      arch_combinations=("bettercap_linux_arm64_${version}.zip" "bettercap_linux_aarch64_${version}.zip")
      ;;
    armv7l|armhf)
      arch_combinations=("bettercap_linux_armv7_${version}.zip" "bettercap_linux_arm_${version}.zip")
      ;;
    *)
      arch_combinations=("bettercap_linux_amd64_${version}.zip")
      ;;
  esac
  
  for pkg in "${arch_combinations[@]}"; do
    local url="https://github.com/bettercap/bettercap/releases/download/${tag}/${pkg}"
    if retry "curl -fsSLO '$url'"; then
      if retry "unzip -qo '$pkg'"; then
        if [ -f "bettercap" ]; then
          retry "install -m 0755 bettercap /usr/local/bin/bettercap"
          if bash -c "${CHECK[bettercap]}" >/dev/null 2>&1; then
            success "Bettercap $tag installed successfully"
            return 0
          fi
        fi
      fi
    fi
  done
  
  return 1
}

install_impacket() {
  if bash -c "${CHECK[impacket]}" >/dev/null 2>&1; then
    success "Impacket already installed"
    return 0
  fi
  
  log "Installing Impacket with multiple methods..."
  
  # Method 1: pipx
  if retry "pipx install impacket"; then
    if bash -c "${CHECK[impacket]}" >/dev/null 2>&1; then
      success "Impacket installed via pipx"
      return 0
    fi
  fi
  
  # Method 2: pip3
  if retry "pip3 install impacket"; then
    if bash -c "${CHECK[impacket]}" >/dev/null 2>&1; then
      success "Impacket installed via pip3"
      return 0
    fi
  fi
  
  # Method 3: Git clone
  cd /opt
  if retry "git clone https://github.com/fortra/impacket.git"; then
    cd impacket
    if retry "python3 -m pip install ."; then
      if bash -c "${CHECK[impacket]}" >/dev/null 2>&1; then
        success "Impacket installed from source"
        return 0
      fi
    fi
  fi
  
  error "Failed to install Impacket with all methods"
  INSTALL_STATUS[impacket]="FAILED"
  return 1
}

install_netexec() {
  if bash -c "${CHECK[netexec]}" >/dev/null 2>&1; then
    success "NetExec already installed"
    return 0
  fi
  
  log "Installing NetExec with multiple methods..."
  
  # Method 1: pipx from git
  if retry "pipx install git+https://github.com/Pennyw0rth/NetExec.git"; then
    if bash -c "${CHECK[netexec]}" >/dev/null 2>&1; then
      success "NetExec installed via pipx (git)"
      return 0
    fi
  fi
  
  # Method 2: Try alternative repo
  if retry "pipx install git+https://github.com/byt3bl33d3r/CrackMapExec.git"; then
    if bash -c "${CHECK[netexec]}" >/dev/null 2>&1; then
      success "CrackMapExec installed as fallback"
      return 0
    fi
  fi
  
  # Method 3: pip3 install
  if retry "pip3 install netexec"; then
    if bash -c "${CHECK[netexec]}" >/dev/null 2>&1; then
      success "NetExec installed via pip3"
      return 0
    fi
  fi
  
  # Method 4: Manual git clone
  cd /opt
  if retry "git clone https://github.com/Pennyw0rth/NetExec.git"; then
    cd NetExec
    if retry "python3 -m pip install ."; then
      if bash -c "${CHECK[netexec]}" >/dev/null 2>&1; then
        success "NetExec installed from source"
        return 0
      fi
    fi
  fi
  
  error "Failed to install NetExec with all methods"
  INSTALL_STATUS[netexec]="FAILED"
  return 1
}

install_sublist3r() {
  if bash -c "${CHECK[sublist3r]}" >/dev/null 2>&1; then
    success "Sublist3r already installed"
    return 0
  fi
  
  log "Installing Sublist3r with multiple methods..."
  
  # Method 1: pipx
  if retry "pipx install sublist3r"; then
    if bash -c "${CHECK[sublist3r]}" >/dev/null 2>&1; then
      success "Sublist3r installed via pipx"
      return 0
    fi
  fi
  
  # Method 2: pip3
  if retry "pip3 install sublist3r"; then
    if bash -c "${CHECK[sublist3r]}" >/dev/null 2>&1; then
      success "Sublist3r installed via pip3"
      return 0
    fi
  fi
  
  # Method 3: Git clone
  cd /opt
  if retry "git clone https://github.com/aboul3la/Sublist3r.git"; then
    cd Sublist3r
    if retry "python3 -m pip install -r requirements.txt"; then
      retry "ln -sf /opt/Sublist3r/sublist3r.py /usr/local/bin/sublist3r"
      chmod +x /usr/local/bin/sublist3r
      if bash -c "${CHECK[sublist3r]}" >/dev/null 2>&1; then
        success "Sublist3r installed from source"
        return 0
      fi
    fi
  fi
  
  error "Failed to install Sublist3r with all methods"
  INSTALL_STATUS[sublist3r]="FAILED"
  return 1
}

install_httpx() {
  if bash -c "${CHECK[httpx]}" >/dev/null 2>&1; then
    success "httpx already installed"
    return 0
  fi
  
  log "Installing httpx with multiple methods..."
  
  # Method 1: Go install
  if ensure_go; then
    local httpx_repos=(
      "github.com/projectdiscovery/httpx/cmd/httpx@latest"
      "github.com/projectdiscovery/httpx/cmd/httpx@v1.3.7"
    )
    
    for repo in "${httpx_repos[@]}"; do
      if retry "GOBIN='$GOPATH/bin' go install $repo"; then
        if [ -f "$GOPATH/bin/httpx" ]; then
          retry "install -m 0755 '$GOPATH/bin/httpx' /usr/local/bin/httpx"
          if bash -c "${CHECK[httpx]}" >/dev/null 2>&1; then
            success "httpx installed via Go"
            return 0
          fi
        fi
      fi
    done
  fi
  
  # Method 2: GitHub releases
  cd /tmp
  local api_url="https://api.github.com/repos/projectdiscovery/httpx/releases/latest"
  if local tag=$(retry "curl -fsSL '$api_url' | jq -r .tag_name 2>/dev/null"); then
    if [ -n "$tag" ] && [ "$tag" != "null" ]; then
      local version="${tag#v}"
      local pkg="httpx_${version}_linux_amd64.zip"
      local url="https://github.com/projectdiscovery/httpx/releases/download/${tag}/${pkg}"
      
      if retry "curl -fsSLO '$url'"; then
        if retry "unzip -qo '$pkg'"; then
          if [ -f "httpx" ]; then
            retry "install -m 0755 httpx /usr/local/bin/httpx"
            if bash -c "${CHECK[httpx]}" >/dev/null 2>&1; then
              success "httpx installed from GitHub releases"
              return 0
            fi
          fi
        fi
      fi
    fi
  fi
  
  error "Failed to install httpx with all methods"
  INSTALL_STATUS[httpx]="FAILED"
  return 1
}

install_seclists() {
  if bash -c "${CHECK[seclists]}" >/dev/null 2>&1; then
    success "SecLists already installed"
    return 0
  fi
  
  log "Installing SecLists with multiple methods..."
  
  # Method 1: Git clone (shallow)
  if retry "git clone --depth 1 https://github.com/danielmiessler/SecLists.git /opt/SecLists"; then
    if bash -c "${CHECK[seclists]}" >/dev/null 2>&1; then
      success "SecLists cloned successfully"
      return 0
    fi
  fi
  
  # Method 2: Download zip
  cd /tmp
  if retry "curl -fsSL https://github.com/danielmiessler/SecLists/archive/master.zip -o seclists.zip"; then
    if retry "unzip -qo seclists.zip"; then
      if retry "mv SecLists-master /opt/SecLists"; then
        if bash -c "${CHECK[seclists]}" >/dev/null 2>&1; then
          success "SecLists installed from zip"
          return 0
        fi
      fi
    fi
  fi
  
  # Method 3: Alternative mirror
  if retry "git clone --depth 1 https://gitlab.com/kalilinux/packages/seclists.git /tmp/seclists-mirror"; then
    if [ -d "/tmp/seclists-mirror/data" ]; then
      if retry "mv /tmp/seclists-mirror/data /opt/SecLists"; then
        if bash -c "${CHECK[seclists]}" >/dev/null 2>&1; then
          success "SecLists installed from mirror"
          return 0
        fi
      fi
    fi
  fi
  
  error "Failed to install SecLists with all methods"
  INSTALL_STATUS[seclists]="FAILED"
  return 1
}

install_payloads_all_the_things() {
  if bash -c "${CHECK[payloadsallthethings]}" >/dev/null 2>&1; then
    success "PayloadsAllTheThings already installed"
    return 0
  fi
  
  log "Installing PayloadsAllTheThings with multiple methods..."
  
  # Method 1: Git clone (shallow)
  if retry "git clone --depth 1 https://github.com/swisskyrepo/PayloadsAllTheThings.git /opt/PayloadsAllTheThings"; then
    if bash -c "${CHECK[payloadsallthethings]}" >/dev/null 2>&1; then
      success "PayloadsAllTheThings cloned successfully"
      return 0
    fi
  fi
  
  # Method 2: Download zip
  cd /tmp
  if retry "curl -fsSL https://github.com/swisskyrepo/PayloadsAllTheThings/archive/master.zip -o payloads.zip"; then
    if retry "unzip -qo payloads.zip"; then
      if retry "mv PayloadsAllTheThings-master /opt/PayloadsAllTheThings"; then
        if bash -c "${CHECK[payloadsallthethings]}" >/dev/null 2>&1; then
          success "PayloadsAllTheThings installed from zip"
          return 0
        fi
      fi
    fi
  fi
  
  error "Failed to install PayloadsAllTheThings with all methods"
  INSTALL_STATUS[payloadsallthethings]="FAILED"
  return 1
}

install_ngrok() {
  if bash -c "${CHECK[ngrok]}" >/dev/null 2>&1; then
    success "ngrok already installed"
    return 0
  fi
  
  log "Installing ngrok with multiple methods..."
  
  # Method 1: Official script
  if retry "curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null"; then
    if retry "echo 'deb https://ngrok-agent.s3.amazonaws.com buster main' | tee /etc/apt/sources.list.d/ngrok.list"; then
      if retry "apt-get update && apt-get install -y ngrok"; then
        if bash -c "${CHECK[ngrok]}" >/dev/null 2>&1; then
          success "ngrok installed via apt repository"
          return 0
        fi
      fi
    fi
  fi
  
  # Method 2: Direct download
  local arch_map=""
  case "$ARCH" in
    x86_64) arch_map="amd64" ;;
    aarch64|arm64) arch_map="arm64" ;;
    armv7l|armhf) arch_map="arm" ;;
    *) arch_map="amd64" ;;
  esac
  
  cd /tmp
  local ngrok_url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-stable-linux-${arch_map}.zip"
  
  if retry "curl -fsSL '$ngrok_url' -o ngrok.zip"; then
    if retry "unzip -qo ngrok.zip"; then
      if retry "install -m 0755 ngrok /usr/local/bin/ngrok"; then
        if bash -c "${CHECK[ngrok]}" >/dev/null 2>&1; then
          success "ngrok installed via direct download"
          return 0
        fi
      fi
    fi
  fi
  
  # Method 3: Snap as last resort (if available)
  if command -v snap >/dev/null 2>&1; then
    if retry "snap install ngrok"; then
      if bash -c "${CHECK[ngrok]}" >/dev/null 2>&1; then
        success "ngrok installed via snap"
        return 0
      fi
    fi
  fi
  
  error "Failed to install ngrok with all methods"
  INSTALL_STATUS[ngrok]="FAILED"
  return 1
}

# ---------- Tool Groups and Management ----------
GROUP_Essentials=(openssh-server tmux screen htop curl wget git unzip p7zip-full python3 python3-pip)
GROUP_Recon_OSINT=(nmap masscan whois dnsutils amass theharvester)
GROUP_Web_Hacking=(ffuf dirsearch nikto sqlmap whatweb wpscan)
GROUP_Password_Cracking=(hydra medusa john hashcat)
GROUP_Network_Analysis=(tcpdump tshark bettercap)
GROUP_Utilities=(netcat-traditional socat jq xxd coreutils sed gawk)
GROUP_Wordlists_Tunnels=(seclists payloadsallthethings ngrok)
GROUP_Advanced=(netexec impacket sublist3r httpx)

ALL_TOOLS=(
  amass theharvester wpscan bettercap
  netexec impacket sublist3r httpx
  seclists payloadsallthethings ngrok
)

# Enhanced installer with comprehensive error handling
install_by_name() {
  local tool="$1"
  log "Installing: $tool"
  
  case "$tool" in
    amass) install_amass ;;
    theharvester) install_theharvester ;;
    wpscan) install_wpscan ;;
    bettercap) install_bettercap ;;
    impacket) install_impacket ;;
    netexec|cme|crackmapexec) install_netexec ;;
    sublist3r) install_sublist3r ;;
    httpx) install_httpx ;;
    seclists) install_seclists ;;
    payloadsallthethings) install_payloads_all_the_things ;;
    ngrok) install_ngrok ;;
    *)
      # Fallback to apt with retry
      if apt-cache show "$tool" >/dev/null 2>&1; then
        if retry "apt-get install -y '$tool'"; then
          success "Installed $tool via apt"
        else
          error "Failed to install $tool via apt"
          INSTALL_STATUS["$tool"]="FAILED"
        fi
      else
        warn "Unknown tool: $tool"
        INSTALL_STATUS["$tool"]="UNKNOWN"
      fi
      ;;
  esac
}

install_group() {
  local group="$1"
  log "Installing group: $group"
  
  case "$group" in
    Essentials)
      for pkg in "${GROUP_Essentials[@]}"; do
        retry "apt-get install -y $pkg" || warn "Failed: $pkg"
      done
      ;;
    Recon_OSINT)
      retry "apt-get install -y nmap masscan whois dnsutils"
      install_by_name amass
      install_by_name theharvester
      ;;
    Web_Hacking)
      retry "apt-get install -y ffuf dirsearch nikto sqlmap whatweb"
      install_by_name wpscan
      ;;
    Password_Cracking)
      retry "apt-get install -y hydra medusa john hashcat"
      ;;
    Network_Analysis)
      retry "apt-get install -y tcpdump tshark"
      install_by_name bettercap
      ;;
    Utilities)
      retry "apt-get install -y netcat-traditional socat jq xxd coreutils sed gawk"
      ;;
    Wordlists_Tunnels)
      install_by_name seclists
      install_by_name payloadsallthethings
      install_by_name ngrok
      ;;
    Advanced)
      install_by_name netexec
      install_by_name impacket
      install_by_name sublist3r
      install_by_name httpx
      ;;
    *)
      warn "Unknown group: $group"
      ;;
  esac
}

install_everything() {
  log "Starting full installation..."
  check_network
  
  install_apt_pkgs
  
  # Install groups in optimal order
  local groups=(Essentials Utilities Recon_OSINT Web_Hacking Password_Cracking Network_Analysis Wordlists_Tunnels Advanced)
  for group in "${groups[@]}"; do
    log "Installing group: $group"
    install_group "$group"
  done
  
  log "Full installation completed."
}

# Enhanced verification with detailed status
check_tools() {
  log "==== Comprehensive Tool Installation Status ===="
  local successful=0
  local failed=0
  local total=${#ALL_TOOLS[@]}
  
  for tool in "${ALL_TOOLS[@]}"; do
    if bash -lc "${CHECK[$tool]} >/dev/null 2>&1"; then
      success "✔ $tool - Working"
      ((successful++))
    else
      error "✘ $tool - Not working"
      ((failed++))
      
      # Try to provide helpful info
      if command -v "$tool" >/dev/null 2>&1; then
        warn "  → Command exists but check failed"
      else
        warn "  → Command not found in PATH"
      fi
    fi
  done
  
  log "==== Installation Summary ===="
  log "Successful: $successful/$total"
  log "Failed: $failed/$total"
  log "Success Rate: $(( (successful * 100) / total ))%"
  
  # Show failed installations with status
  if [ ${#INSTALL_STATUS[@]} -gt 0 ]; then
    log "==== Installation Issues ===="
    for tool in "${!INSTALL_STATUS[@]}"; do
      warn "$tool: ${INSTALL_STATUS[$tool]}"
    done
  fi
  
  # Final verification attempts
  if [ $failed -gt 0 ]; then
    log "==== Attempting Recovery for Failed Tools ===="
    for tool in "${ALL_TOOLS[@]}"; do
      if ! bash -lc "${CHECK[$tool]} >/dev/null 2>&1"; then
        log "Attempting recovery for: $tool"
        
        # Try alternative installation methods
        case "$tool" in
          amass|httpx)
            # Try apt version as fallback
            if apt-cache search "^$tool$" | grep -q "$tool"; then
              retry "apt-get install -y $tool" && success "Recovered $tool via apt"
            fi
            ;;
          theharvester|sublist3r|impacket)
            # Try direct pip install
            retry "pip3 install $tool" && success "Recovered $tool via pip3"
            ;;
        esac
      fi
    done
  fi
  
  # Final count
  successful=0
  failed=0
  for tool in "${ALL_TOOLS[@]}"; do
    if bash -lc "${CHECK[$tool]} >/dev/null 2>&1"; then
      ((successful++))
    else
      ((failed++))
    fi
  done
  
  log "==== Final Results ===="
  log "Final Success Rate: $(( (successful * 100) / total ))%"
  
  if [ $successful -eq $total ]; then
    success "[+] 100% SUCCESS! All tools installed and working!"
  else
    warn "[!] $failed tools still not working. Check logs at /var/log/hackstation.log"
  fi
}

# System optimization and fixes
optimize_system() {
  log "Applying system optimizations..."
  
  # Fix common PATH issues
  cat >> /root/.bashrc << 'BASHRC_ADDITIONS'

# HackStation PATH additions
export PATH="$PATH:/root/.local/bin:/usr/local/go/bin:/root/go/bin"
export GOPATH="/root/go"

# Tool aliases for convenience
alias nxc='crackmapexec'
alias cme='crackmapexec'
alias harvester='theHarvester'

BASHRC_ADDITIONS

  # Create global profile additions
  cat > /etc/profile.d/hackstation.sh << 'PROFILE_ADDITIONS'
export PATH="$PATH:/root/.local/bin:/usr/local/go/bin:/root/go/bin"
export GOPATH="/root/go"
PROFILE_ADDITIONS
  chmod +x /etc/profile.d/hackstation.sh
  
  # Fix pipx issues
  if command -v pipx >/dev/null 2>&1; then
    pipx ensurepath --global 2>/dev/null || true
  fi
  
  # Create tool directories
  mkdir -p /opt/{tools,wordlists,scripts}
  mkdir -p /root/{tools,wordlists,scripts}
  
  # Set proper permissions
  chmod 755 /opt/{tools,wordlists,scripts}
  chmod 755 /root/{tools,wordlists,scripts}
  
  success "System optimizations applied"
}

usage() {
cat <<'USAGE'
HackStation - Universal Penetration Testing Tool Installer
Usage:
  # Full install with optimizations (recommended)
  ./hackstation.sh --all

  # Install a specific group:
  ./hackstation.sh --group Recon_OSINT
  Groups:
    Essentials, Recon_OSINT, Web_Hacking, Password_Cracking,
    Network_Analysis, Utilities, Wordlists_Tunnels, Advanced

  # Install single tool with all fallback methods:
  ./hackstation.sh --tool amass
  ./hackstation.sh --tool bettercap

  # Comprehensive status check with recovery attempts
  ./hackstation.sh --check

  # System optimization and PATH fixes
  ./hackstation.sh --optimize

  # Recovery mode - attempt to fix failed installations
  ./hackstation.sh --recover

Enhanced Features:
- Retry mechanisms with exponential backoff
- Multiple installation methods per tool
- Comprehensive error logging (/var/log/hackstation.log)
- Network connectivity verification  
- Automatic recovery attempts
- System optimization and PATH management
- 100% success rate focus with detailed reporting

Notes:
- All tools have multiple fallback installation methods
- Comprehensive logging for troubleshooting
- Automatic PATH management across shell sessions
- Recovery mechanisms for network/dependency issues
USAGE
}

# Recovery mode - attempt to fix previously failed installations
recovery_mode() {
  log "Starting recovery mode..."
  
  # Re-source environment
  source /root/.bashrc 2>/dev/null || true
  export PATH="$PATH:/root/.local/bin:/usr/local/go/bin:/root/go/bin"
  
  # Fix common issues
  log "Fixing common issues..."
  
  # Update package database
  retry "apt-get update"
  
  # Fix broken packages
  retry "apt-get -f install -y"
  retry "dpkg --configure -a"
  
  # Reinstall pip and pipx
  retry "apt-get install --reinstall -y python3-pip"
  retry "python3 -m pip install --upgrade pip"
  retry "python3 -m pip install --upgrade pipx"
  
  # Re-attempt failed tool installations
  for tool in "${ALL_TOOLS[@]}"; do
    if ! bash -lc "${CHECK[$tool]} >/dev/null 2>&1"; then
      warn "Re-attempting installation of: $tool"
      install_by_name "$tool"
    fi
  done
  
  # Final optimization
  optimize_system
  
  success "Recovery mode completed"
}

# ---------- Enhanced CLI ----------
main() {
  if [ $# -eq 0 ]; then
    usage
    exit 0
  fi
  
  case "${1:-}" in
    --all)
      install_everything
      optimize_system
      check_tools
      ;;
    --group)
      shift
      [ $# -ge 1 ] || die "Missing group name"
      install_apt_pkgs
      install_group "$1"
      ;;
    --tool)
      shift
      [ $# -ge 1 ] || die "Missing tool name"
      install_apt_pkgs
      install_by_name "$1"
      ;;
    --check)
      check_tools
      ;;
    --optimize)
      optimize_system
      ;;
    --recover)
      recovery_mode
      check_tools
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  
  log "HackStation setup completed - $(date)"
}

# Initialize and run
check_network
install_apt_pkgs
main "$@"
