# User Management
$timeId = Get-Date -Format FileDateTime
$userid = ('powershell_test_' + $timeid + '@local').ToLower()
$userName = 'PowerShell Test User ' + $timeid

# Create User with minimum requirements
New-SMAUser -uid $userid -email $userid -Name $userName

# Get this user
Get-SMAUser -eMail $userid

# Change this Users properties
$changedUserName = 'Changed PowerShell Test'
Set-SMAUser -eMail $userid -name $changedUserName

$changedUserPassword = 'S0meC00LPwd!'|ConvertTo-SecureString -AsPlainText
Set-SMAUser -eMail $userid -password $changedUserPassword

$changedUserSettings = @{
          mayNotEncrypt = $false
             mayNotSign = $true
                 locked = $false
         mailAccountUID =(New-GUID).Guid
    mailAccountPassword = 'S0meMailAccountC00LPwd!'|ConvertTo-SecureString -AsPlainText
        mailAccountHost = 'somehost.provider.eu'
         mailAccountSSL = $true
}
Set-SMAUser -eMail $userid @changedUserSettings

Find-smauser -partialMatch 'admin'

Remove-SMAUser -eMail $userid





