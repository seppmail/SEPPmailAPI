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

# SIG # Begin signature block
# MIIVzAYJKoZIhvcNAQcCoIIVvTCCFbkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB/km2JAMw/hNFl
# kQdVM+1kalBc3G/BY+ZcFvEsecm5gaCCEggwggVvMIIEV6ADAgECAhBI/JO0YFWU
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
# BgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDhYdOfrY+oGEQHeG7Bodl8iEh+
# GThnRaPl8u8yHEni2zANBgkqhkiG9w0BAQEFAASCAgCvVPAQfMm2g/6Eix9A1a/R
# sGSfmWTuZ7jAyGo8u/LTx24oWQMtc9piZd4Z8LUIvEGaRwggfG61nsNEtw/wK/V4
# ifk+N+veFUBJ5YtldKPvaPzGWbIhF8crXfNA3Uljv4E5DnRf1cfUjxfFOgrRpkXy
# pZOMtI/m0JNLp9skGBn2nlNiu3HmuC4Z27HfiYF815ZrmRJn3U7UNPalCK+Pv0ft
# 85nWdn21dLd3MjZeHDkloMf60hqztI6FlaJI83NBqc/cfqav6m7Iw+ayrkIG4Ysf
# HTXfn7qc+vCbzSpibqBDP48OXUiaAjchSgO1QThpMqf42Ny23+slrpKNyOrM8dkq
# UKQHq/vea6zJWVVOf/ysyVWayM7sG7q8aw5CE65pPJEN4Jv68S3dBiPxDNEYKFaA
# VtjdbUlGDfDp5FUB5IIZ1W6gRwyPPNteywxCLtvzSGbNcCy1uscIOKscqT68XYQ4
# 8bH8+g3/sB0ZFsevlL0mnxtvLaxbnSRBZ9PWhCMRjeirjDpkh5RwKB9faak3OBoo
# K/poB4hRUmgtng6KcigUvp/DoP6+nCrQgABjknAOwLwFuSb2rOKYnjyyBiY5sEqn
# Odo2+cv6bJgbsRib5sV54uLCe3Sq41yncQonooYJfmlp66TBEPqCzIx21vp5TbBv
# tMOR5EhhezkI2X7l8TFMBA==
# SIG # End signature block
