# Examples to use the SEPPmailAPI Module

Below, find some examples on how to use the module. The modulesCmdLets output are PSObjects for easier further processing. Read the API documentation on https://docs.seppmail.com/api


## Use the SEPPmailAPI Module

### Manage Users

This API allows you to create and modify Users. Especially in environments with many changing useraccounts (i.e. education) external sources for userdata may make sense.

#### Create new SEPPmail Users

Create single User

```powershell
New-SMUser -uid 'cde12348' -email 'u.m@fabrikam.com' -Name 'Ulli Meyer' -customer 'Contoso' -verbose
```

Creating multiple users via CSV import

```powershell
$SampleCSVPath = (Split-Path (Get-Module SEPPmailapi).path) + '\examples\NewUsers.csv'
$newusers = import-csv $SampleCSVPath
foreach ($user in $newusers) {$user|new-smuser}
```

For more examples use the commandlet help
```powershell
Get-Help New-SMUser -examples
```

#### Change a SEPPmail users properties

Change a single User

```powershell
New-SMUser -uid 'cde12348' -email 'u.m@fabrikam.com' -Name 'Ulli Meyer' -customer 'Contoso' -verbose
```

Changing multiple users via CSV import

```powershell
$SampleCSVPath = (Split-Path (Get-Module SEPPmailapi).path) + '\examples\NewUsers.csv'
$changeusers = Import-CSV $SampleCSVPath
foreach ($i in $changeusers) {Set-SMUser -eMailAddress $i.eMailAddress -locked ([boolean]$i.locked)}
```

For more examples use the commandlet help
```powershell
Get-Help New-SMUser -examples
```



--- This is the end of the file ---
