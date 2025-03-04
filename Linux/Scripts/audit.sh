if [ "$(id -u)" != "0" ]; then
    echo -e "\e[31mThis script must be run as root\e[0m" 1>&2
    exit 1
fi

# User / Group / Permisssio

# Checks for all users with uid of 0
check_root_users() {
    echo -e "\e[32m[+] Checking for root users\e[0m" 1>&2
    users=$(sudo awk -F: '$3 == 0 { print $0 }' /etc/passwd)
    echo $users
}

check_users_with_empty_passwords() {
    echo -e "\e[32m[+] Checking for empty passwords\e[0m" 1>&2
    users=$(sudo awk -F: '($2 == "") { print $1 }' /etc/shadow)
    if [[ -z "$users" ]]; then
	echo "No users with empty passwords found"
    else
	echo "$users"
    fi
}

check_all_shell_users() {
    echo -e "\e[32m[+] Checking for shell users\e[0m" 1>&2
    users=$(cat /etc/passwd | grep -E "/bin/.*sh" | cut -d":" -f1)
    echo $users
}

check_root_users
check_users_with_empty_passwords
check_all_shell_users
