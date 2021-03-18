
$env:psModulepath = $env:psModulepath + ';C:\Users\roman.THEGALAXY\GitRepo'

# Romans AzureBox
$global:SMAHost = "172.16.110.22"
$global:SMAkey = Convertto-SecureString -AsPlainText '17e166f0-0779-4e71-b7ac-05e512a12711' -Force
$global:SMAPort = '8445'
$global:SMAskipCertCheck = $true
$global:SMAPIversion = 'v1'

<# voip
$SMAkey = Convertto-SecureString -AsPlainText '025d5348-2259-4b28-b1da-8a3a40e24d82' -Force
$SMAHost = 'voip.seppmail.de'
$SMAPort = '8445'
$SMAskipCertCheck = $false
#>

#$server = "https://AMZ071030316007.reddog.microsoft.com:8445/v1"


Import-Module SEPPmailAPI -Force

# Test 1 - Create Users

## Create User with minimum parameters

$aa = @{
    uid = 'Andreas.Alpha@nocustomer.local'
    email = 'Andreas.Alpha@nocustomer.com'
    name = 'Andreas Alpha'
}

New-SMAuser @aa
#Pester: uid

## Create User with maximum parameters

$bb = @{
    uid = 'Berta.Bromberg@nocustomer.local'
    email = 'Berta.Bromberg@nocustomer.com'
    name = 'Berta Bromberg'
    password = ('somesecretpw'|Convertto-Securestring -asplaintext -force)
    customer = '[none]'
    maynotencrypt = $false
    maynotsign = $false
    locked = $false
    notifications = 'domain default'
    #mpkiSubjectPart = '/type0=value0'
}

New-SMAuser @bb

## Mass generate Users via CSV

Import-Csv .\test\NewUsers.csv |New-SMAuser

## Modify single users

$modifybb = @{
    email = 'Berta.Bromberg@nocustomer.com'
    name = 'Berta Bärbauer'
    password = ('123somesecretpw§%$'|Convertto-Securestring -asplaintext -force)
    customer = '[none]'
    maynotencrypt = $true
    maynotsign = $true
    locked = $true
    notifications = 'never'
    #mpkiSubjectPart = '/type0=value0'
}

Set-SMAUSer @modifybb

## Mass modify users

Import-Csv .\test\UpdateUsers.csv |ForEach-Object {$_.Locked = [bool]($_.Locked -as [int]); $_ }|Foreach-Object {$_.maynotsign = [bool]($_.maynotsign -as [int]); $_ }|Foreach-Object {$_.maynotencrypt = [bool]($_.maynotencrypt -as [int]); $_ } |Set-SMAuser

'*** Read Users Name and email'
Find-SMAUser

'*** Find-SMAUSer -List'
Find-SMAUser -list

$testcust = 'usertest'
New-SMACustomer -name $testcust

Set-SMAUser -eMail $aa.email -customer $testcust
Set-SMAUser -eMail $bb.email -customer $testcust

Find-SMAuser -customer $testcust

# Read User details
Get-SMAUser -email $aa.email

# Remove User
$aa.email|Remove-SMAUser -keepKeys
$bb.email|Remove-SMAUser

Remove-SMAcustomer -name $testcust

#>













#region customertest
#Find-SMAcustomer

<#
$customerInfo = @{
    name = 'Contoso453'
    backupPassword = 'someReallydifficultPassword456'
    comment = 'Umlaute äöüßÜÄÖ'
    #defaultGINADomain = 'ContosoMain'
    deleteOldMessagesGracePeriod = 11
    deleteUnregistered = 41
    description = 'Contoso ONE Holding AG Moscow 1'
    #mailRoutes = ''
    maximumEncryptionLicenses = 11
    maximumLFTLicenses = 6
    #sendBackupToAdmin = $true
}
#Set-SMACustomer -Name 'Contoso1' @customerInfo
#>
<#
New-SMACustomer @customerInfo
###############################
$customerInfo = @{
    Name = 'Contoso3'
    comment = 'Contoso is one of our most important clients'
    #defaultGINADomain = 'ContosoMain'
    deleteOldMessagesGracePeriod = 30
}
New-SMACustomer @customerInfo
#>
#endregion

Remove-SMACustomer -name 'ContosoImport'

#$encPwd = Convertto-SecureString 'SEPPmailZ!P' -AsPlainText -Force
#Export-SMACustomer -name 'Contoso435' -path '.\contosoLPzipexport.zip' -encryptionpassword $encPwd
#Export-SMACustomer -name Contoso -literalPath 'c:\temp\exporttest\contosoLPzipexport.zip' -encryptionpassword $encPwd

# Import-SMACustomer -name 'ContosoImport' -encryptionPassword $encPwd -literalPath c:\users\roman.Thegalaxy\GitRepo\Contoso453.zip
    

