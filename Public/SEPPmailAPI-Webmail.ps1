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
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'E-mail address of the GINA user'
        )]
        [ValidateNotNullorEmpty()]
        [string]$email,

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
            $bodyHt = @{
            }
            Write-Verbose 'Adding ptional values to $body JSON'
            if ($customer) {$bodyHt.customer = $customer}

            $body = $bodyHt|ConvertTo-JSON
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                  Uri         = $uri 
                  Method      = 'DELETE'
                  body        = $body
                  Cred        = $cred
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
$custVerbs = ('New','Remove','Get','Find','Set')

Foreach ($custverb in $custVerbs) {
    $aliasname1 = $custverb + '-SMAGU'
    $cmdName = $custverb + '-SMAGinaUser'
    New-Alias -Name $aliasName1 -Value $cmdName
}


