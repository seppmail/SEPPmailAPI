# Examples for the SEPPmailAPI Module

Below, find some examples on how to use the module. The modules CmdLets output are PSObjects for easier further processing. Read the API documentation on https://docs.seppmail.com/api for insights of the API

## Manage Users

This section explains CRUD (Create, Read, Modify and Delete) operations on SEPPmail User Objects.
Especially in environments with often changing useraccounts (i.e. education) this should be helpful. For mass-changes use external sources like Active Directory or CSV-files for modifying.

### Create new SEPPmail users

Create a single SEPPmail user. you need at least 3 properties for a new user
- uid
- email
- name

More properties may be defined as well, see CmdLet help for more.

*NOTE:* Without specifying a customer this user-object will be created in the [none] customer.

```powershell
New-SMAUser -uid 'umeyer@domain.local' -email 'ullrich.meyer@yourdomain.com' -Name 'Ulli Meyer'
```

Create a single user for a customer.
*NOTE:* Customer Names are __case sensitive!__

```powershell
New-SMAUser -uid 'sandra.berger@fab.int' -email 'sberger@fabrikam.com' -Name 'Sandra Berger' -customer 'Fabrikam'
```

Creating multiple users via CSV import

```powershell
$SampleCSVPath = (Split-Path (Get-Module SEPPmailapi).path) + '\examples\NewUsers.csv'
$newusers = import-csv $SampleCSVPath
foreach ($user in $newusers) {$user|new-SMAUser}
```

For more examples use the CmdLet help

```powershell
Get-Help New-SMAUser -examples
```

### Change a SEPPmail users properties

#### Change a single User

```powershell
# Change locked status
Set-SMAUser -email 'sberger@fabrikam.com' -locked $true
# Change user Display Name
Set-SMAUser -email 'sberger@fabrikam.com' -name 'Alexandra Berger'
# Disable sign and encrypt possibility
Set-SMAUser -email 'sberger@fabrikam.com' -mayNotSign $true -MayNotEncrypt $true
```

#### Changing multiple users via CSV import

```powershell
# The below example shows a CSV which changes all users to $locked 
$SampleCSVPath = (Split-Path (Get-Module SEPPmailapi).path) + '\examples\UpdateUsers.csv'
$changeusers = Import-CSV $SampleCSVPath
foreach ($i in $changeusers) {Set-SMAUser -eMailAddress $i.eMail -locked ([boolean]$i.locked)}
```

For more examples use the commandlet help.

```powershell
Get-Help Set-SMAUser -examples
```

### Remove SEPPmail Users

*NOTE:* Removing a User has no recycle bin functionality. Removed users are GONE!

Remove-SMAUSers works pretty similar to the CmdLets above. If you want to remove a SEPPmail user, you just need the e-Mail address as identifyer.

```powershell
$SampleCSVPath = (Split-Path (Get-Module SEPPmailapi).path) + '\examples\NewUsers.csv'
$newusers = import-csv $SampleCSVPath
foreach ($user in $newusers) {$user|Remove-SMAUser}
```

--- This is the end of the file ---
