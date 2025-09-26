# Changelog of the SEPPmailAPI PowerShell Module

## Version 2.0.0

***Breaking Changes !!! CmdLet output of Find-CmdLets changes to single objects and lists only the unique identifier of the object***

This release has 3 major areas

1. Expansion of the API-features around:
   - crypto
   - mailsystem/manageddomain/{domainname}/group
   - mailsystem/settings
   - statistics
   - system
   - cluster
  
2. Harmonizing of Output for specific commands

- "Find-" CmdLets always emit the identifier property of an object for further processing.
- "Get-" CmdLets always emit the full object properties of an object
  
1. Appliance Report

The CmdLet New-SMAApplianceReport will provide a summary of an Appliance for documentation or troubleshooting.

### Maintenance

- Updates on API Version
- Better output handling of WEBUsers
- Module expects a multi-customer envrinonment
- Find-SMACustomer now emits a List of customers by default. Get-SMAcustomers -List:$False will emit all customer details
- Find-SMAManageDomains now emits domain-lists only. -List parameter is removed

### Features

- New CmdLet Get-SMALicense returning Appliance License Info and customer statistics

### Bugs

- Typo in Modulename for Secretmanagement
- Output of Get-SMAStatistics without parameters (= defaultvalue all) now emits also user data not only domain data

## Version 1.1.0

Updated Version to fix invalid authenticode signature.

### Maintenance

- Typo and minor logic fixes in the existing code
- removed -customer parameter from Set-SMAUsers bcs. of a possible bug in the current API

## Version 1.0.5

### Additions

- Get-UserKey: This CmdLet lets you retrieve Userkeys (PGP/SMIME)
- Remove-UserKey: This CmdLet lets you retrieve Userkeys (PGP/SMIME)

### Changes

#### Find-SMAUser

- ***Breaking Change***: Find-SMAUser now has the -list parameter default to $true, which means only the e-mail addresses are returned.
- ***Breaking Change***: Removed pipeline capability of Find-SMAUser, because it should be used to query and filter specific users with low DB-impact. For a deeper user analysis use Get-SMAUser, which stays pipeline-aware and emits full objects.
- Add -limit parameter to limit the output of the query. by default its "0" which means no limit, -limit 50 would limit to 50 entries.
- Add -uid parameter to filter for specific UID´s
- Add -partialMatch parameter to filter for parts of the e-mail address. <john.doe@contoso.eu> may be filtered by -partialMatch 'conto' or -emailPattern 'john'
- Add -Name parameter to search for Names (works with parts of the name also) like -Name 'john' ==> <john.doe@contoso.eu>
- Add -active parameter to filter by active or locked users with -active:$true or -active:$false
- Add 4 Parametersets to filter by email, patternMatch, name or uid.
- Add examples in the synopsis to show those examples for Get-Help.

#### New-SMAUser

- Added parameters to fully create a user including:
  - memberof (Group Membership)
  - mailAccountUID (Pop/IMAP User)
  - mailAccountPassword
  - mailAccountHost
  - mailAccountSSL

#### Set-SMAUser

- ***Breaking Change***: All parameters which have been of type [switch] are changed to type [boolean], because handling of $true and $false is easier in the code. So you must set $true or $false to use them.  Parameters are:
  - MayNotSign
  - MayNotEncrypt
  - locked
- Added parameters to fully set a user including:
  - memberOf (Group Membership)
  - mailAccountUID (Pop/IMAP User)
  - mailAccountPassword
  - mailAccountHost
  - mailAccountSSL

#### Remove-SMAUser

- Added the -purge parameter, so the user objects gets really purged from the DB.

## Version 1.0.4

All features of API Version 1.0.2 are implemented.
