#region  Installation

# WINDOWS PowerShell 5.1 : It may be the case you need to set the Executionpolicy (on PS 5.1) AS ADMIN to install modules
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# Install Modules into User-scope (no admin rights needed)
Install-Module Microsoft.PowerShell.Secretmanagement -scope CurrentUser
Install-Module Microsoft.PowerShell.SecretStore -scope CurrentUser
Install-Module SEPPmailAPI -scope CurrentUser

#Import Modules into Memory
Import-Module Microsoft.PowerShell.Secretmanagement
Import-Module Microsoft.PowerShell.SecretStore
Import-Module SEPPmailAPI
#endregion

#region Setting up your first Configuration

## 2 required params SMAHost, and the credential, create Credential Object first
$democred = Get-Credential #APIkey as username, #APISecret as password
New-SMAConfiguration -ConfigurationName 'Demo' -SMAHost 'demo.mydomain.com' -Credential $democred 
## Creates a NEW Vault in SecretStore - store a PWD, i.e. : "$3pPm@il1"
## More Infos on Secrets Modules here: https://www.powershell.co.at/powershell-secrets-management-part-1-introduction/

## For "no password" usage of secretstore do:
Set-SecretStoreConfiguration -Authentication None

## Managing Default and Active Configuration
Set-SMAConfiguration -ConfigurationName Demo -SetAsDefault
Set-SMAConfiguration -ConfigurationName Demo -SetActive

## to reload it
Get-SMAConfiguration -ConfigurationName Demo

# Changing Configuration details
Set-SMAConfiguration -ConfigurationName Demo -SMAPort '8446'
Set-SMAConfiguration -ConfigurationName Demo -SMASkipCertCheck $true
#endregion

#region Using multiple Configurations
$testcred = Get-Credential
New-SMAConfiguration -ConfigurationName 'Test' -SMAHost 'test.mydomain.com' -Credential $testcred
Get-SMAConfiguration -List
Set-SMAConfiguration -ConfigurationName Test -SetActive
Get-SMAConfiguration
Get-SMAConfiguration -List

New-SMAConfiguration -ConfigurationName 'Prod' -SMAHost 'securemail.mydomain.com' -Credential $testcred
Get-SMAConfiguration -List

# -- RESTART PowerShell --
Import-Module SEPPmailAPI
Get-SMAConfiguration
#endregion





