#!/bin/bash

#These will be set with environment variables in coordinate
#SERVER_IP
#SPLUNK_USER
#SPLUNK_PASS
PASSWD_LINE=":admin:\$6\$ac53GIJaE2DCDHor\$M6PPl3fSB9dHAaOBnS3Zj/nWM1Ucm81H0u5P6ZhxUoGc4RTCrZMMVE4UciozFVQk8Ha8ZYHq4A9uIAueoQHDf/::Administrator:admin:changeme@example.com:::20166"
MGMT_PORT="8089"
INDEX_PORT="9997"

SPLUNK_BIN_PATH="/opt/splunkforwarder/bin/splunk"
SPLUNK_HOME_PATH="/opt/splunkforwarder"

DOWNLOAD_LINK_RPM="https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-6b4ebe426ca6.x86_64.rpm"
DOWNLOAD_LINK_DPKG="https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-6b4ebe426ca6-linux-amd64.deb"

MONITOR_FILE="[monitor:///var/log/audit/audit.log]\ndisabled = false\nindex = linux_audit\nsourcetype = auditd\n"

function installSplunk(){
	if command -v rpm &>/dev/null; then
		echo "RPM-based system detected."
		wget -O splunkforwarder-9.4.0-6b4ebe426ca6.x86_64.rpm "$DOWNLOAD_LINK_RPM" --no-check-certificate
		rpm --nosignature -i splunkforwarder-9.4.0-6b4ebe426ca6.x86_64.rpm
	elif command -v dpkg &>/dev/null; then
		echo "DPKG-based system detected."
		wget -O splunkforwarder-9.4.0-6b4ebe426ca6-linux-amd64.deb "$DOWNLOAD_LINK_DPKG" --no-check-certificate
		dpkg -i splunkforwarder-9.4.0-6b4ebe426ca6-linux-amd64.deb
	else
		echo "Neither RPM nor DPKG is available. Exiting."
		exit 1
	fi
}

function setupFirstTimeUser() {
    echo "$PASSWD_LINE" >> "$SPLUNK_HOME_PATH/etc/passwd"
    "$SPLUNK_BIN_PATH" start --accept-license --answer-yes
}

function setupDeploymentServer() {
    "$SPLUNK_BIN_PATH" set deploy-poll "$SERVER_IP:$MGMT_PORT" -auth "$SPLUNK_USER:$SPLUNK_PASS"
    echo -e "\n[deployment-client]" >> "/opt/splunkforwarder/etc/system/local/deploymentclient.conf"
}

function addForwardServer() {
    echo "$SPLUNK_USER:$SPLUNK_PASS"
    "$SPLUNK_BIN_PATH" add forward-server "$SERVER_IP:$INDEX_PORT" -auth "$SPLUNK_USER:$SPLUNK_PASS"
}

function startSplunk() {
    "$SPLUNK_BIN_PATH" restart 
}

function addMonitor() {
    echo -e "$MONITOR_FILE" >> "$SPLUNK_HOME_PATH/etc/system/local/inputs.conf"
}


echo "[+] Installing Splunk Forwarder"
installSplunk
echo "[+] Setting up admin user"
setupFirstTimeUser
echo "[+] Setting up index server"
addForwardServer
echo "[+] Monitoring logs"
addMonitor
echo "[+] Starting Splunk Forwarder"
startSplunk


