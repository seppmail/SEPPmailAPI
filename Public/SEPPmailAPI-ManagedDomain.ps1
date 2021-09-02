<#
.SYNOPSIS
Find managed domains, either by name or the customer it belongs to.
.DESCRIPTION
This CmdLet lets you read the detailed properties of multiple users.
.EXAMPLE
    PS C:\> Find-SMAManagedDomain
    Emits all managed domains and their details - may take some time
.EXAMPLE
    PS C:\> Find-SMAManagedDomain -List
    Emits all domain names
#>
function Find-SMAManagedDomain
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'Show list with domain names only'
            )]
        [switch]$list,

        [Parameter(
             Mandatory = $false,
             HelpMessage = "Limit output to a specific domain"
         )]
        [string] $name,

        [Parameter(
             Mandatory = $false,
             HelpMessage = "Limit output to domains of a specific customer"
         )]
        [string] $customer,

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


    if (!(verifyVars -VarList $Script:requiredVarList))
    {
        Throw($missingVarsMessage);
    }; # end if

    try {
        Write-Verbose "Creating URL Path"
        $uriPath = 'mailsystem/manageddomain'

        Write-verbose "Build Parameter hashtable"
        $boundParam = @{}

        if($list)
        {$boundParam["list"] = $true}
        if($name)
        {$boundParam["domainName"] = $name}
        if($customer)
        {$boundParam["customer"] = $customer}

        Write-Verbose "Build QueryString"
        $smaParams=@{
            Host=$Host;
            Port=$Port;
            Version=$Version;
        }; # end smaParams
        $uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams;

        Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
        $invokeParam = @{
            Uri         = $uri
            Method      = 'GET'
            Cred        =  $cred
            SkipCertCheck = $SkipCertCheck
        }

        Write-Verbose "Call Invoke-SMARestMethod $uri"
        $tmp = Invoke-SMARestMethod @invokeParam

        Write-Verbose 'Filter data and return as PSObject'

        if (!$list) {
            $tmp = $tmp.Psobject.properties.value
        }

        Write-Verbose 'Converting Umlauts from ISO-8859-1 and DateTime correctly'
        $ret = foreach ($c in $tmp) {ConvertFrom-SMAPIFormat -inputobject $c}

        if ($ret) {
            return $ret
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
    Get information about a specific managed domain
.DESCRIPTION
    This CmdLet lets you read the detailed properties of an existing managed domain.
.EXAMPLE
    PS C:\> Get-SMAManagedDomain -name 'example.com'
    Get information about a managed domain.
.EXAMPLE
    PS C:\> 'example1.com','example2.com'|Get-SMAManagedDomain
    Use the pipeline to query multiple domains.
#>
function Get-SMAManagedDomain
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'Domain name'
            )]
        [ValidatePattern('^((?!-)[A-Za-z0-9\-]{1,63}(?<!-)\.)+[A-Za-z]{2,6}$')]
        [string]$name,

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
        try {
            Write-Verbose "Creating URL Path"
            $uriPath = "{0}" -f 'mailsystem/manageddomain'

            Write-Verbose "Build QueryString"
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
            $uri = New-SMAQueryString -uriPath $uriPath @smaParams -qParam @{domainName = $name}

            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri
                Method      = 'GET'
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }
            Write-Verbose "Call Invoke-SMARestMethod $uri"
            $tmp = Invoke-SMARestMethod @invokeParam

            Write-Verbose 'Filter data and return as PSObject'
            $ret = $tmp.Psobject.properties.value

            Write-Verbose 'Converting Umlauts from ISO-8859-1'
            $ret = ConvertFrom-SMAPIFormat -inputObject $ret

            # CustomerObject
            if ($ret) {
                return $ret
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
    Create a new SEPPmail Managed Domain
.DESCRIPTION
    This CmdLet lets you create a new managed domain.
#>
function New-SMAManagedDomain
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
             Mandatory                       = $true,
             ValueFromPipelineByPropertyName = $true,
             ValueFromPipeline               = $true,
             HelpMessage                     = 'The domain name, e.g. example.com'
         )]
        [ValidatePattern('^((?!-)[A-Za-z0-9\-]{1,63}(?<!-)\.)+[A-Za-z]{2,6}$')]
        [string]$name,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$forwardingHost,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [uint32]$forwardingPort,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [switch]$noForwardingMxLookup,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$requestedHeader,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$requestedTenantId,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [ValidatePattern("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")]
        [string] $mailAuthenticationExpression,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidatePattern("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")]
        [string] $certAuthenticationExpression,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
             HelpMessage                     = 'An array of hashtables like so: @{ip = "127.0.0.1"; netmask = 32}. For IPv6 addresses the netmask becomes prefix'
            )]
        [hashtable[]]$sendingServers,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$smartHost,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [uint32]$smartHostPort,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [switch]$noSmartHostMxLookup,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$postmaster,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$initialDisclaimer,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $replyDisclaimer,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [string] $bounceNoAuthTemplate,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $bounceNoEncTemplate,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $bounceNoSecKeyTemplate,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $bouncePolicyTemplate,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $sendPgpKeysTemplate,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $webmailDomain,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [switch] $autopublishSmimeDomainKeys,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $tlsLevel,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string[]] $tlsFingerprints,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [switch] $dkimEnabled,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $dkimPublicKey,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $dkimPrivateKey,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [switch] $ldapEnabled,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [switch] $ldapCreateAccount,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [uint32] $ldapPort,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [switch] $ldapTls,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $ldapBindDn,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $ldapBindPassword,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $ldapObjectClass,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $ldapMailAttribute,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $ldapSearchBase,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string[]] $ldapServer,

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
            $uriPath = "{0}" -f 'mailsystem/manageddomain'

            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
            $uri = New-SMAQueryString -uriPath $uriPath @smaParams;
        }
        catch {
            Write-Error "Error $error,CategoryInfo occured"
        }
    }
    process {
        try {
            Write-Verbose 'Crafting mandatory $body JSON'
            $bodyht = @{
                domainName = $name
            }
            Write-Verbose 'Adding Optional values to $body JSON'

            if($forwardingHost)
            {
                $bodyht.forwarding = @{
                    host = $forwardingHost
                    noMXLookup = $noForwardingMxLookup.ToBool()
                }

                if($forwardingPort)
                {$bodyht.forwarding.port = $forwardingPort}
            }

            if($requestedHeader)
            {$bodyht.requestedHeader = $requestedHeader}
            if($requestedTenantId)
            {$bodyht.requestedTenantId = $requestedTenantId}

            if($mailAuthenticationExpression -or $certAuthenticationExpression)
            {$bodyht.authenticationExpression = @{}}

            if($mailAuthenticationExpression)
            {$bodyht.authenticationExpression.mail = $mailAuthenticationExpression}
            if($certAuthenticationExpression)
            {$bodyht.authenticationExpression.cert = $certAuthenticationExpression}

            if($sendingServers)
            {$bodyht.sendingServers = $sendingServers}

            if($smartHost)
            {
                $bodyht.smartHost = @{
                    host = $smartHost
                    noMXLookup = $noSmartHostMxLookup
                }

                if($smartHostPort)
                {$bodyht.smartHost.port = $smartHostPort}
            }

            if($postmaster)
            {$bodyht.postmaster = $postmaster}

            if($webmailDomain)
            {$bodyht.webmailDomain = $webmailDomain}

            if($initialDisclaimer -or $replyDisclaimer)
            {
                $bodyht.disclaimer = @{}
                if($initialDisclaimer)
                {$bodyht.disclaimer.initial = $initialDisclaimer}
                if($replyDisclaimer)
                {$bodyht.disclaimer.reply = $replyDisclaimer}
            }

            $bodyht.templates = @{}
            if($bounceNoAuthTemplate)
            {$bodyht.templates.bounce_noauth = $bounceNoAuthTemplate}
            if($bounceNoEncTemplate)
            {$bodyht.templates.bounce_noenc = $bounceNoEncTemplate}
            if($bounceNoSecKeyTemplate)
            {$bodyht.templates.bounce_noseckey = $bounceNoSecKeyTemplate}
            if($bouncePolicyTemplate)
            {$bodyht.templates.bounce_policy = $bouncePolicyTemplate}
            if($sendPgpKeysTemplate)
            {$bodyht.templates.sendpgpkeys = $sendPgpKeysTemplate}

            if($ldapServer)
            {
                $bodyht.externalAuthentication = @{ldap = @{}}
                $tmp = $bodyht.externalAuthentication.ldap

                $tmp.server = $ldapServer
                $tmp.enabled = $ldapEnabled.ToBool()
                $tmp.createAccount = $ldapCreateAccount.ToBool()
                $tmp.tls = $ldapTls.ToBool()
                if($ldapPort)
                {$tmp.port = $ldapPort}
                if($ldapBindDn)
                {$tmp.bindDN = $ldapBindDn}
                if($ldapBindPassword)
                {$tmp.bindPassword = $ldapBindPassword}
                if($ldapObjectClass)
                {$tmp.objectClass = $ldapObjectClass}
                if($ldapMailAttribute)
                {$tmp.mailAttribute = $ldapMailAttribute}
                if($ldapSearchBase)
                {$tmp.searchBase = $ldapSearchBase}
            }

            if($dkimPrivateKey)
            {
                $bodyht.dkim = @{
                    enabled = $dkimEnabled.ToBool()
                    privateKey = $dkimPrivateKey
                    publicKey = $dkimPublicKey
                }
            }

            if($tlsLevel)
            {
                $bodyht.tls = @{
                    level = $tlsLevel
                    fingerprints = $tlsFingerprints
                }
            }

            if($autopublishSmimeDomainKeys)
            {$bodyht.autopublishSMIMEDomainKeys = "on"}

            $body = $bodyht|ConvertTo-JSON

            $invokeParam = @{
                Uri         = $uri
                Method      = 'POST'
                body        = $body
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }

            if ($PSCmdLet.ShouldProcess($($bodyht.Name),"Create managed domain")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $tmp = Invoke-SMARestMethod @invokeParam

                Write-Verbose 'Returning name of managed domain'
                $tmp.message
            }
        }
        catch {
            Write-Error "An error occured, see $error.CategoryInfo"
        }
    }
}

<#
.SYNOPSIS
    Modifies a SEPPmail Managed Domain
.DESCRIPTION
    This CmdLet lets you modify a customer.
#>
function Set-SMAManagedDomain
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
             Mandatory                       = $true,
             ValueFromPipelineByPropertyName = $true,
             ValueFromPipeline               = $true,
             HelpMessage                     = 'The domain name, e.g. example.com'
         )]
        [ValidatePattern('^((?!-)[A-Za-z0-9\-]{1,63}(?<!-)\.)+[A-Za-z]{2,6}$')]
        [string]$name,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$forwardingHost,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [uint32]$forwardingPort,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [switch]$noForwardingMxLookup,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$requestedHeader,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$requestedTenantId,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [ValidatePattern("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")]
        [string] $mailAuthenticationExpression,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidatePattern("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")]
        [string] $certAuthenticationExpression,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
             HelpMessage                     = 'An array of hashtables like so: @{ip = "127.0.0.1"; netmask = 32}. For IPv6 addresses the netmask becomes prefix'
            )]
        [hashtable[]]$sendingServers,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$smartHost,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [uint32]$smartHostPort,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [switch]$noSmartHostMxLookup,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$postmaster,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$initialDisclaimer,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $replyDisclaimer,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [string] $bounceNoAuthTemplate,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $bounceNoEncTemplate,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $bounceNoSecKeyTemplate,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $bouncePolicyTemplate,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $sendPgpKeysTemplate,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $webmailDomain,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [switch] $autopublishSmimeDomainKeys,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $tlsLevel,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string[]] $tlsFingerprints,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [switch] $dkimEnabled,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $dkimPublicKey,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $dkimPrivateKey,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [switch] $ldapEnabled,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [switch] $ldapCreateAccount,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [uint32] $ldapPort,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [switch] $ldapTls,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $ldapBindDn,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $ldapBindPassword,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $ldapObjectClass,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $ldapMailAttribute,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string] $ldapSearchBase,

        [Parameter(
             Mandatory = $false,
             ValueFromPipelineByPropertyName = $true
         )]
        [string[]] $ldapServer,

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
            $uriPath = "{0}/{1}" -f 'mailsystem/manageddomain', $name

            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
            $uri = New-SMAQueryString -uriPath $uriPath @smaParams;
        }
        catch {
            Write-Error "Error $error,CategoryInfo occured"
        }
    }
    process {
        try {
            Write-Verbose 'Crafting mandatory $body JSON'
            $bodyht = @{}
            Write-Verbose 'Adding Optional values to $body JSON'

            if($forwardingHost)
            {
                $bodyht.forwarding = @{
                    host = $forwardingHost
                    noMXLookup = $noForwardingMxLookup.ToBool()
                }

                if($forwardingPort)
                {$bodyht.forwarding.port = $forwardingPort}
            }

            if($requestedHeader)
            {$bodyht.requestedHeader = $requestedHeader}
            if($requestedTenantId)
            {$bodyht.requestedTenantId = $requestedTenantId}

            if($mailAuthenticationExpression -or $certAuthenticationExpression)
            {$bodyht.authenticationExpression = @{}}

            if($mailAuthenticationExpression)
            {$bodyht.authenticationExpression.mail = $mailAuthenticationExpression}
            if($certAuthenticationExpression)
            {$bodyht.authenticationExpression.cert = $certAuthenticationExpression}

            if($sendingServers)
            {$bodyht.sendingServers = $sendingServers}

            if($smartHost)
            {
                $bodyht.smartHost = @{
                    host = $smartHost
                    noMXLookup = $noSmartHostMxLookup
                }

                if($smartHostPort)
                {$bodyht.smartHost.port = $smartHostPort}
            }

            if($postmaster)
            {$bodyht.postmaster = $postmaster}

            if($webmailDomain)
            {$bodyht.webmailDomain = $webmailDomain}

            if($initialDisclaimer -or $replyDisclaimer)
            {
                $bodyht.disclaimer = @{}
                if($initialDisclaimer)
                {$bodyht.disclaimer.initial = $initialDisclaimer}
                if($replyDisclaimer)
                {$bodyht.disclaimer.reply = $replyDisclaimer}
            }

            $bodyht.templates = @{}
            if($bounceNoAuthTemplate)
            {$bodyht.templates.bounce_noauth = $bounceNoAuthTemplate}
            if($bounceNoEncTemplate)
            {$bodyht.templates.bounce_noenc = $bounceNoEncTemplate}
            if($bounceNoSecKeyTemplate)
            {$bodyht.templates.bounce_noseckey = $bounceNoSecKeyTemplate}
            if($bouncePolicyTemplate)
            {$bodyht.templates.bounce_policy = $bouncePolicyTemplate}
            if($sendPgpKeysTemplate)
            {$bodyht.templates.sendpgpkeys = $sendPgpKeysTemplate}

            if($ldapServer)
            {
                $bodyht.externalAuthentication = @{ldap = @{}}
                $tmp = $bodyht.externalAuthentication.ldap

                $tmp.server = $ldapServer
                $tmp.enabled = $ldapEnabled.ToBool()
                $tmp.createAccount = $ldapCreateAccount.ToBool()
                $tmp.tls = $ldapTls.ToBool()
                if($ldapPort)
                {$tmp.port = $ldapPort}
                if($ldapBindDn)
                {$tmp.bindDN = $ldapBindDn}
                if($ldapBindPassword)
                {$tmp.bindPassword = $ldapBindPassword}
                if($ldapObjectClass)
                {$tmp.objectClass = $ldapObjectClass}
                if($ldapMailAttribute)
                {$tmp.mailAttribute = $ldapMailAttribute}
                if($ldapSearchBase)
                {$tmp.searchBase = $ldapSearchBase}
            }

            if($dkimPrivateKey)
            {
                $bodyht.dkim = @{
                    enabled = $dkimEnabled.ToBool()
                    privateKey = $dkimPrivateKey
                    publicKey = $dkimPublicKey
                }
            }

            if($tlsLevel)
            {
                $bodyht.tls = @{
                    level = $tlsLevel
                    fingerprints = $tlsFingerprints
                }
            }

            if($autopublishSmimeDomainKeys)
            {$bodyht.autopublishSMIMEDomainKeys = "on"}

            $body = $bodyht|ConvertTo-JSON

            $invokeParam = @{
                Uri         = $uri
                Method      = 'PUT'
                body        = $body
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }

            if ($PSCmdLet.ShouldProcess($($bodyht.Name),"Modify managed domain")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $tmp = Invoke-SMARestMethod @invokeParam

                Write-Verbose 'Returning name of managed domain'
                $tmp.message
            }
        }
        catch {
            Write-Error "An error occured, see $error.CategoryInfo"
        }
    }
}

<#
.SYNOPSIS
    Remove a SEPPmail managed domain
.DESCRIPTION
    This CmdLet lets you delete a SEPPmail managed domain.
.EXAMPLE
    PS C:\> Remove-SMAManagedDomain -name 'example.com'
    Delete a domain.
.EXAMPLE
    PS C:\> 'example1.com','example2.com'|Remove-SMAManagedDomain
    Delete a managed domain by using the pipeline
.EXAMPLE
    PS C:\> Remove-SMAManagedDomain -name 'example.com' -WhatIf
    Simulate the managed domain deletion
#>
function Remove-SMAManagedDomain
{
    [CmdletBinding(DefaultParameterSetName = 'Default',SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            ParameterSetName                = 'Default',
            Position                        = 0,
            HelpMessage                     = 'The domain you want to delete'
            )]
        [ValidatePattern('^((?!-)[A-Za-z0-9\-]{1,63}(?<!-)\.)+[A-Za-z]{2,6}$')]
        [string]$name,

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
        try {
            Write-Verbose "Creating URL path"
            $uriPath = "{0}/{1}" -f 'mailsystem/manageddomain', $name

            Write-Verbose "Building param query"
            $boundParam = $pscmdlet.MyInvocation.BoundParameters
            $boundParam.Remove('name')|out-null
            $boundParam.Remove('whatif')|out-null

            Write-Verbose "Building full request uri"
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
            $uri = New-SMAQueryString -uriPath $uriPath @smaParams;

            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri
                Method      = 'DELETE'
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }
            if ($PSCmdLet.ShouldProcess($name, "Remove managed domain")){
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                # Wait-Debugger
                $tmp = Invoke-SMARestMethod @invokeParam
                Write-Verbose 'Returning Delete details'
                $tmp.psobject.Properties.Value
            }
        }
        catch {
            Write-Error "An error occured, see $error"
        }
    }
    end {

    }

}
