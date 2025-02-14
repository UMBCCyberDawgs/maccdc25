param (
    [switch]$d,  # define the -u flag as a switch (boolean flag)
    [Parameter(Mandatory=$false)]
    [string]$exemptUser = "Administrator",
    [Parameter(Mandatory=$false)]
    [string]$groupName = "Administrators"
)

# if d is present do on domain level
if ($d) {
    Write-Host "Starting domain clean"
    $groupMembers = Get-ADGroupMember -Identity $groupName | Where-Object { $_.objectClass -eq "user" }
    foreach ($member in $groupMembers) {
        if ($member.SamAccountName -ne $exemptUser) {
            try {
                Remove-ADGroupMember -Identity $groupName -Members $member -Confirm:$false
                Write-Host "Removed $($member.SamAccountName) from $groupName"
            } catch {
                Write-Host "Failed to remove $($member.SamAccountName): $_"
            }
        } else {
            Write-Host "Skipping exempt user: $exemptUser"
        }
    }
} else {
    Write-Host "Starting local clean"
    $localGroupMembers = Get-LocalGroupMember -Group $groupName
    foreach($user in $localGroupMembers){
        if($user.Name -ne $exemptUser){
            Remove-LocalGroupMember -Group $groupName -Member $user.Name
            Write-Host "removed $($user.Name) from group $($groupName)"   
        }
    }
}
