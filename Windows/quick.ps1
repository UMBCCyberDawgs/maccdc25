Set-SmbServerConfiguration -EnableSMB1Protocol $false -EnableSMB2Protocol $true –EncryptData $true –RejectUnencryptedAccess $true -RequireSecuritySignature $true -EnableSecuritySignature $true -AuditSmb1Access $true
Disable-WindowsOptionalFeature -Online -FeatureName "TelnetClient" 
Disable-WindowsOptionalFeature -Online -FeatureName "TFTP"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LMCompatibilityLevel" -Value 4
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" -Name "UseLogonCredential" -Value 0
"
HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run	
HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunOnce
User: C:\Users\USERNAME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\
System: C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\
"