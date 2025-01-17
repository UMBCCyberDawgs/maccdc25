Invoke-WebRequest -Uri "https://download.splunk.com/products/universalforwarder/releases/9.4.0/windows/splunkforwarder-9.4.0-6b4ebe426ca6-windows-x64.msi" -OutFile "splunkforwarder-9.4.0-6b4ebe426ca6-windows-x64.msi"

Start-Process -FilePath "msiexec.exe" -ArgumentList "/i splunkforwarder-9.4.0-6b4ebe426ca6-windows-x64.msi /quiet /norestart" -Wait -NoNewWindow

#It will prompt you to put in the server name. or the competition it will be 172.20.241.20:8089 for the deployment server and 172.20.241.20:9997 for the indexer port.
    
cd "C:\Program Files\SplunkUniversalForwarder\bin"
.\splunk.exe start
