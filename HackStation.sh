#!/usr/bin/env bash
set -euo pipefail

if (( EUID != 0 )); then
    echo "Run this script with sudo or as root."
    exit 1
fi

# Function to install via apt
install_packages() {
    apt install -y "$@"
}

# Function to install Amass via Snap or Go
install_amass() {
    if command -v snap >/dev/null 2>&1; then
        snap install amass
    else
        install_packages golang git
        export GOPATH="${GOPATH:-$HOME/go}"
        export PATH="$PATH:$GOPATH/bin"
        go install github.com/owasp-amass/amass/v4/...@master
    fi
}

# Function to install theHarvester from GitHub using uv
install_theharvester() {
    export PATH="$HOME/.local/bin:$PATH"
    if ! command -v uv >/dev/null 2>&1; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    if [ ! -d "$HOME/theHarvester" ]; then
        git clone https://github.com/laramies/theHarvester "$HOME/theHarvester"
    else
        cd "$HOME/theHarvester" && git pull
    fi
    cd "$HOME/theHarvester"
    uv venv && uv sync
}

# Function to install WPScan via Ruby Gem
install_wpscan() {
    if ! command -v wpscan >/dev/null 2>&1; then
        install_packages ruby ruby-dev build-essential
        gem install wpscan
    fi
}

# Function to install Bettercap via Ruby Gem
install_bettercap() {
    if ! command -v bettercap >/dev/null 2>&1; then
        install_packages ruby-dev libpcap-dev build-essential
        gem install bettercap
    fi
}

# Function to install CrackMapExec, Impacket, Sublist3r, and httpx
install_advanced_tools() {
    install_packages build-essential libssl-dev libffi-dev python3-dev git pipx golang
    pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"
    export GOPATH="${GOPATH:-$HOME/go}"
    export PATH="$PATH:$GOPATH/bin"
    pipx install git+https://github.com/byt3bl33d3r/CrackMapExec.git
    pipx install git+https://github.com/fortra/impacket.git
    pipx install git+https://github.com/aboul3la/Sublist3r.git
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest
}

# Function to install SecLists, PayloadsAllTheThings, and Ngrok
install_optional_tools() {
    install_packages autossh sshuttle
    mkdir -p /opt && cd /opt
    git clone --depth 1 https://github.com/danielmiessler/SecLists.git SecLists || true
    git clone --depth 1 https://github.com/swisskyrepo/PayloadsAllTheThings.git || true
    case "$(uname -m)" in
        armv7l|armhf) NG_ARCH="arm" ;;
        aarch64|arm64) NG_ARCH="arm64" ;;
        x86_64) NG_ARCH="amd64" ;;
        *) NG_ARCH="arm" ;;
    esac
    curl -Ls "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-stable-linux-${NG_ARCH}.zip" -o ngrok.zip
    unzip -qo ngrok.zip -d /usr/local/bin && rm ngrok.zip
    chmod +x /usr/local/bin/ngrok
}

# Function to install tools by name
install_by_name() {
    case "$1" in
        amass) install_amass ;;
        theharvester) install_theharvester ;;
        wpscan) install_wpscan ;;
        bettercap) install_bettercap ;;
        cme|impacket|sublist3r|httpx) install_advanced_tools ;;
        seclists|payloadsallthethings|ngrok) install_optional_tools ;;
        *) install_packages "$1" ;;
    esac
}

# Function to install all tools
install_everything() {
    for tool in "${ALL_TOOLS[@]}"; do
        install_by_name "$tool"
    done
    echo "[✔] All tools installed."
}

# Function to check installed tools and show results
check_tools() {
    echo -e "\n==== Tool Installation Status ====\n"
    for group in "${GROUP_NAMES[@]}"; do
        echo "$group:"
        for tool in ${GROUP_TOOLS[$group]}; do
            case "$tool" in
                seclists)
                    [[ -d /opt/SecLists || -d /usr/share/seclists ]] \
                        && echo "  ✔ $tool installed" || echo "  ✘ $tool missing"
                    ;;
                payloadsallthethings)
                    [[ -d /opt/PayloadsAllTheThings || -d /usr/share/PayloadsAllTheThings ]] \
                        && echo "  ✔ $tool installed" || echo "  ✘ $tool missing"
                    ;;
                theharvester)
                    [[ -x "$HOME/theHarvester/theHarvester.py" ]] \
                        && echo "  ✔ $tool installed" || echo "  ✘ $tool missing"
                    ;;
                *)
                    command -v "$tool" >/dev/null 2>&1 \
                        && echo "  ✔ $tool installed" || echo "  ✘ $tool missing"
                    ;;
            esac
        done
        echo
    done
    echo "==================================="
}

# List of all tools (APT + Custom)
APT_TOOLS=(openssh-server tmux screen htop curl wget git unzip p7zip-full python3 python3-pip
           nmap masscan whois dnsutils
           ffuf dirsearch nikto sqlmap whatweb
           hydra medusa john hashcat
           tcpdump tshark netcat-traditional socat
           jq xxd coreutils sed gawk)

CUSTOM_TOOLS=(amass theharvester wpscan bettercap cme impacket sublist3r httpx seclists payloadsallthethings ngrok)

ALL_TOOLS=("${APT_TOOLS[@]}" "${CUSTOM_TOOLS[@]}")

# Group tools
declare -A GROUP_TOOLS=(
  [Essentials]="openssh-server tmux screen htop curl wget git unzip p7zip-full python3 python3-pip"
  [Recon_OSINT]="nmap masscan whois dnsutils amass theharvester"
  [Web_Hacking]="ffuf dirsearch nikto sqlmap whatweb wpscan"
  [Password_Cracking]="hydra medusa john hashcat"
  [Network_Analysis]="tcpdump tshark bettercap"
  [Utilities]="netcat-traditional socat jq xxd coreutils sed gawk"
  [Wordlists_Tunnels]="seclists payloadsallthethings ngrok"
  [Advanced]="cme impacket sublist3r httpx"
)

GROUP_NAMES=("${!GROUP_TOOLS[@]}")

# ---------------------------- Menu ----------------------------
print_tool_list() {
    echo -e "\nAvailable tools (by index):"
    for i in "${!ALL_TOOLS[@]}"; do
        printf "%2d) %-20s" "$i" "${ALL_TOOLS[$i]}"
        (( (i + 1) % 4 == 3 )) && echo
    done
    echo
}

main_menu() {
    while true; do
        echo
        echo "==== HackerStation Menu ===="
        echo "1) Install a specific tool"
        echo "2) Install a group of tools"
        echo "3) Install all the tools"
        echo "4) Check installed tools"
        echo "5) Exit"
        echo "============================"
        read -rp "Choice: " choice
        case "$choice" in
            1)
                print_tool_list
                read -rp "Enter tool index: " idx
                if [[ "$idx" =~ ^[0-9]+$ && "$idx" -ge 0 && "$idx" -lt "${#ALL_TOOLS[@]}" ]]; then
                    install_by_name "${ALL_TOOLS[$idx]}"
                else
                    echo "Invalid index."
                fi
                ;;
            2)
                echo "Available groups:"
                for i in "${!GROUP_NAMES[@]}"; do printf "%2d) %s\n" "$i" "${GROUP_NAMES[$i]}"; done
                read -rp "Enter group index: " gidx
                if [[ "$gidx" =~ ^[0-9]+$ && "$gidx" -ge 0 && "$gidx" -lt "${#GROUP_NAMES[@]}" ]]; then
                    install_group "$gidx"
                else
                    echo "Invalid index."
                fi
                ;;
            3) install_everything ;;
            4) check_tools ;;
            5) echo "Goodbye."; exit 0 ;;
            *) echo "Invalid option." ;;
        esac
        echo; read -rp "Press Enter to return to the menu..."
    done
}

main_menu
