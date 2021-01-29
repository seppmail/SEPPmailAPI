$ModulePath = Split-Path ((Get-Module -Name SEPPmailAPI -Listavailable).Path) 
. $ModulePath\Private\SEPPmailAPIPrivate.ps1
. $ModulePath\Public\SEPPmailAPICmdLets.ps1
