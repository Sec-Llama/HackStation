# **HackStation Project**

**Developed by:** P1N3APPL3 @Sec-Llama

---

## **Overview**

HackStation is a comprehensive, plug-and-play toolkit designed for cybersecurity professionals, penetration testers, and ethical hackers. It provides an easy-to-use installation script to quickly set up a variety of essential tools, from reconnaissance to password cracking and web exploitation. HackStation is built with a focus on Debian-based operating systems (like Kali Linux, Parrot, Ubuntu), offering a one-stop solution for setting up a fully operational hacking station.

---

## **Key Features**

* **Automated Tool Installation**: Install essential cybersecurity tools with a single command.
* **Customizable**: Choose between installing individual tools, groups of tools, or all tools in the toolkit.
* **Tool Status Checker**: Check the status of installed tools to ensure your environment is set up correctly.
* **Official Methods**: Tools are installed using the official, most efficient methods (APT, Snap, Go, GitHub, etc.).
* **Cross-Distro Support**: Designed for Debian-based systems but flexible enough to work on others with minimal changes.

---

## **Tools Included**

### **Essentials**:

* **Openssh-server**, **tmux**, **screen**, **curl**, **wget**, **git**, **python3**, **p7zip**, **unzip**, and more.

### **Recon & OSINT**:

* **Nmap**, **Masscan**, **Whois**, **dnsutils**, **Amass**, **theHarvester**, and more.

### **Web Hacking**:

* **FFUF**, **Dirsearch**, **Nikto**, **SQLMap**, **WhatWeb**, **WPScan**, and more.

### **Password Cracking**:

* **Hydra**, **Medusa**, **John the Ripper**, **Hashcat**.

### **Network Analysis**:

* **Tcpdump**, **Tshark**, **Bettercap**.

### **Utilities**:

* **Netcat**, **Socat**, **JQ**, **XXD**, **Coreutils**, **Sed**, **Gawk**, and more.

### **Wordlists & Tunneling**:

* **SecLists**, **PayloadsAllTheThings**, **Ngrok**.

### **Advanced Tools**:

* **CrackMapExec**, **Impacket**, **Sublist3r**, **httpx**.

---

## **Installation**

### **1. Prerequisites**

Before using the script, ensure your system is a **Debian-based OS** (Kali, Parrot, Ubuntu, etc.) with root or sudo access.

### **2. Installing HackStation Toolkit**

Clone the repository and run the installation script:

```bash
git clone https://github.com/Sec-Llama/HackStation.git
cd HackStation
sudo bash install_tools.sh
```

This script will automatically install the tools listed in the toolkit. You can choose to install individual tools, groups of tools, or all tools at once.

---

## **Usage**

Once the script completes, you can run HackStation with the following options:

```bash
sudo bash install_tools.sh
```

* **1) Install a specific tool**: Select a tool from the list and install it individually.
* **2) Install a group of tools**: Install a predefined group of tools (e.g., Recon\_OSINT, Web\_Hacking).
* **3) Install all the tools**: Install all tools from all groups.
* **4) ToolCheck**: Check the installation status of each tool. This will display the installed tools in a visual format.
* **5) Exit**: Exit the menu.

---

## **Example:**

### **Install a Specific Tool**

If you want to install just **Amass**, you can choose option 1 and select it from the list.

```bash
1) Install a specific tool
2) Install a group of tools
3) Install all the tools
4) ToolCheck
5) Exit
```

Then, simply follow the prompts to install.

---

## **Tool Installation Methods**

The tools are installed using **official installation methods** to ensure reliability:

* **APT**: Tools available in the system’s repository (e.g., `sudo apt install nmap`)
* **Snap**: For tools like Amass (e.g., `sudo snap install amass`)
* **Go**: Tools like Amass and httpx are installed via Go (e.g., `go install github.com/owasp-amass/amass/v4/...@master`)
* **Ruby Gem**: Tools like WPScan and Bettercap use the Ruby gem package manager (e.g., `gem install wpscan`)
* **GitHub**: Some tools are installed by cloning their GitHub repositories (e.g., `git clone https://github.com/laramies/theHarvester.git`)

---

## **Troubleshooting**

* If you encounter any errors related to dependencies, ensure your system is fully updated by running:

  ```bash
  sudo apt update && sudo apt upgrade
  ```

* For any installation issues, check the official installation documentation for the specific tool.

---

## **Contributions**

If you have suggestions, improvements, or bug fixes, feel free to fork the repository and submit a pull request.

---

## **License**

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## **Contact**

For any issues or questions, feel free to reach out to us at [Sec-Llama](https://www.sec-llama.com).

---

**Enjoy using HackStation!**
**Stay Secure. Stay Ethical.**

