if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

WHEEL_OS=$(grep '^wheel:' /etc/group)


harden_sudoers() {
    echo "[+] Hardening Sudoers file..."
    echo "RGVmYXVsdHMgZW52X3Jlc2V0IApEZWZhdWx0cyBtYWlsX2JhZHBhc3MgCkRlZmF1bHRzIHNlY3VyZV9wYXRoPS91c3Ivc2JpbjovdXNyL2Jpbjovc2JpbjovYmluIApyb290IEFMTD0oQUxMOkFMTCkgQUxMIAolYWRtaW4gQUxMPShBTEwpIEFMTCAKJXN1ZG8gQUxMPShBTEw6QUxMKSBBTEwK" | base64 -d > /etc/sudoers
    find /etc/sudoers.d/ -mindepth 1 ! -name whiteteam ! -name blackteam -delete
}

disable_cron() {
    echo "[+] Disabling Cron"
    systemctl mask --now cron
}

remove_profiles() {
    echo "[+] Removing all profiles"
    mv /etc/prof{i,y}le.d 2>/dev/null
    mv /etc/prof{i,y}le 2>/dev/null
    for f in '.profile' '.bashrc' '.bash_login'; do
	find /home /root -name "$f" -exec rm {} \;
    done
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


reset_pam() {
    echo "[+] Resetting Pam Configs"
    DEBIAN_FRONTEND=noninteractive
    pam-auth-update --force  --package
#DO THIS MANUALLY. It takes too long to script    apt-get -y --reinstall install libpam-runtime libpam-modules
}


disable_history() {
    echo "[+] Disabling root history"
    ln -sf /dev/null /root/.bash_history
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

confidentiality_mode() {
    # edit LINUX_CMDLINE and LINUX_DEFAULT_CMDLINE in /etc/default/grub to include lockdown=confidentiality

    # I can "safely" assume grub is installed already

    mkdir -p /etc/default/grub.d/
    chmod 644 /etc/default/grub.d

    . /etc/default/grub

    cat <<-EOF > /etc/default/grub.d/gc2.cfg
    GRUB_CMDLINE_LINUX_DEFAULT="lockdown=confidentiality ${GRUB_CMDLINE_LINUX_DEFAULT}"
    GRUB_CMDLINE_LINUX="lockdown=confidentiality ${GRUB_CMDLINE_LINUX}"
EOF
    grub-mkconfig -o /boot/grub/grub.cfg
}

echo "Running Hardening Scripts..."

clear_ld_preload 
harden_sudoers
harden_sshd
disable_history
disable_cron
remove_profiles
sysctl_hardening
remove_compilers
reset_pam
