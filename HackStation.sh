#!/usr/bin/env bash
set -euo pipefail

if (( EUID != 0 )); then
    echo "Run this script with sudo or as root."
    exit 1
fi

apt update

# APT tools
ALL_APT_TOOLS=(
  openssh-server tmux screen htop curl wget git unzip p7zip-full
  python3 python3-pip
  nmap masscan whois dnsutils
  ffuf dirsearch nikto sqlmap whatweb
  hydra medusa john hashcat
  tcpdump tshark netcat-traditional socat
  jq xxd coreutils sed gawk
)

declare -A GROUP_TOOLS=(
  [Essentials]="openssh-server tmux screen htop curl wget git unzip p7zip-full python3 python3-pip"
  [Recon_OSINT]="nmap masscan whois dnsutils"
  [Web_Hacking]="ffuf dirsearch nikto sqlmap whatweb"
  [Password_Cracking]="hydra medusa john hashcat"
  [Network_Analysis]="tcpdump tshark"
  [Utilities]="netcat-traditional socat jq xxd coreutils sed gawk"
)
GROUP_NAMES=("Essentials" "Recon_OSINT" "Web_Hacking" "Password_Cracking" "Network_Analysis" "Utilities")

install_packages() { apt install -y "$@"; }

# Fallback installers

install_amass() {
    if apt-cache show amass >/dev/null 2>&1; then
        install_packages amass
    elif command -v snap >/dev/null 2>&1; then
        snap install amass
    else
        echo "[*] Installing Amass via Go..."
        install_packages golang git
        export GOPATH="${GOPATH:-$HOME/go}"
        export PATH="$PATH:$GOPATH/bin"
        go install -v github.com/owasp-amass/amass/v4/...@master
    fi
}

install_theharvester() {
    # Use the packaged version if available
    if apt-cache show theharvester >/dev/null 2>&1; then
        apt install -y theharvester
        return
    fi
    echo "[*] Installing theHarvester via pipx..."
    # Try to install pipx and a generic venv module via apt
    if ! command -v pipx >/dev/null 2>&1; then
        apt install -y pipx python3-venv || {
            # Fall back to pip if pipx isn’t packaged
            python3 -m pip install --user pipx --break-system-packages
        }
        # Ensure pipx’s binary path is on PATH
        pipx ensurepath || true
        export PATH="$PATH:$HOME/.local/bin"
    fi
    # Install directly from the official repository using pipx
    # This approach avoids referencing python3.12-venv and is compatible with Python 3.11.
    pipx install git+https://github.com/laramies/theHarvester.git || {
        echo "[-] Failed to install theHarvester with pipx." >&2
        return 1
    }
}


install_wpscan() {
    if apt-cache show wpscan >/dev/null 2>&1; then
        install_packages wpscan
    else
        echo "[*] Installing WPScan via Ruby gem..."
        install_packages ruby ruby-dev build-essential
        gem install wpscan
    fi
}

install_bettercap() {
    if apt-cache show bettercap >/dev/null 2>&1; then
        install_packages bettercap
    else
        echo "[*] Installing bettercap via Ruby gem..."
        install_packages ruby-dev libpcap-dev build-essential
        gem install bettercap
    fi
}

install_group() {
    local idx="$1"
    local group="${GROUP_NAMES[$idx]}"
    read -ra pkgs <<< "${GROUP_TOOLS[$group]}"
    install_packages "${pkgs[@]}"
}

install_all_apt() {
    for pkg in "${ALL_APT_TOOLS[@]}"; do
        install_packages "$pkg"
    done
    install_amass
    install_theharvester
    install_wpscan
    install_bettercap
}

install_advanced_tools() {
    install_packages build-essential libssl-dev libffi-dev python3-dev git
    if ! command -v pipx >/dev/null 2>&1; then
        install_packages pipx || python3 -m pip install --user pipx
        pipx ensurepath
        export PATH="$PATH:$HOME/.local/bin"
    fi
    pipx install git+https://github.com/byt3bl33d3r/CrackMapExec.git
    pipx install git+https://github.com/fortra/impacket.git
    pipx install git+https://github.com/aboul3la/Sublist3r.git
    install_packages golang
    export GOPATH="${GOPATH:-$HOME/go}"
    export PATH="$PATH:$GOPATH/bin"
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
}

install_optional_tools() {
    install_packages autossh sshuttle
    mkdir -p /opt
    cd /opt
    git clone --depth 1 https://github.com/danielmiessler/SecLists.git SecLists || true
    git clone --depth 1 https://github.com/swisskyrepo/PayloadsAllTheThings.git || true
    case "$(uname -m)" in
        armv7l|armhf) NG_ARCH="arm" ;;
        aarch64|arm64) NG_ARCH="arm64" ;;
        x86_64) NG_ARCH="amd64" ;;
        *) NG_ARCH="arm" ;;
    esac
    curl -Ls "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-stable-linux-${NG_ARCH}.zip" -o ngrok.zip
    unzip -qo ngrok.zip -d /usr/local/bin
    rm -f ngrok.zip
    chmod +x /usr/local/bin/ngrok
    echo "Add your ngrok auth token with: ngrok config add-authtoken <TOKEN>"
}

confirm_install_everything() {
    echo "This will install ALL tools:"
    echo "- APT tools: ${ALL_APT_TOOLS[*]}"
    echo "- Non-APT tools: amass, theHarvester, WPScan, bettercap"
    echo "- Advanced tools: crackmapexec, impacket, Sublist3r, httpx (via pipx/Go)"
    echo "- Optional extras: autossh, sshuttle, SecLists, PayloadsAllTheThings, ngrok"
    read -rp "Proceed with full installation? (y/N): " resp
    [[ "$resp" =~ ^[Yy]$ ]]
}

install_everything() {
    if confirm_install_everything; then
        install_all_apt
        install_advanced_tools
        install_optional_tools
        echo "[✔] Full installation complete."
    else
        echo "Operation cancelled."
    fi
}

# Interactive main menu loop
main_menu() {
    while true; do
        echo
        echo "Main Menu:"
        echo "1) Install a specific APT-based tool"
        echo "2) Install a group of APT-based tools"
        echo "3) Install all APT tools (incl. Amass/TheHarvester/WPScan/bettercap)"
        echo "4) Install advanced tools (pipx/Go)"
        echo "5) Install optional extras (wordlists, tunnels, etc.)"
        echo "6) Install everything (APT + advanced + optional)"
        echo "0) Exit"
        read -rp "Choice: " choice
        case "$choice" in
            1)
                echo "Available APT tools:"
                for i in "${!ALL_APT_TOOLS[@]}"; do printf "%2d) %s\n" "$i" "${ALL_APT_TOOLS[$i]}"; done
                read -rp "Enter tool number: " idx
                install_packages "${ALL_APT_TOOLS[$idx]}"
                ;;
            2)
                echo "Available groups:"
                for i in "${!GROUP_NAMES[@]}"; do printf "%2d) %s\n" "$i" "${GROUP_NAMES[$i]}"; done
                read -rp "Enter group number: " gidx
                install_group "$gidx"
                ;;
            3) install_all_apt ;;
            4) install_advanced_tools ;;
            5) install_optional_tools ;;
            6) install_everything ;;
            0) echo "Goodbye."; exit 0 ;;
            *) echo "Invalid choice." ;;
        esac
        echo
        read -rp "Press Enter to return to the main menu..." _
    done
}

main_menu
