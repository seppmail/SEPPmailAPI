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
# MIIVzAYJKoZIhvcNAQcCoIIVvTCCFbkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC/Z0TCB56kb6H1
# h3LjJ/BcTgH3MQwpfBQ+v1xr1OerO6CCEggwggVvMIIEV6ADAgECAhBI/JO0YFWU
# jTanyYqJ1pQWMA0GCSqGSIb3DQEBDAUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# DBJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoM
# EUNvbW9kbyBDQSBMaW1pdGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2Vy
# dmljZXMwHhcNMjEwNTI1MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjBWMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYDVQQDEyRTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCN55QSIgQkdC7/FiMCkoq2rjaFrEfUI5ErPtx94jGgUW+s
# hJHjUoq14pbe0IdjJImK/+8Skzt9u7aKvb0Ffyeba2XTpQxpsbxJOZrxbW6q5KCD
# J9qaDStQ6Utbs7hkNqR+Sj2pcaths3OzPAsM79szV+W+NDfjlxtd/R8SPYIDdub7
# P2bSlDFp+m2zNKzBenjcklDyZMeqLQSrw2rq4C+np9xu1+j/2iGrQL+57g2extme
# me/G3h+pDHazJyCh1rr9gOcB0u/rgimVcI3/uxXP/tEPNqIuTzKQdEZrRzUTdwUz
# T2MuuC3hv2WnBGsY2HH6zAjybYmZELGt2z4s5KoYsMYHAXVn3m3pY2MeNn9pib6q
# RT5uWl+PoVvLnTCGMOgDs0DGDQ84zWeoU4j6uDBl+m/H5x2xg3RpPqzEaDux5mcz
# mrYI4IAFSEDu9oJkRqj1c7AGlfJsZZ+/VVscnFcax3hGfHCqlBuCF6yH6bbJDoEc
# QNYWFyn8XJwYK+pF9e+91WdPKF4F7pBMeufG9ND8+s0+MkYTIDaKBOq3qgdGnA2T
# OglmmVhcKaO5DKYwODzQRjY1fJy67sPV+Qp2+n4FG0DKkjXp1XrRtX8ArqmQqsV/
# AZwQsRb8zG4Y3G9i/qZQp7h7uJ0VP/4gDHXIIloTlRmQAOka1cKG8eOO7F/05QID
# AQABo4IBEjCCAQ4wHwYDVR0jBBgwFoAUoBEKIz6W8Qfs4q8p74Klf9AwpLQwHQYD
# VR0OBBYEFDLrkpr/NZZILyhAQnAgNpFcF4XmMA4GA1UdDwEB/wQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBsGA1UdIAQUMBIwBgYE
# VR0gADAIBgZngQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21v
# ZG9jYS5jb20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEE
# KDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZI
# hvcNAQEMBQADggEBABK/oe+LdJqYRLhpRrWrJAoMpIpnuDqBv0WKfVIHqI0fTiGF
# OaNrXi0ghr8QuK55O1PNtPvYRL4G2VxjZ9RAFodEhnIq1jIV9RKDwvnhXRFAZ/ZC
# J3LFI+ICOBpMIOLbAffNRk8monxmwFE2tokCVMf8WPtsAO7+mKYulaEMUykfb9gZ
# pk+e96wJ6l2CxouvgKe9gUhShDHaMuwV5KZMPWw5c9QLhTkg4IUaaOGnSDip0TYl
# d8GNGRbFiExmfS9jzpjoad+sPKhdnckcW67Y8y90z7h+9teDnRGWYpquRRPaf9xH
# +9/DUp/mBlXpnYzyOmJRvOwkDynUWICE5EV7WtgwggYaMIIEAqADAgECAhBiHW0M
# UgGeO5B5FSCJIRwKMA0GCSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENv
# ZGUgU2lnbmluZyBSb290IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5
# NTlaMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzAp
# BgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0G
# CSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjI
# ztNsfvxYB5UXeWUzCxEeAEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NV
# DgFigOMYzB2OKhdqfWGVoYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/3
# 6F09fy1tsB8je/RV0mIk8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05Zw
# mRmTnAO5/arnY83jeNzhP06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm
# +qxp4VqpB3MV/h53yl41aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUe
# dyz8rNyfQJy/aOs5b4s+ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz4
# 4MPZ1f9+YEQIQty/NQd/2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBM
# dlyh2n5HirY4jKnFH/9gRvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQY
# MBaAFDLrkpr/NZZILyhAQnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritU
# pimqF6TNDDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNV
# HSUEDDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsG
# A1UdHwREMEIwQKA+oDyGOmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1
# YmxpY0NvZGVTaWduaW5nUm9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsG
# AQUFBzAChjpodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2Rl
# U2lnbmluZ1Jvb3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0
# aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURh
# w1aVcdGRP4Wh60BAscjW4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0Zd
# OaWTsyNyBBsMLHqafvIhrCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajj
# cw5+w/KeFvPYfLF/ldYpmlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNc
# WbWDRF/3sBp6fWXhz7DcML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalO
# hOfCipnx8CaLZeVme5yELg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJs
# zkyeiaerlphwoKx1uHRzNyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z7
# 6mKnzAfZxCl/3dq3dUNw4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5J
# KdGvspbOrTfOXyXvmPL6E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHH
# j95Ejza63zdrEcxWLDX6xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2
# Bev6SivBBOHY+uqiirZtg0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/
# L9Uo2bC5a4CH2RwwggZzMIIE26ADAgECAhAMcJlHeeRMvJV4PjhvyrrbMA0GCSqG
# SIb3DQEBDAUAMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0
# ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYw
# HhcNMjMwMzIwMDAwMDAwWhcNMjYwMzE5MjM1OTU5WjBqMQswCQYDVQQGEwJERTEP
# MA0GA1UECAwGQmF5ZXJuMSQwIgYDVQQKDBtTRVBQbWFpbCAtIERldXRzY2hsYW5k
# IEdtYkgxJDAiBgNVBAMMG1NFUFBtYWlsIC0gRGV1dHNjaGxhbmQgR21iSDCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOapobQkNYCMP+Y33JcGo90Soe9Y
# /WWojr4bKHbLNBzKqZ6cku2uCxhMF1Ln6xuI4ATdZvm4O7GqvplG9nF1ad5t2Lus
# 5SLs45AYnODP4aqPbPU/2NGDRpfnceF+XhKeiYBwoIwrPZ04b8bfTpckj/tvenB9
# P8/9hAjWK97xv7+qsIz4lMMaCuWZgi8RlP6XVxsb+jYrHGA1UdHZEpunEFLaO9Ss
# OPqatPAL2LNGs/JVuGdq9p47GKzn+vl+ANd5zZ/TIP1ifX76vorqZ9l9a5mzi/HG
# vq43v2Cj3jrzIQ7uTbxtiLlPQUqkRzPRtiwTV80JdtRE+M+gTf7bT1CTvG2L3scf
# YKFk7S80M7NydxV/qL+l8blGGageCzJ8svju2Mo4BB+ALWr+gBmCGqrM8YKy/wXR
# tbvdEvBOLsATcHX0maw9xRCDRle2jO+ndYkTKZ92AMH6a/WdDfL0HrAWloWWSg62
# TxmJ/QiX54ILQv2Tlh1Al+pjGHN2evxS8i+XoWcUdHPIOoQd37yjnMjCN593wDzj
# XCEuDABYw9BbvfSp29G/uiDGtjttDXzeMRdVCJFgULV9suBVP7yFh9pK/mVpz+aC
# L2PvqiGYR41xRBKqwrfJEdoluRsqDy6KD985EdXkTvdIFKv0B7MfbcBCiGUBcm1r
# fLAbs8Q2lqvqM4bxAgMBAAGjggGpMIIBpTAfBgNVHSMEGDAWgBQPKssghyi47G9I
# ritUpimqF6TNDDAdBgNVHQ4EFgQUL96+KAGrvUgJnXwdVnA/uy+RlEcwDgYDVR0P
# AQH/BAQDAgeAMAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwSgYD
# VR0gBEMwQTA1BgwrBgEEAbIxAQIBAwIwJTAjBggrBgEFBQcCARYXaHR0cHM6Ly9z
# ZWN0aWdvLmNvbS9DUFMwCAYGZ4EMAQQBMEkGA1UdHwRCMEAwPqA8oDqGOGh0dHA6
# Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1YmxpY0NvZGVTaWduaW5nQ0FSMzYu
# Y3JsMHkGCCsGAQUFBwEBBG0wazBEBggrBgEFBQcwAoY4aHR0cDovL2NydC5zZWN0
# aWdvLmNvbS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdDQVIzNi5jcnQwIwYIKwYB
# BQUHMAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28uY29tMB4GA1UdEQQXMBWBE3N1cHBv
# cnRAc2VwcG1haWwuY2gwDQYJKoZIhvcNAQEMBQADggGBAHnWpS4Jw/QiiLQi2EYv
# THCtwKsj7O3G7wAN7wijSJcWF7iCx6AoCuCIgGdWiQuEZcv9pIUrXQ6jOSRHsDNX
# SvIhCK9JakZJSseW/SCb1rvxZ4d0n2jm2SdkWf5j7+W+X4JHeCF9ZOw0ULpe5pFs
# IGTh8bmTtUr3yA11yw4vHfXFwin7WbEoTLVKiL0ZUN0Qk+yBniPPSRRlUZIX8P4e
# iXuw7lh9CMaS3HWRKkK89w//18PjUMxhTZJ6dszN2TAfwu1zxdG/RQqvxXUTTAxU
# JrrCuvowtnDQ55yXMxkkSxWUwLxk76WvXwmohRdsavsGJJ9+yxj5JKOd+HIZ1fZ7
# oi0VhyOqFQAnjNbwR/TqPjRxZKjCNLXSM5YSMZKAhqrJssGLINZ2qDK/CEcVDkBS
# 6Hke4jWMczny8nB8+ATJ84MB7tfSoXE7R0FMs1dinuvjVWIyg6klHigpeEiAaSaG
# 5KF7vk+OlquA+x4ohPuWdtFxobOT2OgHQnK4bJitb9aDazGCAxowggMWAgEBMGgw
# VDELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDErMCkGA1UE
# AxMiU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5nIENBIFIzNgIQDHCZR3nkTLyV
# eD44b8q62zANBglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3AgEMMQowCKACgACh
# AoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAM
# BgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDwBEA4ZMoATdS4/NRaLGeSzrmJ
# iQXB88WwfFT5dikhWjANBgkqhkiG9w0BAQEFAASCAgBqQLa1BdW5atE2ZDRY/+0S
# +6nAM6HGM/V/EqwbIJgwQkPUfzIR9+qODg1d6y3/wUvakST6TCWvcKK660X6KsvF
# s3saMuLJrWUU47vCiQP30AqBRn4ybBQXan1RaHtbAHAbaIo6aqCsse98HEGfhbgi
# 42L0+bBychQCn9uIU+VWM3hNdFMPwuwmdRdTovMk5aVblCts6ZGLy/NHgIOrDyK+
# FxM3MwSip1Mt1tXqDJqwG3CPOC2ACxIx0yMb46hIe7Im2Fi4DB2IPTlhqg6oQwrx
# QAQb9i6nlW/dcaSkwyGOYc7S+DB3M1/MsZnAwJk8CPMaUAPC1oBA2iwCfO85cGkr
# pR1aFzmHANI91xfvHCOe0sY4qHlaIx3K8H5xJdnN5nQvmiO52D/QwABKBjT0qSTJ
# +LF+Rkdt86CYXPNjrq/4e5NnhKgRSoyCpT1G6Ve86J05C5G+SPmPfDigxkZJGU2p
# u+07ANDA9RAm9ffhlX8S4iLpVT8rz2aKZsoHH74+0TQbmMDXHwlmA2Aofdqso+3C
# RK8s19Oj/yz45BXjKtdtPr/kBNOWk3x0XO2PC1MmIvA1sXuB8VVldvHfPskVU0C4
# eb2d6Wh7R8wxnSUwAojKCOjHvUHpLhetALCJCTNFSxHjRhoZnl9j7dAiDhsjodsY
# fWYMJmTuYzQpRYVnlKn3+Q==
# SIG # End signature block
