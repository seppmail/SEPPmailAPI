# Examples for the SEPPmailAPI Module

Below, find some examples on how to use the module. The modules CmdLets emits PSObjects for easier further processing in PowerShell. Read the API documentation on https://docs.seppmail.com/api for more detailed insights of the API.

## Manage Users

This section explains CRUD (Create, Read, Modify and Delete) operations on SEPPmail User Objects.
Especially in environments with often changing useraccounts (i.e. education) this should be helpful. For mass-changes use external sources like Active Directory or CSV-files for modifying.

### Finding Users

When you start exploring this module and your SEPPmail appliance, finding out which users exist on the system may be a good starting point.

To ge a List of all users on the SEPPmail appliance type:

```powershell
Find-SMAuser # Displays all info of all users
Find-SMAuser |select Name,email # Displays name and email of all users
```

This will return a list of existing users on your system, at least the default admin with e-mail admin@local if you are on a brand-new installation.

To limit the output of find-user to a specific customer use the -customer parameter.
__NOTE!__": Values in the -customer parameter are _case sensitive_.

```powershell
Find-SMAuser -customer 'Fabrikam'
```

### Create new SEPPmail users

#### Create a single SEPPmail user in the [default] customer.

You need at least 3 properties for a new user.

- uid
- email
- name

More properties may be defined as well, see CmdLet help for detailed information.

```powershell
New-SMAUser -uid 'umeyer@domain.local' -email 'ullrich.meyer@yourdomain.com' -Name 'Ulli Meyer'
```

#### Create a single user for a customer.

__NOTE!__ Customer Names are _case sensitive!_ . Customers must exist prior to create users for that customer.

```powershell
New-SMAUser -uid 'sandra.berger@fab.int' -email 'sberger@fabrikam.com' -Name 'Sandra Berger' -customer 'Fabrikam'
```

#### Creating multiple users via CSV import

```powershell
$SampleCSVPath = (Split-Path (Get-Module SEPPmailapi).path) + '\examples\NewUsers.csv'
$newusers = import-csv $SampleCSVPath
foreach ($user in $newusers) {$user|new-SMAUser}
```

For more examples use the CmdLet help.

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
# The below example shows a CSV which changes all users status to $locked 
$SampleCSVPath = (Split-Path (Get-Module SEPPmailapi).path) + '\examples\UpdateUsers.csv'
$changeusers = Import-CSV $SampleCSVPath
foreach ($i in $changeusers) {Set-SMAUser -eMail $i.eMail -locked ([boolean]$i.locked)}
```

For more examples use the commandlet help.

```powershell
Get-Help Set-SMAUser -examples
```

### Remove SEPPmail Users

__NOTE!__ Removing a zser has no recycle bin functionality. Removed users are GONE!

Remove-SMAUuer works pretty similar to the CmdLets above. If you want to remove a SEPPmail user, you just need the e-Mail address as identifyer.

#### Removing a single user 

```powershell
Remove-SMAUser -email 'sberger@fabrikam.com'
```

#### Removing multiple users via pipeline

```powershell
Find-SMAuser |where email -like '*wrongdomain.com' |foreach {Remove-SMAUser -email $_.email}
```

#### Removing multiple Users via CSV Import

```powershell
$SampleCSVPath = (Split-Path (Get-Module SEPPmailapi).path) + '\examples\NewUsers.csv'
$oldusers = import-csv $SampleCSVPath
foreach ($user in $oldusers) {Remove-SMAUser -email $user.email}
```

--- This is the end of the file ---
