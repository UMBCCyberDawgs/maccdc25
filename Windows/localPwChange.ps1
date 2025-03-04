$newPassword = Read-Host -AsSecureString -Prompt "Enter the new password: "

Get-LocalUser | ForEach-Object {
    $username = $_.Name
    try {
        Set-LocalUser -Name $username -Password $newPassword
        Write-Host "Password changed successfully for user: $username"
    } catch {
        Write-Host "Failed to change password for user: $username - $($_.Exception.Message)"
    }
}