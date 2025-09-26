# Customer CRUD Operations

BeforeAll {
    $ts = (Get-Date).ToString('yyyyMMddTHHmmss')
    $customerName = "PesterTestCustomer_$ts"
    $script:CapturedInvoke = $null
    Import-Module "$PSScriptRoot/../SEPPmailAPI.psd1" -force -ErrorAction SilentlyContinue | Out-Null
    # 2 GINA Accounts erstellen
}

Describe "New-SMACustomer to create a pester test-customer" {
    Context "Create basic customer entry" {
        It "Returns Customer Name" {
            New-SMACustomer -Name $customerName | Should -be "add for customer $customerName successful" #fixme Customer Name fix in New-SMAcus
        }
    }
    Context "modify customer entry" {
        It "Returns changed customer objects" {
            $changedSettings = @{
                # Customer Details
                Name                         = $customerName
                description                  = "This is a test customer created by Pester on $ts"
                adminEmail                   = 'admin@local'
                comment                      = "This is a test customer COMMET content created by "    
                # Customer administrator
                #$admins           = 10
                # License limiter
                maximumEncryptionLicenses    = 3
                maximumLFTLicenses           = 2
                # Managed domains
                mailroutes                   = @('pestertest.route1.local', 'pestertest.route2.local')
                # Hier fehlen noch Werte
                # Assigned GINA Accounts
                
                # Backup/Restore
                backupPassword               = (ConvertTo-SecureString "BackupP@ssw0rd-$ts" -AsPlainText -Force)
                sendBackupToAdmin            = $true
                defaultGINADomain            = '[default]'
                #retention settings
                deleteOldMessagesGracePeriod = 30
                deleteUnregistered           = 10
            }
            Set-SMACustomer @changedSettings | Should -be "modify for customer $customerName successful"
        }
    }
    <# Add Further options:
    - Global LFT Quota
    - GLQ warn levels
    - GLQ enforce
    - ULFT Quota
    - ULFT Default value
    - GINA Accounts assigned to this customer

    #>
    Context "retrieve customer entry with Find" {
        It "returns a list of customers and $customerName is in the list" {
            Find-SMACustomer | Should -Contain $customerName
        }
    }
    Context "remove customer entry" {
        It "removes the test customer" {
            Remove-SMACustomer -Name $customerName | Should -be "delete for customer $customerName successful"
        }
    }
}
Afterall {
    # Lösche 2 GINA Accounts
    Find-SMACustomer | ForEach-Object { if ($_ -like 'PesterTestCustomer_*') { Remove-SMACustomer -Name $_ -ErrorAction SilentlyContinue | Out-Null } } 

}
# Cleanup: Find-SMACust|foreach {if ($_ -like 'PesterTestCustomer_*') {Remove-SMAcustomer -Name $_}}



