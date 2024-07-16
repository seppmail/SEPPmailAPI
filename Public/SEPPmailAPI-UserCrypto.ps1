<#
.SYNOPSIS
    Get the S/MIME or PGP Keys of a single locally existing users
.DESCRIPTION
    This CmdLet lets you read one or all keys of an existing user.
.EXAMPLE
    PS C:\> Get-SMAUserKey -eMail 'alice.miller@contoso.com'
    Gets all available keys for a user and shows all details
.EXAMPLE
    PS C:\> Get-SMAUserKey -eMail 'alice.miller@contoso.com' -technology pgp
    Gets pgp keys for a user and shows all details
.EXAMPLE
    PS C:\> Get-SMAUserKey -eMail 'alice.miller@contoso.com' -technology smime -list:$true
    Gets pgp keys for a user and shows the key only.
.EXAMPLE
    PS C:\> Get-SMAUserKey -eMail 'alice.miller@contoso.com' -limit 2
    Gets all keys for a user and shows only 2 keys.
#>
function Get-SMAUserKey
{
    [CmdletBinding()]
    param (
        #region REST-API path and query parameters
        [Parameter(
            ParameterSetName                = 'email',
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'User E-Mail address'
            )]
        [Parameter(
            ParameterSetName                = 'keyid',
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'User E-Mail address'
            )]            
        [string]$eMail,

        [Parameter(
            ParameterSetName                = 'keyid',
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'Keys id or serial number'
            )]
        [Alias('serial','keyid')]
        [string]$key,
    
        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'Show an array of names instead details'
            )]
        [Boolean]$list = $false,

        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'limit output to <n> objects' 
            )]
        [int]$limit = 0,

        [Parameter(
            Mandatory                   = $false,
            HelpMessage                 = 'specify the keytype you want to see (default both)'
            )]
        [ValidateSet('pgp','smime','both')]
        [string]$technology = 'both',

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'The password for the key'
            )]
        [SecureString]$password,
        #endregion

        #region SMA host parameters
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
        }; # end if
    }
    process {
        try {
            Write-Verbose "Creating URL path"
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('key')) {
                $uriPath = "{0}/{1}/{2}/{3}" -f 'crypto','user', $eMail, 'serial_or_key'
            } else {
                $uriPath = "{0}/{1}/{2}" -f 'crypto','user', $eMail
            }
    
            # Build querystring hashtable for conversion from parameters. Boundparams are eiter mandatory or have default values
            $boundParam = @{
                      'list' = $list
                     'limit' = $limit
                'technology' = $technology
            }

                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('password')) {$boundParam.password = (ConverFrom-SecureString -securestring $password -asplaintext)}
                     if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('uid')) {$boundParam.uid = $uid}


            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
            $uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams
            
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri           = $uri 
                Method        = 'GET'
                Cred          =  $cred
                SkipCertCheck = $SkipCertCheck
            }
    
            Write-Verbose "Call Invoke-SMARestMethod $uri" 
            $userKeyRaw = Invoke-SMARestMethod @invokeParam
            <#
            Write-Verbose 'Filter data and return as PSObject'
            $GetUserKey = $userKeyRaw.Psobject.properties.value
    
            Write-Verbose 'Converting Umlauts from ISO-8859-1'
            $userKey = ConvertFrom-SMAPIFormat -inputObject $getUserKey
            #>
            # Userobject
            if ($UserKeyRaw) {
                return $userKeyRaw
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
    Remove the S/MIME or PGP Keys of a single locally existing users
.DESCRIPTION
    This CmdLet lets you read one or all keys of an existing user. Based on API /crypto/user/{email}/{serial_or_keyid}
.EXAMPLE
    PS C:\> Remove-SMAUserKey -eMail 'alice.miller@contoso.com' -Key '0x9FA4185B8B094759F8215E5'
    Removes a Key, but doesnt delete it and revokes the certificate
.EXAMPLE
    PS C:\> Remove-SMAUserKey -eMail 'alice.miller@contoso.com' -Key '0x9FA4185B8B094759F8215E5' -revoke:$false
    Removes a Key, but doesnt delete it and also doesnt revoke the certificate
.EXAMPLE
    PS C:\> Remove-SMAUserKey -eMail 'alice.miller@contoso.com' -Key '0x9FA4185B8B094759F8215E5'
    Removes a Key, but deletes it and also revokes the certificate
#>
function Remove-SMAUserKey
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
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'Keys id or serial number (SMIME 0x9FA4185B8B094759F8215E5), (PGP CE80994BA881F424)'
            )]
        [Alias('serial','keyid')]
        [string]$key,
    
        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'Revoke the certificate'
            )]
        [Boolean]$revoke = $true,

        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'Delete the key finally' 
            )]
        [Boolean]$delete = $false,

        #endregion

        #region SMA host parameters
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
        }; # end if
    }
    process {
        try {
            Write-Verbose "Creating URL path"
            $uriPath = "{0}/{1}/{2}/{3}" -f 'crypto','user', $eMail, 'serial_or_key'
    
            # Build querystring hashtable for conversion from parameters. Boundparams are eiter mandatory or have default values
            $boundParam = @{}

            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('delete')) {$boundParam.delete = $delete}
            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('revoke')) {$boundParam.revoke = $revoke}

            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
            $uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams
            
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri           = $uri 
                Method        = 'DELETE'
                Cred          = $cred
                SkipCertCheck = $SkipCertCheck
            }
    
            Write-Verbose "Call Invoke-SMARestMethod $uri" 
            $DeleteKey = Invoke-SMARestMethod @invokeParam
            <#
            Write-Verbose 'Filter data and return as PSObject'
            $GetUserKey = $userKeyRaw.Psobject.properties.value
    
            Write-Verbose 'Converting Umlauts from ISO-8859-1'
            $userKey = ConvertFrom-SMAPIFormat -inputObject $getUserKey
            #>
            # Userobject
            if ($DeleteKey) {
                return $DeleteKey
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
