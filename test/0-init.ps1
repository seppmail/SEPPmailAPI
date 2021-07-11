Import-Module ~\gitrepo\SEPPmailAPI\SEPPmailAPI.psd1 -force

$smaTestCred = New-Object -TypeName pscredential -ArgumentList ('l19nftTsxXOIdP8VDzZVO26uRNs0qeFn',(Convertto-Securestring -String 'w0Y6qurobTNVGunbzE1sEJl0dK2yq2j7' -AsPlainText))
$RsPsAzureVm = @{
    ConfigurationName = 'smaTest'
    SMAHost = '172.16.110.22'
    # SMAPort = '8445'
    Credential = $smaTestCred
    SMASkipCertCheck = $true
}

New-SMAConfiguration @RsPsAzureVm

Set-SMAConfiguration -ConfigurationName 'smaTest' -SetAsDefault
Set-SMAConfiguration -ConfigurationName 'smaTest' -SetActive

[String]$TestNum = "{0:s}" -f (Get-Date) -replace ':',''

#Region create customer for Tests

# Create a new Customer for tests
$secBackupPwd = ConvertTo-Securestring -String 'someReallydifficultPassword456' -AsPlainText -Force
$customerInfo = @{
    name = $testNum + 'Contoso'
    backupPassword = $secBackupPwd
    comment = 'Umlaute äöüßÜÄÖ'
    #defaultGINADomain = 'ContosoMain'
    deleteOldMessagesGracePeriod = 11
    deleteUnregistered = 41
    description = "ContosoTest Customer of testrun $TestNum"
    #mailRoutes = ''
    maximumEncryptionLicenses = 11
    maximumLFTLicenses = 6
    #sendBackupToAdmin = $true
}
New-SMACustomer @customerinfo

# Change that Customer
$NewSecBackupPwd = ConvertTo-Securestring -String '123someReallydifficultPassword' -AsPlainText -Force

$customerInfo = @{
    name = $testNum + 'Contoso'
    backupPassword = $NewSecBackupPwd
    comment = 'New Comment written'
    defaultGINADomain = '[default]'
    deleteOldMessagesGracePeriod = 12
    deleteUnregistered = 30
    description = "ContosoTest Customer of testrun $TestNum"
    #mailRoutes = ''
    maximumEncryptionLicenses = 4
    maximumLFTLicenses = 2
    sendBackupToAdmin = $true
}

Set-SMACustomer @customerInfo

# Export customer
$TestCustomer = $TestNum + 'Contoso'
$ZipPwd = ConvertTo-Securestring -String '3xporT' -AsPlainText -Force
$ZipFileName = $testNum + '.zip'
$ZipPath = Join-Path -Path $env:temp -ChildPath $ZipFileName
Export-SMACustomer -name $TestCustomer -encryptionPassword $ZipPwd -path $ZipPath

# Remove-Customer
Remove-SMACustomer -name $TestCustomer

# Import Customer
Import-SMACustomer -name $TestCustomer -path $ZipPath -encryptionPassword $ZipPwd


#endregion





