$groupName = Get-Date -Format FileDateTime

New-SMAGroup -name $GroupName -description 'PS Module Test' -members 'admin@local'

Get-SMAGroup -name $groupName

# Modify a Group
New-SMAUSer -uid 'groupmember1@local' -email 'groupmember1@local' -Name 'Temp group member 1'
New-SMAUSer -uid 'groupmember2@local' -email 'groupmember2@local' -Name 'Temp group member 2'
$newMembers = @('groupmember1@local','groupmember2@local')
Set-SMAGroup -name $groupName -description 'Changed Group Description' -members $newMembers

# Remove Group Member Users and Group
Remove-SMAUSer -email 'groupmember1@local'
Remove-SMAUSer -email 'groupmember2@local'

Remove-SMAGroup -name $groupName





