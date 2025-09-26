BeforeAll {
    $ts = (Get-Date).ToString('ddHHmmssff')
    $userName = "PSPT_$ts@local"
    $userDisplayName = "PSPT $ts"
    $userTestcustomer = "PSPTUsers_$ts"
    New-SMACustomer -name $userTestcustomer | Out-Null
    # Import the module to be tested
    if (Get-Module -Name SEPPmailAPI) {
        Remove-Module SEPPmailAPI -Force
    } else {
        Import-Module "$PSScriptRoot/../SEPPmailAPI.psd1" -force -ErrorAction SilentlyContinue | Out-Null
    }
}

Describe "New-SMAUser to create a pester test-user" {
    Context "Create basic user entry" {
        It "Returns User ID" {
            New-SMAUser -uid $userName -email $userName -name $userDisplayName | Should -Be "$userName"
        }
    }
    Context "retrieve user entry" {
        It "returns the created user object" {
            $user = Get-SMAUser -email $userName -ErrorAction Stop
            $user | Should -Not -BeNullOrEmpty

            $user.uid   | Should -Be $userName
            $user.email | Should -Be $userName
            $user.name  | Should -Be $userName
        }
    }
    Context "Find User entry" {
        It "returns a list of users and $userName is in the list" {
            Find-SMAUser -partialMatch "$ts" | Should -Contain $userName
        }
    }
    Context "modify user entry" {
        It "Returns changed user objects" {
            $changedSettings = @{
                          eMail               = $userName
                          memberOf            = @('backup','logsadmin') # keine Abhängigkeit zu existierenden Gruppen
                          name                = "This is a changed Pester Test User"
                          customer            = $userTestcustomer
                          locked              = $false
                          notifications        = 'always'
                          mailAccountUID      = "pop-$ts@local"
                          mailAccountHost     = 'pop.example.test'
                          mailAccountPassword = (ConvertTo-SecureString "M@il-$ts" -AsPlainText -Force)
                          mailAccountSSL      = $true
                          mayNotEncrypt       = $false
                          mayNotSign          = $true
                          mfaSecret           = 'ABCDEF123456'
                          mfaExemption        = $true
                          #mpkiSubjectPart     = '/type0=value0/type1=value1'
                          mustChangePassword  = $true

            }
            New-SMACustomer -name $userTestcustomer | Out-Null
            Set-SMAUser @changedSettings | Should -Be "$userName"
        }
    }
#        $user = Get-SMAUser -email $email -ErrorAction Stop
#        $user | Should -Not -BeNullOrEmpty
#
#        $user.uid   | Should -Be $uid
#        $user.email | Should -Be $email
#        $user.name  | Should -Be $name

    #Context "modify user entry" {
    #    It "Returns changed user objects" {
    #        $changedSettings = @{
    #                      eMail               = $userName
    #                      memberOf            = @('backup','logsadmin') # keine Abhängigkeit zu existierenden Gruppen
    #                      name                = "This is a changed Pester Test User"
    #                      customer            = $userTestcustomer
    #                      locked              = $false
    #                      notifications        = 'always'
    #                      mailAccountUID      = "pop-$ts@local"
    #                      mailAccountHost     = 'pop.example.test'
    #                      mailAccountPassword = (ConvertTo-SecureString "M@il-$ts" -AsPlainText -Force)
    #                      mailAccountSSL      = $true
    #                      mayNotEncrypt       = $false
    #                      mayNotSign          = $true
    #                      mfaSecret           = 'ABCDEF123456'
    #                      mfaExemption        = $true
    #                      #mpkiSubjectPart     = '/type0=value0/type1=value1'
    #                      mustChangePassword  = $true
#
    #        }
    #        Set-SMAUser @changedSettings | Should -Be "$userName"
    #    }
    #}
    #Context "retrieve user entry with Find" {
    #    It "returns a list of users and $userName is in the list" {
    #        Find-SMAUser | Should -Contain $userName
    #    }
    #}
    #Context "remove user entry" {
    #    It "removes the test user" {
    #        Remove-SMAUser -eMail $userName | Should -Be "delete for user $userName successful"
    #    }
    #}
}

AfterAll {
    Remove-SMACustomer -name $userTestcustomer -ErrorAction SilentlyContinue | Out-Null
    Remove-SMAUser -eMail $userName -ErrorAction SilentlyContinue | Out-Null
}
<#
Import-Module "$PSScriptRoot/../SEPPmailAPI.psd1" -Force

Describe 'New-SMAUser (integration)' -Tag 'Integration','New-SMAUser' {
    # Eindeutige Werte auf Basis des Datums
    $ts    = Get-Date -Format 'yyyyMMdd-HHmmssfff'
    $uid   = "ps-$ts@local"
    $email = $uid
    $name  = "Pester User $ts"

    It 'creates a new user and can retrieve it' {
        { New-SMAUser -uid $uid -email $email -name $name -ErrorAction Stop } | Should -Not -Throw

        $user = Get-SMAUser -email $email -ErrorAction Stop
        $user | Should -Not -BeNullOrEmpty

        $user.uid   | Should -Be $uid
        $user.email | Should -Be $email
        $user.name  | Should -Be $name
    }

    It 'creates a new user with all supported properties' {
        # Werte für alle (bekannten) optionalen Eigenschaften
        $customer        = 'Contoso'
        $locked          = $false
        $mayNotEncrypt   = $false
        $mayNotSign      = $true
        $notifications   = 'never'          # ggf. an erlaubte Werte anpassen
        $mpkiSubjectPart = 'STATIC'
        $memberOf        = @()              # keine Abhängigkeit zu existierenden Gruppen
        $mailAccountUID  = "pop-$ts@local"
        $mailAccountHost = 'pop.example.test'
        $mailAccountSSL  = $true
        $mustChangePwd   = $true

        # Passwörter als SecureString (Cmdlet wandelt intern in Klartext um)
        $plainPwd        = "P@ss-$ts"
        $plainMailPwd    = "M@il-$ts"
        $password        = ConvertTo-SecureString $plainPwd -AsPlainText -Force
        $mailAccountPassword = ConvertTo-SecureString $plainMailPwd -AsPlainText -Force

        # Felder, die laut Code/Kommentare evtl. (noch) nicht von der API verarbeitet werden
        $mfaExemption    = $false
        $mfaSecret       = 'ABCDEF123456'

        { 
            New-SMAUser `
                -uid $uid -email $email -name $name `
                -customer $customer `
                -locked:$locked `
                -mayNotEncrypt:$mayNotEncrypt `
                -mayNotSign:$mayNotSign `
                -notifications $notifications `
                -password $password `
                -mpkiSubjectPart $mpkiSubjectPart `
                -memberOf $memberOf `
                -mailAccountUID $mailAccountUID `
                -mailAccountPassword $mailAccountPassword `
                -mailAccountHost $mailAccountHost `
                -mailAccountSSL:$mailAccountSSL `
                -mustChangePassword:$mustChangePwd `
                -mfaExemption:$mfaExemption `
                -mfaSecret $mfaSecret `
                -ErrorAction Stop
        } | Should -Not -Throw

        $user = Get-SMAUser -email $email -ErrorAction Stop
        $user | Should -Not -BeNullOrEmpty

        # Pflichtfelder
        $user.uid   | Should -Be $uid
        $user.email | Should -Be $email
        $user.name  | Should -Be $name

        # Optionale Felder (nur prüfen, wenn sie zurückgeliefert werden)
        if ($user.PSObject.Properties.Name -contains 'customer')        { $user.customer        | Should -Be $customer }
        if ($user.PSObject.Properties.Name -contains 'locked')          { $user.locked          | Should -Be $locked }
        if ($user.PSObject.Properties.Name -contains 'mayNotEncrypt')   { $user.mayNotEncrypt   | Should -Be $mayNotEncrypt }
        if ($user.PSObject.Properties.Name -contains 'mayNotSign')      { $user.mayNotSign      | Should -Be $mayNotSign }
        if ($user.PSObject.Properties.Name -contains 'notifications')   { $user.notifications   | Should -Be $notifications }
        if ($user.PSObject.Properties.Name -contains 'mpkiSubjectPart') { $user.mpkiSubjectPart | Should -Be $mpkiSubjectPart }
        if ($user.PSObject.Properties.Name -contains 'memberOf')        { ($user.memberOf ?? @()) | Should -BeOfType 'System.Object[]' }
        if ($user.PSObject.Properties.Name -contains 'mailAccountUID')  { $user.mailAccountUID  | Should -Be $mailAccountUID }
        if ($user.PSObject.Properties.Name -contains 'mailAccountHost') { $user.mailAccountHost | Should -Be $mailAccountHost }
        if ($user.PSObject.Properties.Name -contains 'mailAccountSSL')  { $user.mailAccountSSL  | Should -Be $mailAccountSSL }
        if ($user.PSObject.Properties.Name -contains 'mustChangePassword') { $user.mustChangePassword | Should -Be $mustChangePwd }

        # Hinweis: Passwörter/MFA-Werte werden i. d. R. nicht im Klartext zurückgegeben – daher keine strikten Asserts
    }

    AfterAll {
        try {
            Remove-SMAUser -email $email -ErrorAction SilentlyContinue | Out-Null
        } catch {

        #>