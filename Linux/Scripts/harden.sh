if [ "$(id -u)" != "0" ]; then
    echo -e "\e[31mThis script must be run as root\e[0m" 1>&2
    exit 1
fi

color_text() {
    echo -e "\e[$1m$2\e[0m"
}

change_root_password() {
    echo -n "Root Password: "; read -r pass
    echo "root:$pass" | chpasswd
    color_text "32" "Successfully changed root password"
}

color_text "37" "Running Hardening Scripts..."
echo "[+] Changing root password..."
change_root_password

