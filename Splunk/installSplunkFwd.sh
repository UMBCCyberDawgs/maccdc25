#!/bin/bash
SERVER_IP="172.20.241.20"
MGMT_PORT="8089"
INDEX_PORT="9997"
SPLUNK_BIN_PATH="/opt/splunkforwarder/bin/splunk"
SPLUNK_HOME_PATH="/opt/splunkforwarder"
DOWNLOAD_LINK_RPM="https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-6b4ebe426ca6.x86_64.rpm"
DOWNLOAD_LINK_DPKG="https://download.splunk.com/products/universalforwarder/releases/9.4.0/linux/splunkforwarder-9.4.0-6b4ebe426ca6-linux-amd64.deb"
LINUX_LOG_FORMAT="[monitor:///var/log]\ndisabled=0\nindex=linux_logs\nsourcetype=syslog\nrecursive=true"
function checkSplunkInstalled() {
	if [[ -x "$SPLUNK_BIN_PATH" ]]; then
		echo "Splunk Universal Forwarder is already installed."
		return 0
	fi
	return 1
}

function installSplunk(){
	if command -v rpm &>/dev/null; then
		echo "RPM-based system detected."
		wget -O splunkforwarder-9.4.0-6b4ebe426ca6.x86_64.rpm "$DOWNLOAD_LINK_RPM" --no-check-certificate
		sudo rpm --nosignature -i splunkforwarder-9.4.0-6b4ebe426ca6.x86_64.rpm
	elif command -v dpkg &>/dev/null; then
		echo "DPKG-based system detected."
		wget -O splunkforwarder-9.4.0-6b4ebe426ca6-linux-amd64.deb "$DOWNLOAD_LINK_DPKG" --no-check-certificate
		sudo dpkg -i splunkforwarder-9.4.0-6b4ebe426ca6-linux-amd64.deb
	else
		echo "Neither RPM nor DPKG is available. Exiting."
		exit 1
	fi
}

function setupDeploymentServer() {
	sudo "$SPLUNK_BIN_PATH" set deploy-poll "$SERVER_IP:$MGMT_PORT"
 	echo -e "\n[deployment-client]" >> "/opt/splunkforwarder/etc/system/local/deploymentclient.conf"
}

function addForwardServer() {
	sudo "$SPLUNK_BIN_PATH" add forward-server "$SERVER_IP:$INDEX_PORT"
}

function startSplunk() {
	sudo "$SPLUNK_BIN_PATH" start --accept-license
}

function addMonitor() {
	echo -e "$LINUX_LOG_FORMAT" >> "/opt/splunkforwarder/etc/system/local/inputs.conf"
 }

if ! checkSplunkInstalled; then
	echo "Splunk Universal Forwarder is not installed. Proceeding with installation..."
	installSplunk
	setupDeploymentServer
	addForwardServer
 	addMonitor
	startSplunk
else
	echo "No installation required."
	setupDeploymentServer
	addForwardServer
 	addMonitor
	startSplunk
fi

