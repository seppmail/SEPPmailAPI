Find-SMACustomer
Find-SMACustomer -list

$timeId = (Get-Date -Format FileDateTime).Tolower()
$custId = ('powershell_testcustomer_' + $timeid).ToLower()
$custName = 'PowerShell Test Customer ' + $timeid

New-SMACustomer -name $custId -adminEmail 'admin@local' -admins @('admin@local') -comment $custName -description $custName

$customerSettings = @{
    maximumEncryptionLicenses = 10
           maximumLFTLicenses = 5
}

Set-SMACustomer -name $custId @customerSettings

remove-smacustomer -name $custId



