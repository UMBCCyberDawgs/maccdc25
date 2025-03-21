if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

DNS_ADDR="172.20.240.20"
WEB_ADDR="172.20.242.10"
SPLNK_ADDR="172.20.241.20"
WEBAPP_ADDR="172.20.241.30"
MAIL_ADDR="172.20.241.40"

CURRENT_IP=$(hostname -I | awk '{print $1}')

echo "$CURRENT_IP"

WHEEL_OS=$(grep '^wheel:' /etc/group)

false_all_users() {
    #randomizes all non root passwords and bin false except on 
    for u in $(cat /etc/passwd | grep -E "/bin/.*sh" | grep -v "root" | grep -v "dawg" | cut -d":" -f1); do
	if [[ "$CURRENT_IP" == "$MAIL_ADDR" ]]; then # you need password for authentication on mail server
	    usermod -s "/bin/false" "$u"
	    continue
	fi

	ns=$(date +%N)
	pw=$(echo "${ns}$REPLY" | sha256sum | cut -d" " -f1)	
	
	echo "$u:$pw" | chpasswd	
	
	echo "$u,$pw"
	usermod -s "/bin/false" "$u" 
    done
}


lock_all_service_accounts() {
    for u in $(cat /etc/passwd | grep -vE "/bin/.*sh" | cut -d":" -f1); do
        passwd -l $u;
    done

}


harden_sudoers() {
    echo "[+] Hardening Sudoers file..."
    # Determine the correct sudo group
    if [ -n "$WHEEL_OS" ]; then
        SUDO_GROUP="wheel"
    else
        SUDO_GROUP="sudo"
    fi
    
    # Overwrite /etc/sudoers with a hardened configuration
    cat <<EOF > /etc/sudoers
Defaults env_reset
Defaults mail_badpass
Defaults secure_path=/usr/sbin:/usr/bin:/sbin:/bin

root ALL=(ALL:ALL) ALL
dawg ALL=(ALL:ALL) ALL
%$SUDO_GROUP ALL=(ALL:ALL) ALL
EOF
    echo "[+] Sudoers file hardened for group: $SUDO_GROUP"
    find /etc/sudoers.d/ -mindepth 1 ! -name whiteteam ! -name blackteam -delete
}

disable_cron() {
    echo "[+] Disabling Cron"
    systemctl mask --now cron
}

disable_history() {
    echo "[+] Disabling root history"
    ln -sf /dev/null /root/.bash_history
}

remove_profiles() {
    echo "[+] Removing all profiles"
    mv /etc/prof{i,y}le.d 2>/dev/null
    mv /etc/prof{i,y}le 2>/dev/null
    for f in '.bash_profile' '.profile' '.bashrc' '.bash_login'; do
	find /home /root -name "$f" -exec rm {} \;
    done
    ln -sf /dev/null /etc/bash.bashrc
}

remove_compilers() {
    echo "[+] Removing Compilers and disabling kernel module insertion"
    /sbin/sysctl -w kernel.modules_disabled=1
    if command -v gcc &> /dev/null; then
	rm `which gcc`
    else
	echo "  - gcc not found"
    fi
    if command -v g++ &> /dev/null; then
        rm `which g++`
    else
        echo "  - g++ not found"
    fi
    if command -v cc &> /dev/null; then
        rm `which cc`
    else
        echo "  - cc not found"
    fi
}

clear_ld_preload() {
    echo "[+] Disabling LD Preload"
    export LD_PRELOAD=""
    BB_URL="https://www.busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox"
    if command -v wget &>/dev/null; then
    	echo found wget
    	wget "$BB_URL" -O ./busybox
        chmod u+x ./busybox
        ./busybox ln -sf /dev/null /etc/ld.so.preload
    elif command -v curl &>/dev/null; then
    	echo found curl
    	curl "$BB_URL" -L -o ./busybox
        chmod u+x ./busybox
        ./busybox ln -sf /dev/null /etc/ld.so.preload
    else
    	echo "unable to find wget or curl; using weaker system binary ln"
        ln -sf /dev/null /etc/ld.so.preload
    fi
}

remove_admin_users() {
    # Determine the correct sudo group
    if [ -n "$WHEEL_OS"]; then
        SUDO_GROUP="wheel"
    else
        SUDO_GROUP="sudo"
    fi

    users=$(grep "^$SUDO_GROUP:" /etc/group | tr ":" " " | cut -d' ' -f4- | tr "," " ")
    echo "Current admin users: $users"

    echo "[+] Removing old admin users"
    for user in $users; do
	if [[ "$user" == "whiteteam" || "$user" == "blackteam" ]]; then
            continue
	fi
	gpasswd -d "$user" "$SUDO_GROUP"
    done
    echo "[+] Adding new admin user"
    useradd -m -s "/bin/sh" "dawg"
    echo "$ADMIN_PASS:dawg"
    usermod -aG "$SUDO_GROUP" "dawg"
}


setup_auditd() {
    echo "[+] Setting up auditd"
    if command -v apt &>/dev/null; then
        sudo apt install -y auditd
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y audit
    elif command -v yum &>/dev/null; then
        sudo yum install -y audit
    else
        echo "[!] No supported package manager found. Install auditd manually."
        return 1
    fi
    URL="https://github.com/UMBCCyberDawgs/maccdc25/raw/refs/heads/main/Splunk/audit.rules"
    DEST="/etc/audit/rules.d/audit.rules"    
    echo "[+] auditd installation complete"
    echo "[+] Copying configuration files"
    if command -v wget &>/dev/null; then
	wget "$URL" -O "$DEST"
    elif command -v curl &>/dev/null; then
	curl -L "$URL" -o "$DEST"
    else
	echo "[!] Neither wget nor curl is installed. Please install one of them."
	return 1
    fi

    auditctl -R /etc/audit/rules.d/audit.rules    
}

configure_firewall() {
    echo "[+] Disabling firewall wrappers..."
    systemctl stop firewalld 2>/dev/null
    systemctl disable firewalld 2>/dev/null
    systemctl stop ufw 2>/dev/null
    systemctl disable ufw 2>/dev/null
    systemctl stop nftables 2>/dev/null
    systemctl disable nftables 2>/dev/null

    echo "[+] Flushing existing iptables rules..."
    iptables -F
    iptables -X
    iptables -Z

    echo "[+] Setting up new iptables rules..."
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP

    # Allow loopback traffic
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    # Allow established connections
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Allow SSH
#    iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -j ACCEPT
#    iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

    # Allow specific services based on the machine's IP
    if [[ "$CURRENT_IP" == "$WEB_ADDR" ]]; then
	echo "[+] This is the web server ($WEB_ADDR), allowing HTTP and HTTPS..."
	iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
	iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT
    fi

    if [[ "$CURRENT_IP" == "$WEBAPP_ADDR" ]]; then
	echo "[+] This is the web server ($WEB_ADDR), allowing HTTP and HTTPS..."
	iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
	iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT
    fi
    
    if [[ "$CURRENT_IP" == "$DNS_ADDR" ]]; then
	echo "[+] This is the DNS server ($DNS_ADDR), allowing DNS traffic..."
	iptables -A INPUT -p udp --dport 53 -j ACCEPT
	iptables -A INPUT -p tcp --dport 53 -j ACCEPT
    fi
    
    if [[ "$CURRENT_IP" == "$MAIL_ADDR" ]]; then
        echo "[+] This is the Mail server ($MAIL_ADDR), allowing SMTP and POP3 traffic..."
        iptables -A INPUT -p tcp --dport 25 -m conntrack --ctstate NEW -j ACCEPT
#        iptables -A INPUT -p tcp --dport 587 -m conntrack --ctstate NEW -j ACCEPT ---- SMTPS maybe inject?

        iptables -A INPUT -p tcp --dport 110 -m conntrack --ctstate NEW -j ACCEPT
#	iptables -A INPUT -p tcp --dport 143 -m conntrack --ctstate NEW -j ACCEPT --- IF Using IMAP for some reason??
#        iptables -A INPUT -p tcp --dport 995 -m conntrack --ctstate NEW -j ACCEPT ---- POP3S, maybe inject?
    fi
	
    echo "[+] Saving iptables rules..."
    if command -v iptables-save &>/dev/null; then
	iptables-save > /etc/iptables.rules
	echo "iptables-save completed."
    else
	echo "iptables-save not found, rules may not persist after reboot."
    fi
}


sysctl_hardening() {
    echo "[+] Hardening sysctl"

    cat <<-EOF >> /etc/sysctl.conf
    net.ipv6.conf.all.disable_ipv6=1
    net.ipv6.conf.default.disable_ipv6=1
    net.ipv4.tcp_syncookies=1
    net.ipv4.tcp_rfc1337=1
    net.ipv4.icmp_ignore_bogus_error_responses=1
    net.ipv4.conf.all.accept_redirects=0
    net.ipv4.icmp_echo_ignore_all=1
    fs.suid_dumpable=0
    kernel.kptr_restrict=2
    kernel.perf_event_paranoid=2
    kernel.randomize_va_space=2
    kernel.yama.ptrace_scope=3
    kernel.ftrace_enabled=0
    kernel.modules_disabled=1
    kernel.kexec_load_disabled=1
    kernel.unprivileged_bpf_disabled=1
    net.core.bpf_jit_harden=2
    net.core.bpf_jit_kallsyms=0
EOF
    sysctl -p
}


harden_sshd() {
    echo "[+] Hardening SSHD config..."
    echo "UGVybWl0Um9vdExvZ2luIG5vClB1YmtleUF1dGhlbnRpY2F0aW9uIG5vClVzZVBBTSBubwpVc2VETlMgbm8KQWRkcmVzc0ZhbWlseSBpbmV0Cg==" | base64 -d > /etc/ssh/sshd_config
    chattr +i /etc/ssh/sshd_config
}


echo "Running Hardening Scripts..."

false_all_users
lock_all_service_accounts
harden_sudoers
harden_sshd
clear_ld_preload 
disable_history
disable_cron

remove_profiles
remove_compilers

sysctl_hardening

setup_auditd
configure_firewall
