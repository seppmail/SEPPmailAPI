<#
.SYNOPSIS
    Retrieve information about webmail users
.DESCRIPTION
    This CmdLet lets you recieve detailed properties of existing GINA (webmail) users. You can filter the query based on GINA-user properties, see the examples for more)
.EXAMPLE
    PS C:\> Find-SMAGinaUser
.EXAMPLE
    PS C:\> Find-SMAGinaUser -mobile 0049*
    Filter GINA users by mobile phone. Wildcards are allowed
.EXAMPLE
    PS C:\> Find-SMAGinaUser -name Sieg*
    Filter GINA users by mobile phone. Wildcards are allowed

#>
function Find-SMAGinaUser {
    [CmdLetBinding()]
    param(
    
        #region REST-API call path and query parameters
        [Parameter(
            Mandatory                       = $false,
            ValueFromPipeline               = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Enter an e-mail address in correct format i.e. john doe@domain.com'
        )]
        [ValidateNotNullorEmpty()]
        [String]$email,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipeline               = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Enter the GINA user display name (case sensitive). Wildcards are allowed'
        )]
        [ValidateNotNullorEmpty()]
        [alias('DisplayName')]
        [String]$name,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipeline               = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Enter the GINA user display name (case sensitive). Wildcards are allowed'
        )]
        [ValidateNotNullorEmpty()]
        [alias('tenant')]
        [String]$customer,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipeline               = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Enter the GINA users mobile numbner beginning with 00. Wildcards are allowed'
        )]
        [ValidateNotNullorEmpty()]
        [string]$mobile,

        [Parameter(
            Mandatory   = $false,
            HelpMessage = 'Reduce output to email address instead of full dataset of each user'
        )]
        [ValidateNotNullorEmpty()]
        [switch]$list,
        #endregion

        #region Config parameters block
        [Parameter(
            Mandatory = $false
            )]
        [String]$host = $Script:activeCfg.SMAHost,

        [Parameter(
            Mandatory = $false
            )]
        [int]$port = $Script:activeCfg.SMAPort,

        [Parameter(
            Mandatory = $false
            )]
        [String]$version = $Script:activeCfg.SMAPIVersion,

        [Parameter(
            Mandatory=$false
            )]
            [System.Management.Automation.PSCredential]$cred=$Script:activeCfg.SMACred,

        [Parameter(
            Mandatory=$false
            )]
        [switch]$SkipCertCheck=$Script:activeCfg.SMAskipCertCheck
        #endregion
        
    )

    begin {
        if (! (verifyVars -VarList $Script:requiredVarList))
        {
            Throw($missingVarsMessage);
        }
    }
    process {
        try {
            Write-Verbose "Creating URL path"
            $uriPath = "{0}/{1}" -f 'webmail', 'user'

            Write-Verbose "Building full request uri with query parameters"
            $boundParam = @{}
            if ($list) {$boundParam.list = $true}
            if ($customer) {$boundParam.customer = $customer}
            if ($email) {$boundParam.email = $email}
            if ($name) {$boundParam.name = $name}
            if ($mobile) {$boundParam.mobile = $mobile}

            $smaParams = @{
                Host    = $Host
                Port    = $Port
                Version = $Version
            }
            $uri = New-SMAQueryString -uriPath $uriPath -qparam $boundParam @smaParams

            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri 
                Method      = 'GET'
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }
    
            Write-Verbose "Replace wrong '%40' value with '@'"
            $invokeparam.Uri = ($invokeParam.Uri).Replace('%40','@')

            Write-Verbose "Call Invoke-SMARestMethod $($invokeparam.Uri)" 
            $ginaUserRaw = Invoke-SMARestMethod @invokeParam
   
            Write-Verbose 'Converting Umlauts from ISO-8859-1'
            $ginaUser = ConvertFrom-SMAPIFormat -inputObject $GinaUserRaw #|convertfrom-Json -AsHashtable

            # Gina-Userobject
            if ($ginaUser) {
                return $ginaUser
            }
            else {
                Write-Information 'No matching GINA user found, nothing to return'
            }

        }
        catch 
        {
            Write-Error "An error occured, see $error"
        }
    }

}

<#
.SYNOPSIS
    Create a new GINA User
.DESCRIPTION
    This CmdLet lets you create a new GINA User with defined values
.EXAMPLE
    PS C:\> $secpw = 'TheGinaPassword'|ConvertTo-SecureString -AsPlainText -Force
    PS C:\> New-SMAGinaUser -email john.doe@contoso.com -name 'John Doe' -password $secpwd
    These are the minimum values to create a GINA user. Password must be a securestring.
.EXAMPLE
    PS C:\> $ginaParam = @{email='john.doe@contoso.com';name='John Doe';password=$secpwd;}
    PS C:\> New-SMAGinaUser @ginaParam
    To create a Gina User with more than the minimum values, you may add all needed values as parameters. Beginning with a certain amount of values (>4) the use of a parameter hashtable makes sense.
#>
function New-SMAGinaUser {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        #region REST-API Data parameters
        #mandatory params

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'E-mail address of the GINA user'
        )]
        [ValidateNotNullorEmpty()]
        [string]$email,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Full Name (or Display Name)'
        )]
        [ValidateNotNullorEmpty()]
        [string]$name,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'GINA Password as secure string'
        )]
        [ValidateNotNullorEmpty()]
        [secureString]$password,
        
        #non-mandatory params

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Notes why this user has been created (Default: PowerShell Module)'
        )]
        [string]$creationInfo,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Case sensitive tenant/customer name'
        )]
        [string]$customer,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'mobile number beginning with 00 (spaces are allowed inbetween, i.e. 0049 123 456789)'
        )]
        [string]$mobile,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'GINA interface display language'
        )]
        [ValidateSet('d','e','s','i','f')]
        [alias('lg')]
        [string]$language,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Zip attachment allowed ?'
        )]
        [bool]$zipAttachment,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Gina user must change the password at next logon'
        )]
        [bool]$mustChangePassword,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Password reset question, i.e. name of first pet ...'
        )]
        [string]$question,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Password reset answer, i.e. biff ...'
        )]
        [string]$answer,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Active or inactive Gina user ?'
        )]
        [ValidateSet('enabled','disabled')]
        [string]$accountStatus = 'enabled',

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'External Authentication'
        )]
        [bool]$externalAuthentication,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'What password reset options are possible for this GINA user ?'
        )]
        [ValidateSet(
            'Default', 
            'Reset by e-mail verification',
            'Reset by e-mail verification',
            'no reminder question/answer',
            'Reset by hotline',
            'Reset by hotline, no reminder question/answer',
            'Reset by SMS',
            'Reset by SMS, no reminder question/answer',
            'Let user choose between hotline and SMS'
            )]
        [string]$passwordSecurityLevel = 'Default',

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'External Authentication'
        )]
        [string]$authToken,
        #endregion

        #region Host configuration parameters
        [Parameter(Mandatory = $false)]
        [String]$host = $Script:activeCfg.SMAHost,

        [Parameter(Mandatory = $false)]
        [int]$port = $Script:activeCfg.SMAPort,

        [Parameter(Mandatory = $false)]
        [String]$version = $Script:activeCfg.SMAPIVersion,

        [Parameter(
            Mandatory=$false
            )]
            [System.Management.Automation.PSCredential]$cred=$Script:activeCfg.SMACred,

        [Parameter(
                Mandatory=$false
            )]
        [switch]$SkipCertCheck=$Script:activeCfg.SMAskipCertCheck
        #endregion
    )

    begin {
        if (! (verifyVars -VarList $Script:requiredVarList))
        {
            Throw($missingVarsMessage);
        }; # end if

        try {
            Write-Verbose "Creating URL path"
            $uriPath = "{0}/{1}" -f 'webmail', 'user'

            Write-Verbose "Building full request uri"
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }

            $uri = New-SMAQueryString -uriPath $uriPath @smaParams;
        }
        catch {
            Write-Error "Error $error.CategoryInfo occured"
        }
    }
    process {
        try {
            Write-Verbose 'Crafting mandatory $body JSON'
            $bodyHt = @{
                email = $email
                name = $name
                password = $password|ConvertFrom-SecureString -AsPlainText
            }
            Write-Verbose 'Adding ptional values to $body JSON'
            if ($customer) {$bodyHt.customer = $customer}
            if ($creationInfo) {$bodyHt.creationInfo = $creationInfo}
            if ($customer) {$bodyHt.customer = $customer}
            if ($mobile) {$bodyHt.mobile = $mobile}
            if ($language) {$bodyHt.language = $language}
            if ($zipAttachment -ne $null) {$bodyHt.zipAttachment = $zipAttachment}
            if ($mustChangePassword -ne $null) {$bodyHt.mustChangePassword = $mustChangePassword}
            if ($question) {$bodyHt.question = $question}
            if ($answer) {$bodyHt.answer = $answer}
            if ($accountStatus) {$bodyHt.accountStatus = $accountStatus}
            if ($externalAuthentication -ne $null) {$bodyHt.externalAuthentication = $externalAuthentication}
            if ($passwordSecurityLevel) {$bodyHt.passwordSecurityLevel = $passwordSecurityLevel}
            if ($authToken) {$bodyHt.authToken = $authToken}

            $body = $bodyHt|ConvertTo-JSON
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri 
                Method      = 'POST'
                body        = $body
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }

            if ($PSCmdLet.ShouldProcess($($bodyHt.Email),"Create user with e-mail $email")) {
                
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $ginaUserRaw = Invoke-SMARestMethod @invokeParam
                
                return $ginaUserRaw
                #Write-Verbose 'Returning e-Mail address of new users'
                #($ginaUserraw.message -split ' ')[3]
            }
        }
        catch {
            Write-Error "An error occured, see $error"
        }
    }
    end {}
    
}

<#
.SYNOPSIS
    Update an existing GINA User
.DESCRIPTION
    This CmdLet lets you update an existinng GINA User with defined values, i.e. a new password
.EXAMPLE
    PS C:\> $newpw = 'NewGinaPassword'|ConvertTo-SecureString -AsPlainText -Force
    PS C:\> Set-SMAGinaUser -email john.doe@contoso.com -password $secpwd
    Change the password of a Gina user.
.EXAMPLE
    PS C:\> $ginaParam = @{email='john.doe@contoso.com';name='John Doe';password=$newpw;}
    PS C:\> Set-SMAGinaUser @ginaParam
    To update a Gina user with more than >4 values the use of a parameter hashtable makes sense.
#>
function Set-SMAGinaUser {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        #region REST-API Data parameters
        #mandatory params

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'E-mail address of the GINA user'
        )]
        [ValidateNotNullorEmpty()]
        [string]$email,

        #non-mandatory params

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Full Name (or Display Name)'
        )]
        [ValidateNotNullorEmpty()]
        [string]$name,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'GINA Password as secure string'
        )]
        [ValidateNotNullorEmpty()]
        [secureString]$password,
        
        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Case sensitive tenant/customer name'
        )]
        [string]$customer,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'mobile number beginning with 00 (spaces are allowed inbetween, i.e. 0049 123 456789)'
        )]
        [string]$mobile,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'GINA interface display language'
        )]
        [ValidateSet('d','e','s','i','f')]
        [alias('lg')]
        [string]$language = 'd',

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Zip attachment allowed ?'
        )]
        [bool]$zipAttachment,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Gina user must change the password at next logon'
        )]
        [bool]$mustChangePassword,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Password reset question, i.e. name of first pet ...'
        )]
        [string]$question,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Password reset answer, i.e. biff ...'
        )]
        [string]$answer,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Active or inactive Gina user ?'
        )]
        [ValidateSet('enabled','disabled')]
        [string]$accountStatus = 'enabled',

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'External Authentication'
        )]
        [bool]$externalAuthentication,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'What password reset options are possible for this GINA user ?'
        )]
        [ValidateSet(
            'Default', 
            'Reset by e-mail verification',
            'Reset by e-mail verification',
            'no reminder question/answer',
            'Reset by hotline',
            'Reset by hotline, no reminder question/answer',
            'Reset by SMS',
            'Reset by SMS, no reminder question/answer',
            'Let user choose between hotline and SMS'
            )]
        [string]$passwordSecurityLevel = 'Default',

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'External Authentication'
        )]
        [string]$authToken,
        #endregion

        #region Host configuration parameters
        [Parameter(Mandatory = $false)]
        [String]$host = $Script:activeCfg.SMAHost,

        [Parameter(Mandatory = $false)]
        [int]$port = $Script:activeCfg.SMAPort,

        [Parameter(Mandatory = $false)]
        [String]$version = $Script:activeCfg.SMAPIVersion,

        [Parameter(
            Mandatory=$false
            )]
            [System.Management.Automation.PSCredential]$cred=$Script:activeCfg.SMACred,

        [Parameter(
                Mandatory=$false
            )]
        [switch]$SkipCertCheck=$Script:activeCfg.SMAskipCertCheck
        #endregion
    )

    begin {
        if (! (verifyVars -VarList $Script:requiredVarList))
        {
            Throw($missingVarsMessage);
        }; # end if

        try {
            Write-Verbose "Creating URL path"
            $uriPath = "{0}/{1}/{2}" -f 'webmail', 'user', $email

            Write-Verbose "Building full request uri"
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }

            $uri = New-SMAQueryString -uriPath $uriPath @smaParams;
        }
        catch {
            Write-Error "Error $error.CategoryInfo occured"
        }
    }
    process {
        try {
            Write-Verbose 'Crafting mandatory $body JSON'
            $bodyHt = @{
            }
            Write-Verbose 'Adding ptional values to $body JSON'
            if ($name) {$bodyHt.name = $name}
            if ($password) {$bodyHt.password = $password|ConvertFrom-SecureString -AsPlainText}
            if ($customer) {$bodyHt.customer = $customer}
            if ($mobile) {$bodyHt.mobile = $mobile}
            if ($language) {$bodyHt.language = $language}
            if ($zipAttachment -ne $null) {$bodyHt.zipAttachment = $zipAttachment}
            if ($mustChangePassword -ne $null) {$bodyHt.mustChangePassword = $mustChangePassword}
            if ($question) {$bodyHt.question = $question}
            if ($answer) {$bodyHt.answer = $answer}
            if ($accountStatus) {$bodyHt.accountStatus = $accountStatus}
            if ($externalAuthentication -ne $null) {$bodyHt.externalAuthentication = $externalAuthentication}
            if ($passwordSecurityLevel) {$bodyHt.passwordSecurityLevel = $passwordSecurityLevel}
            if ($authToken) {$bodyHt.authToken = $authToken}

            $body = $bodyHt|ConvertTo-JSON
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri 
                Method      = 'PUT'
                body        = $body
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }

            if ($PSCmdLet.ShouldProcess($($bodyHt.Email),"Update user with e-mail $email")) {
                
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $ginaUserRaw = Invoke-SMARestMethod @invokeParam
                
                return $ginaUserRaw
                #Write-Verbose 'Returning e-Mail address of new users'
                #($ginaUserraw.message -split ' ')[3]
            }
        }
        catch {
            Write-Error "An error occured, see $error"
        }
    }
    end {}
    
}

<#
.SYNOPSIS
    Remove an existing GINA User
.DESCRIPTION
    This CmdLet lets you delete an existinng GINA User
.EXAMPLE
    PS C:\> Remove-SMAGinaUser -email john.doe@contoso.com
    Delete Gina user john.doe@contoso.com.
#>
function Remove-SMAGinaUser {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        #region REST-API Data parameters
        #mandatory params

        [Parameter(
                                  Mandatory = $true,
                          ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
                                HelpMessage = 'E-mail address of the GINA user'
        )]
        [ValidateNotNullorEmpty()]
        [string]$eMail,

        [Parameter(
                                  Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
                                HelpMessage = 'Case sensitive tenant/customer name'
        )]
        [string]$customer,
        #endregion

        #region Host configuration parameters
        [Parameter(Mandatory = $false)]
        [String]$host = $Script:activeCfg.SMAHost,

        [Parameter(Mandatory = $false)]
        [int]$port = $Script:activeCfg.SMAPort,

        [Parameter(Mandatory = $false)]
        [String]$version = $Script:activeCfg.SMAPIVersion,

        [Parameter(
            Mandatory=$false
            )]
            [System.Management.Automation.PSCredential]$cred=$Script:activeCfg.SMACred,

        [Parameter(
                Mandatory=$false
            )]
        [switch]$SkipCertCheck=$Script:activeCfg.SMAskipCertCheck
        #endregion
    )

    begin {
        if (! (verifyVars -VarList $Script:requiredVarList))
        {
            Throw($missingVarsMessage);
        }; # end if

        try {
            Write-Verbose "Creating URL path"
            $uriPath = "{0}/{1}/{2}" -f 'webmail', 'user', $email

            Write-Verbose "Building full request uri"
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }

            $uri = New-SMAQueryString -uriPath $uriPath @smaParams;
        }
        catch {
            Write-Error "Error $error.CategoryInfo occured"
        }
    }
    process {
        try {
            Write-Verbose 'Crafting mandatory $body JSON'
            $bodyHt = @{}
            Write-Verbose 'Adding ptional values to $body JSON'
            if ($customer) {$bodyHt.customer = $customer}

            $body = $bodyHt|ConvertTo-JSON
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri           = $uri 
                Method        = 'DELETE'
                body          = $body
                Cred          = $cred
                SkipCertCheck = $SkipCertCheck
            }

            if ($PSCmdLet.ShouldProcess($($bodyHt.Email),"Update user with e-mail $email")) {
                
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $ginaUserRaw = Invoke-SMARestMethod @invokeParam
                
                return $ginaUserRaw
                #Write-Verbose 'Returning e-Mail address of deleted users'
                #($ginaUserraw.message -split ' ')[3]
            }
        }
        catch {
            Write-Error "An error occured, see $error"
        }
    }
    end {}
    
}


Write-Verbose 'Create CmdLet Alias for GINA users' 
$custVerbs = ('New','Remove','Find','Set')

Foreach ($custverb in $custVerbs) {
    $aliasname1 = $custverb + '-SMAGU'
    $cmdName = $custverb + '-SMAGinaUser'
    New-Alias -Name $aliasName1 -Value $cmdName
}



# SIG # Begin signature block
# MIIL1wYJKoZIhvcNAQcCoIILyDCCC8QCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCXCvph6/fwlAg+15O8WELfrW
# LpKggglAMIIEmTCCA4GgAwIBAgIQcaC3NpXdsa/COyuaGO5UyzANBgkqhkiG9w0B
# AQsFADCBqTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDHRoYXd0ZSwgSW5jLjEoMCYG
# A1UECxMfQ2VydGlmaWNhdGlvbiBTZXJ2aWNlcyBEaXZpc2lvbjE4MDYGA1UECxMv
# KGMpIDIwMDYgdGhhd3RlLCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNlIG9ubHkx
# HzAdBgNVBAMTFnRoYXd0ZSBQcmltYXJ5IFJvb3QgQ0EwHhcNMTMxMjEwMDAwMDAw
# WhcNMjMxMjA5MjM1OTU5WjBMMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMdGhhd3Rl
# LCBJbmMuMSYwJAYDVQQDEx10aGF3dGUgU0hBMjU2IENvZGUgU2lnbmluZyBDQTCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJtVAkwXBenQZsP8KK3TwP7v
# 4Ol+1B72qhuRRv31Fu2YB1P6uocbfZ4fASerudJnyrcQJVP0476bkLjtI1xC72Ql
# WOWIIhq+9ceu9b6KsRERkxoiqXRpwXS2aIengzD5ZPGx4zg+9NbB/BL+c1cXNVeK
# 3VCNA/hmzcp2gxPI1w5xHeRjyboX+NG55IjSLCjIISANQbcL4i/CgOaIe1Nsw0Rj
# gX9oR4wrKs9b9IxJYbpphf1rAHgFJmkTMIA4TvFaVcnFUNaqOIlHQ1z+TXOlScWT
# af53lpqv84wOV7oz2Q7GQtMDd8S7Oa2R+fP3llw6ZKbtJ1fB6EDzU/K+KTT+X/kC
# AwEAAaOCARcwggETMC8GCCsGAQUFBwEBBCMwITAfBggrBgEFBQcwAYYTaHR0cDov
# L3QyLnN5bWNiLmNvbTASBgNVHRMBAf8ECDAGAQH/AgEAMDIGA1UdHwQrMCkwJ6Al
# oCOGIWh0dHA6Ly90MS5zeW1jYi5jb20vVGhhd3RlUENBLmNybDAdBgNVHSUEFjAU
# BggrBgEFBQcDAgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgEGMCkGA1UdEQQiMCCk
# HjAcMRowGAYDVQQDExFTeW1hbnRlY1BLSS0xLTU2ODAdBgNVHQ4EFgQUV4abVLi+
# pimK5PbC4hMYiYXN3LcwHwYDVR0jBBgwFoAUe1tFz6/Oy3r9MZIaarbzRutXSFAw
# DQYJKoZIhvcNAQELBQADggEBACQ79degNhPHQ/7wCYdo0ZgxbhLkPx4flntrTB6H
# novFbKOxDHtQktWBnLGPLCm37vmRBbmOQfEs9tBZLZjgueqAAUdAlbg9nQO9ebs1
# tq2cTCf2Z0UQycW8h05Ve9KHu93cMO/G1GzMmTVtHOBg081ojylZS4mWCEbJjvx1
# T8XcCcxOJ4tEzQe8rATgtTOlh5/03XMMkeoSgW/jdfAetZNsRBfVPpfJvQcsVncf
# hd1G6L/eLIGUo/flt6fBN591ylV3TV42KcqF2EVBcld1wHlb+jQQBm1kIEK3Osgf
# HUZkAl/GR77wxDooVNr2Hk+aohlDpG9J+PxeQiAohItHIG4wggSfMIIDh6ADAgEC
# AhBdMTrn+ZR0fTH9F/xerQI2MA0GCSqGSIb3DQEBCwUAMEwxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwx0aGF3dGUsIEluYy4xJjAkBgNVBAMTHXRoYXd0ZSBTSEEyNTYg
# Q29kZSBTaWduaW5nIENBMB4XDTIwMDMxNjAwMDAwMFoXDTIzMDMxNjIzNTk1OVow
# XTELMAkGA1UEBhMCQ0gxDzANBgNVBAgMBkFhcmdhdTERMA8GA1UEBwwITmV1ZW5o
# b2YxFDASBgNVBAoMC1NFUFBtYWlsIEFHMRQwEgYDVQQDDAtTRVBQbWFpbCBBRzCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKE54Nn5Vr8YcEcTv5k0vFyW
# 26kzBt9Pe2UcawfjnyqvYpWeCuOXxy9XXif24RNuBROEc3eqV4EHbA9v+cOrE1me
# 4HTct7byRM0AQCzobeFAyei3eyeDbvb963pUD+XrluCQS+L80n8yCmcOwB+weX+Y
# j2CY7s3HZfbArzTxBHo5AKEDp9XxyoCc/tUQOq6vy+wdbOOfLhrNMkDDCsBWSLqi
# jx3t1E+frAYF7tXaO5/FEGTeb/OjXqOpoooNL38FmCJh0CKby090sBJP5wSienn1
# NdhmBOKRL+0K3bomozoYmQscpT5AfWo4pFQm+8bG4QdNaT8AV4AHPb4zf23bxWUC
# AwEAAaOCAWowggFmMAkGA1UdEwQCMAAwHwYDVR0jBBgwFoAUV4abVLi+pimK5PbC
# 4hMYiYXN3LcwHQYDVR0OBBYEFPKf1Ta/8vAMTng2ZeBzXX5uhp8jMCsGA1UdHwQk
# MCIwIKAeoByGGmh0dHA6Ly90bC5zeW1jYi5jb20vdGwuY3JsMA4GA1UdDwEB/wQE
# AwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzBuBgNVHSAEZzBlMGMGBmeBDAEEATBZ
# MCYGCCsGAQUFBwIBFhpodHRwczovL3d3dy50aGF3dGUuY29tL2NwczAvBggrBgEF
# BQcCAjAjDCFodHRwczovL3d3dy50aGF3dGUuY29tL3JlcG9zaXRvcnkwVwYIKwYB
# BQUHAQEESzBJMB8GCCsGAQUFBzABhhNodHRwOi8vdGwuc3ltY2QuY29tMCYGCCsG
# AQUFBzAChhpodHRwOi8vdGwuc3ltY2IuY29tL3RsLmNydDANBgkqhkiG9w0BAQsF
# AAOCAQEAdszNU8RMB6w9ylqyXG3EjWnvii7aigN0/8BNwZIeqLP9aVrHhDEIqz0R
# u+KJG729SgrtLgc7OenqubaDLiLp7YICAsZBUae3a+MS7ifgVLuDKBSdsMEH+oRu
# N1iGMfnAhykg0P5ltdRlNfDvQlIFiqGCcRaaGVC3fqo/pbPttbW37osyIxTgmB4h
# EWs1jo8uDEHxw5qyBw/3CGkBhf5GNc9mUOHeEBMnzOesmlq7h9R2Q5FaPH74G9FX
# xAG2z/rCA7Cwcww1Qgb1k+3d+FGvUmVGxJE45d2rVj1+alNc+ZcB9Ya9+8jhMssM
# LjhJ1BfzUWeWdZqRGNsfFj+aZskwxjGCAgEwggH9AgEBMGAwTDELMAkGA1UEBhMC
# VVMxFTATBgNVBAoTDHRoYXd0ZSwgSW5jLjEmMCQGA1UEAxMddGhhd3RlIFNIQTI1
# NiBDb2RlIFNpZ25pbmcgQ0ECEF0xOuf5lHR9Mf0X/F6tAjYwCQYFKw4DAhoFAKB4
# MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQB
# gjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkE
# MRYEFPctJGUrdBBQEyfIbGpVgFNISfgQMA0GCSqGSIb3DQEBAQUABIIBAGsYCz3F
# wfanIBr7Xn2R1bzQp6KaG0qrKYq1WgM2PKMG9Ef2GC6ty7oicns5Yu8YKvBdEpxe
# e4KXYRrlbOBi7umiWvl3/3EUcipb8mCluo/bfeguirZvNJCsL2gRirT7fekMS201
# 0Z0bGOjtknoraD9ql9R1nPz7c0UbBZvKX2dGMhHz5wDV4ylJsZQmw6utu1nfoESM
# Ud7Z4NWeTZxOSAqhpMCrHIgabtNrYfECa5Olu1LPSkN/aK0PMcO5i0Et0h//W7SC
# DwE30Xr+VK9Pq/Jgxzo0yMeCzqUuP23wG8Pj7uk7OQcOgHRVv0F1TKrPvem6tVnU
# RV09X4/5whRrK54=
# SIG # End signature block
