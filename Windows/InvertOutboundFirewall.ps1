param (
    [switch]$h  # Define the -d flag as a switch (boolean flag)
)
Write-Host "Starting"

if($h){
	# http/s outbound
	New-NetFirewallRule -DisplayName "Block Outbound HTTP (Port 80)" -Direction Outbound -Protocol TCP -LocalPort 80 -Action Block -Description "Blocks outbound HTTP traffic (Port 80)"
	New-NetFirewallRule -DisplayName "Block Outbound HTTP (Port 443)" -Direction Outbound -Protocol TCP -LocalPort 443 -Action Block -Description "Blocks outbound HTTP traffic (Port 443)"
	New-NetFirewallRule -DisplayName "Block Outbound HTTP (Port 8080)" -Direction Outbound -Protocol TCP -LocalPort 8080 -Action Block -Description "Blocks outbound HTTP traffic (Port 8080)"

	#http/s inbound
	New-NetFirewallRule -DisplayName "Block Inbound HTTP (Port 80)" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Block -Description "Blocks inbound HTTP traffic (Port 80)"
	New-NetFirewallRule -DisplayName "Block Inbound HTTP (Port 443)" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Block -Description "Blocks inbound HTTP traffic (Port 443)"
	New-NetFirewallRule -DisplayName "Block Inbound HTTP (Port 8080)" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Block -Description "Blocks inbound HTTP traffic (Port 8080)"

	# block nano
	New-NetFirewallRule -DisplayName "Block Inbound Traffic from 10.3.1.12" -Direction Inbound -RemoteAddress "10.3.1.12" -Action Block -Description "Blocks all inbound traffic from IP 10.3.1.12"
	New-NetFirewallRule -DisplayName "Block Outbound Traffic to 10.3.1.12" -Direction Outbound -RemoteAddress "10.3.1.12" -Action Block -Description "Blocks all outbound traffic to IP 10.3.1.12"
	Write-Host "Blocked HTTP/S"

}else{

	Set-NetFirewallProfile -Profile Domain,Private,Public -DefaultOutboundAction Block

	$ports = @(
	53,   #DNS 
	88,   #kerb
	135,  #RPC mapper 
	389,  #LDAP
	445,  #SMB
	#636,  #LDAP SSL
	3268 #LDAP Catalog
	#3269 #LDAP SSL Catalog 
	)

	foreach ($port in $ports) {
	    Write-Host "Allowing outbound traffic on port $port..."
	    New-NetFirewallRule -DisplayName "Allow Outbound AD Port $port (TCP)" -Direction Outbound -Action Allow -Protocol TCP -LocalPort $port
	    New-NetFirewallRule -DisplayName "Allow Outbound AD Port $port (UDP)" -Direction Outbound -Action Allow -Protocol UDP -LocalPort $port
	}
	# dynamic ephemerals (49152-65535)
	New-NetFirewallRule -DisplayName "Allow Outbound AD Dynamic RPC Ports" -Direction Outbound -Action Allow -Protocol TCP -LocalPort 49152-65535
}


Write-Host "Done"
