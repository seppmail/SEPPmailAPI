<#
.SYNOPSIS
    Get a single locally existing users properties
.DESCRIPTION
    This CmdLet lets you read the detailed properties of an existing user.
.EXAMPLE
    PS C:\> Get-SMAUser 
.EXAMPLE
    PS C:\> Get-SMAUser -eMailAddress 'alice.miller@contoso.com'
    Get information about a SEPPmail user
.EXAMPLE
    PS C:\> Get-SMAUser -eMailAddress 'alice.miller@contoso.com' -Customer 'Contoso'
    Get information about a SEPPmail user of a specific customer
.EXAMPLE
    PS C:\> 'alice.miller@contoso.com','bob.brown@contoso.com'|Get-SMAUser
    Use the pipeline to retrieve users
#>
function Get-SMAUser
{
    [CmdletBinding()]
    param (
        #region REST-API path and query parameters
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'User E-Mail address'
            )]
        [string]$eMail,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'For MSP´s and multi-customer environments, set the GINA users customer'
            )]
        [string]$customer,
        #endregion

        # SMA host parameters
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
    )

    begin {
        if (! (verifyVars -VarList $Script:requiredVarList))
        {
            Throw($missingVarsMessage);
        }; # end if
    }
    process {
        try {
            Write-Verbose "Creating URL path"
            $uriPath = "{0}/{1}" -f 'user', $eMail
    
            Write-Verbose "Building full request uri"
            if ($customer) {
                $boundParam = @{
                    customer = $customer
                }
            }
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
            $uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams
            
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri 
                Method      = 'GET'
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }
    
            Write-Verbose "Call Invoke-SMARestMethod $uri" 
            $UserRaw = Invoke-SMARestMethod @invokeParam
    
            Write-Verbose 'Filter data and return as PSObject'
            $GetUser = $userraw.Psobject.properties.value
    
            Write-Verbose 'Converting Umlauts from ISO-8859-1'
            $user = ConvertFrom-SMAPIFormat -inputObject $Getuser
    
            # Userobject
            if ($User) {
                return $User
            }
            else {
                Write-Information 'Nothing to return'
            }
        }
        catch {
            Write-Error "An error occured, see $error"
        }
    
    }
    end {

    }
}

<#
.SYNOPSIS
    Find a locally existing users and details
.DESCRIPTION
    This CmdLet lets you read the detailed properties of multiple users.
.EXAMPLE
    PS C:\> Find-SMAUser
    Emits all users and their details - may take some time
.EXAMPLE
    PS C:\> Find-SMAUser -List
    Emits all users - mail-addresses only
.EXAMPLE
    PS C:\> Find-SMAUser -customer 'Contoso'
    Emits all users of a particular customer
.EXAMPLE
    PS C:\> Find-SMAUser -customer 'Contoso' -List
    Emits e-mail addresses of all users of a particular customer
#>
function Find-SMAUser
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'For MSP´s and multi-customer environments, limit query for a specific customer'
            )]
        [string]$customer,

        
        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Show list with e-mail address only'
            )]
        [switch]$list,

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
                
    )

    if (! (verifyVars -VarList $Script:requiredVarList))
    {
        Throw($missingVarsMessage);
    }; # end if

    try {
        Write-Verbose "Building full request uri"
        $boundParam = $psCmdLet.MyInvocation.BoundParameters
        $smaParams=@{
            Host=$Host;
            Port=$Port;
            Version=$Version;
        }; # end smaParams

        $uri = New-SMAQueryString -uriPath 'user' -qParam $boundParam @smaParams;

        Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
        $invokeParam = @{
            Uri         = $uri 
            Method      = 'GET'
            Cred        =  $cred
            SkipCertCheck = $SkipCertCheck
        }

        Write-Verbose "Call Invoke-SMARestMethod $uri" 
        $UserRaw = Invoke-SMARestMethod @invokeParam

        Write-Verbose 'Filter data and return as PSObject'

        if ($list) {
            $Finduser = $userraw
        }
        else {
            $FindUser = $userraw.Psobject.properties.value
        }

        Write-Verbose 'Converting Umlauts from ISO-8859-1 and DateTime correctly'
        $user = foreach ($u in $finduser) {ConvertFrom-SMAPIFormat -inputobject $u}

        if ($User) {
            return $User
        }
        else {
            Write-Information 'Nothing to return'
        }

    }
    catch {
        Write-Error "An error occured, see $error"
    }
}

<#
.SYNOPSIS
    Create a new SEPPmail users
.DESCRIPTION
    This CmdLet lets you create a new user. You need at least 3 properties to create a user (name, uid and email)
.EXAMPLE
    PS C:\> New-SMAUser -uid 'm.musterfrau@contoso.com' -email 'm.musterfrau@contoso.com' -Name 'Maria Musterfrau'
    Basic information about a user. uid and email are identical
.EXAMPLE
    PS C:\> $UID = (New-Guid).guid
    PS C:\> New-SMAUser -uid $uid -email 'm.musterfrau@contoso.com' -Name 'Maria Musterfrau'
    Basic information about a user. uid is a GUID
.EXAMPLE
    PS C:\> $userinfo = @{
        uid = '245b8741-4724-4434-8343-bc26c9a10586'
        email = 'm.musterfrau@contoso.com'
        Name = 'Maria Musterfrau'
        locked = $false
        mayNotEncrypt = $false
        mayNotSign = $false
        password = ('aBc1$6tgR'|ConvertTo-SecureString -AsPlainText)
        customer = 'Contoso'
        notifications = 'never'
        mpkiSubjectPart = ''
    }
    PS C:\> New-SMAUser @userInfo
    Example of all parameters possible to create a user using parameter splatting
#>
function New-SMAUser
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Unique ID, mostly the e-Mail address'
            )]
        [string]$uid,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'User E-Mail address'
            )]
        [string]$eMail,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'The users full name'
            )]
        [string]$name,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'You may set the password for the user or leave it blank. API default is blank'
            )]
        [SecureString]$password,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = '!!CASE_SENSITIVE!! For MSP´s, multi-customer and cloud environments, set the users customer, API default is blank'
            )]
        [string]$customer,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Disable the encrypt functionality for the user, API default is $false'
            )]
        [switch]$mayNotEncrypt,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Disable the sign functionality for the user, API default is $false'
            )]
        [switch]$mayNotSign,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Lock this user, API default is $false'
            )]
        [switch]$locked,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Define if and how the user gets notified, API standard is domain default'
            )]
            [ValidateSet('never','always','domain default')]
        [string]$notifications,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Userspecific static subject part'
            )]
        [string]$mpkiSubjectPart,

        # Host configuration parameters
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
    
    )

    begin {
        if (! (verifyVars -VarList $Script:requiredVarList))
        {
            Throw($missingVarsMessage);
        }; # end if

        try {
            Write-Verbose "Building full request uri"
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams

            $uri = New-SMAQueryString -uriPath 'user' @smaParams;
        }
        catch {
            Write-Error "Error $error.CategoryInfo occured"
        }
    }

    process {
        try {
            Write-Verbose 'Crafting mandatory $body JSON'
            $bodyht = @{
                uid = $uid
                name = $name
                email = $email
            }
            Write-Verbose 'Adding Optional values to $body JSON'
                   if ($customer) {$bodyht.customer = $customer}
                     if ($locked) {$bodyht.locked = $locked}
              if ($mayNotEncrypt) {$bodyht.mayNotEncrypt = $mayNotEncrypt}
                 if ($mayNotSign) {$bodyht.mayNotSign = $mayNotSign}
            if ($mpkiSubjectPart) {$bodyht.mpkiSubjectPart = $mpkiSubjectPart}
              if ($notifications) {$bodyht.notifications = $notifications}
                   if ($password) {$bodyht.password = ($password|ConvertFrom-SecureString -asplaintext)}

            
            $body = $bodyht|ConvertTo-JSON
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri 
                Method      = 'POST'
                body        = $body
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }

            if ($PSCmdLet.ShouldProcess($($bodyht.Email),"Create user")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $UserRaw = Invoke-SMARestMethod @invokeParam
                #debug $userraw
                Write-Verbose 'Returning e-Mail address of new users'
                ($userraw.message -split ' ')[3]
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
    Modyfies a SEPPmail user
.DESCRIPTION
    This CmdLet lets you modity an existing user. You need the email address to identify the user.
.EXAMPLE
    PS C:\> Set-SMAUser -email 'm.musterfrau@contoso.com' -Name 'Martha Musterfrau'
    Change the UserName of m.musterfrau@contoso.com
.EXAMPLE
    PS C:\> $userinfo = @{
        email = 'm.musterfrau@contoso.com'
        Name = 'Marithe Musterfrau'
        locked = $true
        mayNotEncrypt = $false
        mayNotSign = $false
        password = 'aBc1$6tgR'
        customer = 'Contoso'
        notifications = 'never'
        mpkiSubjectPart = ''
    }
    PS C:\> Set-SMAUser @userInfo
    Example of all parameters possible to change a user using parameter splatting
#>
function Set-SMAUser
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            #ValueFromPipeline               = $true,
            HelpMessage                     = 'User E-Mail address'
            )]
        [string]$eMail,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'The users full name'
            )]
        [string]$name,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'You may set the password for the user or leave it blank. API default is blank'
            )]
        [SecureString]$password,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = '!!CASE_SENSITIVE!! For MSP´s, multi-customer and cloud environments, set the users customer, API default is blank'
            )]
        [string]$customer,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Disable the encrypt functionality for the user, API default is $false'
            )]
        [switch]$mayNotEncrypt,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Disable the sign functionality for the user, API default is $false'
            )]
        [switch]$mayNotSign,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Lock this user, API default is $false'
            )]
        [switch]$locked,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Define if and how the user gets notified, API standard is domain default'
            )]
        [ValidateSet('never','always','domain default')]
        [string]$notifications,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Userspecific static subject part'
            )]
        [string]$mpkiSubjectPart,

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
    
    )
    begin {
        if (! (verifyVars -VarList $Script:requiredVarList))
        {
            Throw($missingVarsMessage);
        }; # end if
    }
    process {
        try  {
            
            Write-Verbose "Creating URL path"
            $uriPath = "{0}/{1}" -f 'user', $eMail
            Write-Verbose "Building full request uri"
            if ($customer) {
                $boundParam = @{
                    customer = $customer
                }
            }
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams

            $uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams;
            
            Write-Verbose 'Crafting mandatory $body JSON'
            $bodyht = @{
                email = $email
            }
            Write-Verbose 'Adding optional values to $body JSON'
            if ($name) {$bodyht.name = $name}
            if ($customer) {$bodyht.customer = $customer}
            if ((Get-Variable locked).value -eq $false) {$bodyht.locked = $false}
            if ((Get-Variable locked).value -eq $true) {$bodyht.locked = $true}
            if ((Get-Variable mayNotEncrypt).value -eq $false) {$bodyht.mayNotEncrypt = $false}
            if ((Get-Variable mayNotEncrypt).value -eq $true) {$bodyht.mayNotEncrypt = $true}
            if ((Get-Variable mayNotSign).value -eq $false) {$bodyht.mayNotSign = $false}
            if ((Get-Variable mayNotSign).value -eq $true) {$bodyht.mayNotSign = $true}
            if ($mpkiSubjectPart) {$bodyht.mpkiSubjectPart = $mpkiSubjectPart}
            if ($notifications) {$bodyht.notifications = $notifications}
            if ($password) {$bodyht.password = ($password|ConvertFrom-SecureString -asplaintext)}
            
            $body = $bodyht|ConvertTo-JSON
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri 
                Method      = 'PUT'
                body        = $body
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }
            #debug $uri
            if ($PSCmdLet.ShouldProcess($($bodyht.Email),"Change user")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri" 
                $UserRaw = Invoke-SMARestMethod @invokeParam
                #debug $userraw
                Write-Verbose 'Returning e-Mail addresses of updated user'
                ($userraw.message -split ' ')[3]
            }
        }
        catch {
            Write-Error "An error occured, see $error.CategoryInfo"
        }
    }
}

<#
.SYNOPSIS
    Remove a SEPPmail user
.DESCRIPTION
    This CmdLet lets you delete a SEPPmail user. You need the e-Mail address of the user. Optionally it is possible to leave the certificates and keys in the appliance.
.EXAMPLE
    PS C:\> Remove-SMAUser -email 'm.musterfrau@contoso.com'
    Delete a user and all keys and certificates.
.EXAMPLE
    PS C:\> Remove-SMAUser -email 'm.musterfrau@contoso.com' -keepKeys
    Delete a user but leave the keys. If you recreate the user with the same email address, the keys will be re-attached.
#>
function Remove-SMAUser
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'User E-Mail address'
            )]
        [string]$eMail,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'If true certificates and private keys will not be deleted'
            )]
        [switch]$keepKeys,

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

    )

    begin {
        if (! (verifyVars -VarList $Script:requiredVarList))
        {
            Throw($missingVarsMessage);
        }; # end if

        try {
            Write-Verbose "Creating URL path"
            $uriPath = "{0}/{1}" -f 'user', $eMail
        }
        catch {
            Write-Error "Error$.categoryInfo happened"
        }
    }
    process {
        try {
            Write-Verbose "Building full request uri"
            $boundParam = @{
                keepkeys = $keepkeys
            }

            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
            $uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams;
    
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri 
                Method      = 'DELETE'
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
                }
            
            if ($PSCmdLet.ShouldProcess($email,"Remove User")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $UserRaw = Invoke-SMARestMethod @invokeParam
                Write-Verbose 'Returning e-Mail addresses of removed user'
                ($userraw.message -split ' ')[3]
            }
        }
        catch {
            Write-Error "An error occured, see $error.CategoryInfo"
        }
    }
}

# SIG # Begin signature block
# MIIL1wYJKoZIhvcNAQcCoIILyDCCC8QCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8a8QsDfYK7tzqESpa69lY4EO
# G0qggglAMIIEmTCCA4GgAwIBAgIQcaC3NpXdsa/COyuaGO5UyzANBgkqhkiG9w0B
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
# MRYEFB0Y51Y024WVyDS5YMt3YYU8FX7sMA0GCSqGSIb3DQEBAQUABIIBAB5RCWYO
# iCwxsndYxZazRN93DZi0V5SfTQW2TAdR3qcOj0hgei7Qf87IlCk5Qwi2kzag7fq/
# +YCljUv9AH0w416QOwDFbQ2aj1dKBhRRqK1bJAYkB6pt+f5ixC1x/RAAD+no62Dt
# F0Cucco4IBk5+vk9/g08bMCexEdQkmp1nzL8+d9luv0/e/ro5FL0U9dK3uU9QYS9
# CwFDUeodX9cAvlow6cWl+QwM/ZBJy8l9VG9PrebrdvCbhRKuAVqwRiEZU/LImC7w
# NYBBqDkPSabTG/7wfYCp5wZBhF+9psQK9vtJvFsGFl54K2Vfy3EI9oRmHbG85FDe
# m049jQQbid+kig0=
# SIG # End signature block
