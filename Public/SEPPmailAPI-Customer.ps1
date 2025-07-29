<#
.SYNOPSIS
    Find a locally existing users and details
.DESCRIPTION
    This CmdLet lets you read the detailed properties of multiple users.
.EXAMPLE
    PS C:\> Find-SMACustomer
    Emits all customers and their details - may take some time
.EXAMPLE
    PS C:\> Find-SMAUser -List
    Emits all customers names
#>
function Find-SMACustomer
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'Show list with e-mail address only'
            )]
        [bool]$list = $true,

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
        $uriPath = 'customer'

        Write-verbose "Build Parameter hashtable"
        $boundParam = @{list=$list}
        
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
        $CustomerRaw = Invoke-SMARestMethod @invokeParam

        Write-Verbose 'Filter data and return as PSObject'

        if ($list) {
            $Findcustomer = $customerRaw
        }
        else {
            $FindCustomer = $customerRaw.Psobject.properties.value
        }

        Write-Verbose 'Converting Umlauts from ISO-8859-1 and DateTime correctly'
        $customer = foreach ($c in $findcustomer) {ConvertFrom-SMAPIFormat -inputobject $c}

        if ($customer) {
            return $customer
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
    Get a locally existing customes properties
.DESCRIPTION
    This CmdLet lets you read the detailed properties of an existing customer.
.EXAMPLE
    PS C:\> Get-SMACustomer -name 'Fabrikam'
    Get information about a SEPPmail customer.
    NOTE!: Customer names are case-sensitive
.EXAMPLE
    PS C:\> 'Contoso','Fabrikam'|Get-SMACustomer
    Use the pipeline to query multiple customers
    NOTE!: Customer names are case-sensitive
#>
function Get-SMACustomer
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'Customer name (Case sensitive!)'
            )]
        [ValidatePattern('[a-zA-Z0-9\-_]')]
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
            $uriPath = "{0}/{1}" -f 'customer', $name
    
            Write-Verbose "Build QueryString"
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
            $uri = New-SMAQueryString -uriPath $uriPath @smaParams;
    
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri 
                Method      = 'GET'
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }
            Write-Verbose "Call Invoke-SMARestMethod $uri" 
            $customerRaw = Invoke-SMARestMethod @invokeParam
    
            Write-Verbose 'Filter data and return as PSObject'
            $GetCustomer = $customerRaw.Psobject.properties.value
    
            Write-Verbose 'Converting Umlauts from ISO-8859-1'
            $customer = ConvertFrom-SMAPIFormat -inputObject $getCustomer
    
            # CustomerObject
            if ($customer) {
                return $customer
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
    Create a new SEPPmail Customer
.DESCRIPTION
    This CmdLet lets you create a new customer. You need at minimum the customers name.
.EXAMPLE
    PS C:\> New-SMACustomer -Name 'Fabrikam'
    Create the customer 'Fabrikam' with default values.
.EXAMPLE
    PS C:\> New-SMACustomer -Name 'Fabrikam' -adminEmail admin@fabrikam.com
    Create the customer 'Fabrikam' with default values.
.EXAMPLE
    PS C:\> New-SMACustomer -Name 'Fabrikam' -admins @('admin@fabrikam.com','admin2@fabrikam.com')
    Create a new customer and set 2 admins by defining their E-Mail adresses
.EXAMPLE
    PS C:\> $customerInfo = @{
        Name = 'Contoso'
        adminEmail = 'admin@contoso.com'
        admins = @('admin@contoso.com','admin2@contoso.com')
        backupPassword = 'someReallydifficultPassword'
        comment = 'Contoso is one of our most important clients'
        defaultGINADomain = 'ContosoMain'
        deleteOldMessagesGracePeriod = 30
        deleteUnregistered = 60
        description = 'Contoso Holding AG'
        mailRoutes = @()
        maximumEncryptionLicenses = 5
        maximumLFTLicenses = 3
        sendBackupToAdmin = $true
    }
    PS C:\> New-SMACustomer @customerInfo
    Example of all parameters possible to create a customer using PowerShell parameter splatting
#>
function New-SMACustomer
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'The customers display name'
            )]
        [ValidatePattern('[a-zA-Z0-9\-_]')]
        [string]$name,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Customers admin E-Mail address'
            )]
        [string]$adminEmail,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'The customers administrators uid´s as array'
            )]
        [string[]]$admins,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Backup password'
            )]
        [secureString]$backupPassword,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Some additional text'
            )]
        [string]$comment,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'GINA domain to use of none is selected'
            )]
        [string]$defaultGINADomain,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Grace period (in days) after which old GINA message metadata are automatically removed. Mails can still be decrypted by recipient if metadata is missing. (set to 0 to disable)'
            )]
        [Alias('delMessGrace')]
        [int]$deleteOldMessagesGracePeriod = 0,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Grace period (in days) after which unregistered GINA accounts are automatically removed (set to 0 to disable)'
            )]
        [Alias('delUnreg')]
        [int]$deleteUnregistered = 0,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Customers more detailed description'
            )]
        [string]$description,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = '?????????????????'
            )]
        [string[]]$mailRoutes,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'How many licenses may users of this customers consume for encryption ?'
            )]
        [int]$maximumEncryptionLicenses,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'How many licenses may users of this customers consume for elarge file transfer ?'
            )]
        [int]$maximumLFTLicenses,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Automatically send backup to Customer Admin E-mail'
            )]
        [bool]$sendBackupToAdmin,

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
            $uriPath = "{0}" -f 'customer'
        
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
                name = $name
            }
            Write-Verbose 'Adding Optional values to $body JSON'
            if ($adminEmail) {$bodyht.adminEmail = $adminEmail}
            if ($admins) {$bodyht.admins = $admins}
            if ($backupPassword) {$bodyht.backupPassword = (ConvertFrom-SMASecureString -securePassword $backupPassword)}
            if ($comment) {$bodyht.comment = $comment}
            if ($defaultGINADomain) {$bodyht.defaultGINADomain = $defaultGINADomain}
            if ($deleteOldMessagesGracePeriod) {$bodyht.deleteOldMessagesGracePeriod = $deleteOldMessagesGracePeriod}
            if ($deleteUnregistered) {$bodyht.deleteUnregistered = $deleteUnregistered}
            if ($description) {$bodyht.description = $description}
            if ($mailRoutes) {$bodyht.mailRoutes = $mailRoutes}
            if ($maximumEncryptionLicenses) {$bodyht.maximumEncryptionLicenses = $maximumEncryptionLicenses}
            if ($maximumLFTLicenses) {$bodyht.maximumLFTLicenses = $maximumLFTLicenses}
            if ($sendBackupToAdmin) {$bodyht.sendBackupToAdmin = $sendBackupToAdmin}
    
            $body = $bodyht|ConvertTo-JSON
    
            $invokeParam = @{
                Uri           = $uri 
                Method        = 'POST'
                body          = $body
                Cred          =  $cred
                SkipCertCheck = $SkipCertCheck
            }

            if ($PSCmdLet.ShouldProcess($($bodyht.Name),"Create customer")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $customerRaw = Invoke-SMARestMethod @invokeParam
        
                Write-Verbose 'Returning name of customer'
                $customerRaw.message
            }
        }
        catch {
            Write-Error "An error occured, see $error.CategoryInfo"
        }
    }
}

<#
.SYNOPSIS
    Modyfies a SEPPmail customer
.DESCRIPTION
    This CmdLet lets you modity an existing customer. You need the customer name for identification.
.EXAMPLE
    PS C:\> Set-SMAcustomer -name 'Contoso' -description 'Contoso AG London'
    Change the description of Contoso.
.EXAMPLE
    To change multiple values of a customer at one, we recomend using paraeter splatting. Create a hashtable, like below and 
    PS C:\> $customerInfo = @{
        adminEmail = 'admin@contoso.com'
        admins = @('admin@contoso.com','admin2@contoso.com')
        backupPassword = 'someReallydifficultPassword'
        comment = 'Contoso is one of our most important clients'
        defaultGINADomain = 'ContosoMain'
        deleteOldMessagesGracePeriod = 30
        deleteUnregistered = 60
        description = 'Contoso Holding AG'
        mailRoutes = @()
        maximumEncryptionLicenses = 10
        maximumLFTLicenses = 5
        sendBackupToAdmin = $true
    }
    PS C:\> Set-SMAcustomer -name 'Contoso' @customerInfo
    Example of all parameters possible to change a customer.
#>
function Set-SMACustomer
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'The customers display name'
            )]
        [ValidatePattern('[a-zA-Z0-9\-_]')]
        [string]$name,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Customers admin E-Mail address(es)'
            )]
        [string]$adminEmail,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'The customers administrators uid´s as array'
            )]
        [string[]]$admins,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Backup password'
            )]
        [secureString]$backupPassword,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Some additional text'
            )]
        [string]$comment,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'GINA domain to use of none is selected'
            )]
        [string]$defaultGINADomain,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Grace period (in days) after which old GINA message metadata are automatically removed. Mails can still be decrypted by recipient if metadata is missing. (set to 0 to disable)'
            )]
        [Alias('delMessGrace')]
        [int]$deleteOldMessagesGracePeriod = 0,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Grace period (in days) after which unregistered GINA accounts are automatically removed (set to 0 to disable)'
            )]
        [Alias('delUnreg')]
        [int]$deleteUnregistered = 0,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Customers more detailed description'
            )]
        [string]$description,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = '?????????????????'
            )]
        [string[]]$mailRoutes,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'How many licenses may users of this customers consume for encryption ?'
            )]
        [int]$maximumEncryptionLicenses,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'How many licenses may users of this customers consume for elarge file transfer ?'
            )]
        [int]$maximumLFTLicenses,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Automatically send backup to Customer Admin E-mail'
            )]
        [bool]$sendBackupToAdmin,

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
        Write-Verbose "Creating URL path"
        $uriPath = "{0}/{1}" -f 'customer', $name

        Write-Verbose "Building full request uri"
        $boundParam = @{name=$name}
        $smaParams=@{
            Host=$Host;
            Port=$Port;
            Version=$Version;
        }; # end smaParams
        $uri = New-SMAQueryString -uriPath $uriPath @smaParams; #-qParam $boundParam

        Write-Verbose 'Crafting mandatory $body JSON'
        $bodyht = @{}

        Write-Verbose 'Adding optional values to $body JSON'
        if ($adminEmail) {$bodyht.adminEmail = $adminEmail}
        if ($admins) {$bodyht.admins = $admins}
        if ($backupPassword) {$bodyht.backupPassword = (ConvertFrom-SMASecureString -securePassword $backupPassword)}
        if ($comment) {$bodyht.comment = $comment}
        if ($defaultGINADomain) {$bodyht.defaultGINADomain = $defaultGINADomain}
        if ($deleteOldMessagesGracePeriod) {$bodyht.deleteOldMessagesGracePeriod = $deleteOldMessagesGracePeriod}
        if ($deleteUnregistered) {$bodyht.deleteUnregistered = $deleteUnregistered}
        if ($description) {$bodyht.description = $description}
        if ($mailRoutes) {$bodyht.mailRoutes = $mailRoutes}
        if ($maximumEncryptionLicenses) {$bodyht.maximumEncryptionLicenses = $maximumEncryptionLicenses}
        if ($maximumLFTLicenses) {$bodyht.maximumLFTLicenses = $maximumLFTLicenses}
        if ($sendBackupToAdmin) {$bodyht.sendBackupToAdmin = $sendBackupToAdmin}
        
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
        Write-Verbose "Call Invoke-SMARestMethod $uri"
        $customerRaw = Invoke-SMARestMethod @invokeParam
        #debug $customerraw
        Write-Verbose 'Returning name of customer'
        $customerRaw.psobject.Properties.Value  
    }
    catch {
        Write-Error "An error occured, see $error"
    }
}

<#
.SYNOPSIS
    Remove a SEPPmail customer
.DESCRIPTION
    This CmdLet lets you delete a SEPPmail customer. You need the name of the customer.
.EXAMPLE
    PS C:\> Remove-SMAcustomer -name 'Fabrikam'
    Delete a customer.
.EXAMPLE
    PS C:\> 'Contoso','Fabrikam'|Remove-SMAcustomer
    Delete a customer by using the pipeline
.EXAMPLE
    PS C:\> Remove-SMAcustomer -name 'Fabrikam' -WhatIf
    Simulate the customer deletion
#>
function Remove-SMAcustomer
{
    [CmdletBinding(DefaultParameterSetName = 'Default',SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            ParameterSetName                = 'Default',
            Position                        = 0,
            HelpMessage                     = 'The customer´s name you want to delete'
            )]
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            ParameterSetName                = 'DeleteAll',
            Position                        = 0,
            HelpMessage                     = 'The customer´s name you want to delete'
            )]
        [ValidatePattern('[a-zA-Z0-9\-_]')]
        [string]$name,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName                = 'Default',
            HelpMessage                     = 'If set, deletes all related users of this customer'
            )]
        [switch]$deleteUsers = $false,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName                = 'Default',
            HelpMessage                     = 'If set, deletes all related GINA users of this customer'
            )]
        [switch]$deleteGINAUsers = $false,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName                = 'Default',
            HelpMessage                     = 'If set, deletes all Admin Users of this customer'
            )]
        [switch]$deleteAdminUsers = $false,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName                = 'Default',
            HelpMessage                     = 'If set, deletes all managed domains related to this customer'
            )]
        [switch]$deleteManagedDomains = $false,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName                = 'Default',
            HelpMessage                     = 'If set, deletes all GINA domains related to this customer'
            )]
        [switch]$deleteGINADomains = $false,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName                = 'Default',
            HelpMessage                     = 'If set, deletes all policies of this customer'
            )]
        [switch]$deletePolicies = $false,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName                = 'Default',
            HelpMessage                     = 'If set, deletes all smarhost credentials used EXCLUSIVELY by this customer'
            )]
        [switch]$deleteSmarthostCredentials = $false,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName                = 'DeleteAll',
            HelpMessage                     = 'If set, deletes everything related to this customer'
            )]
        [switch]$deleteEverything = $false,

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
            $uriPath = "{0}/{1}" -f 'customer', $name
    
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
            $uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams;
    
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri 
                Method      = 'DELETE'
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }
            if ($PSCmdLet.ShouldProcess($name, "Remove customer")){
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                # Wait-Debugger
                $customerRaw = Invoke-SMARestMethod @invokeParam
                Write-Verbose 'Returning Delete details'
                $customerRaw.psobject.Properties.Value
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
    Export a customer and all its details.
.DESCRIPTION
    This CmdLet lets you export an existing customer.
.EXAMPLE
    PS C:\> $backuppassword = ConvertTo-SecureString -String 'secretbackup' -AsPlainText -Force
    PS C:\> Export-SMACustomer -name 'Fabrikam' -encryptionpassword $backuppassword -path ..\Fabrikam.zip
    Export the customer Fabrikam to a local ZIP-file in the parent folder of the current folder (with a relative path)
    NOTE!: Customer names are case-sensitive
.EXAMPLE
    PS C:\> $backuppassword = ConvertTo-SecureString -String 'secretbackup' -AsPlainText -Force
    PS C:\> Export-SMACustomer -name 'Fabrikam' -encryptionpassword $backuppassword -literalpath c:\temp\Fabrikam.zip
    Export the customer Fabrikam to a local ZIP-file with a literal path
    NOTE!: Customer names are case-sensitive
#>
function Export-SMACustomer
{
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Customer name (Case sensitive!)'
            )]
        [ValidatePattern('[a-zA-Z0-9\-_]')]
        [string]$name,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Password for encrypted ZIP'
            )]
        [SecureString]$encryptionPassword,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName                = 'Path',
            HelpMessage                     = 'Relative Path for ZIP-File, i.e. .\contoso.zip'
            )]
        [string]$path,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName                = 'LiteralPath',
            HelpMessage                     = 'Literal path for ZIP-File, i.e. c:\temp\contoso.zip'
            )]
        [string]$literalPath,

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
                $uriPath = "{0}/{1}/{2}" -f 'customer', $name, 'export'
        
                Write-Verbose "Building full request uri"
                $smaParams=@{
                    Host=$Host;
                    Port=$Port;
                    Version=$Version;
                }; # end smaParams
                $uri = New-SMAQueryString -uriPath $uriPath @smaParams;
        
                Write-verbose "Packing password into body JSON"
                $encryptionPasswordPlain = ConvertFrom-SMASecureString -securePassword $encryptionPassword
        
                $bodyHt = @{
                    encryptionpassword = $encryptionPasswordPlain
                }
                $body = ConvertTo-Json $bodyHt
        
                Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
                $invokeParam = @{
                    Uri         = $uri 
                    Method      = 'POST'
                    body        = $body
                    Cred        =  $cred
                    SkipCertCheck = $SkipCertCheck
                }
        
                Write-Verbose "Call Invoke-SMARestMethod $uri" 
                $ExportRaw = Invoke-SMARestMethod @invokeParam
        
                Write-Verbose "Converting JSON Zip data to ZipFile"
                $bytes = [System.Convert]::FromBase64String($ExportRaw.zippedData)
                if ($pscmdlet.ParameterSetName -eq 'Path') {
                    Write-Verbose "Will create a file according to $path definition"
                    $ZipfileRoot = (Split-Path $path -Parent|resolve-path).Path
                    $ZipfileName = Split-Path $path -leaf
                    $ZipfilePath = Join-Path -Path $ZipFileRoot -ChildPath $ZipFileName
                    [IO.File]::WriteAllBytes($ZipFilePath, $bytes)
                    Write-Information "Written file to $ZipFilePath"
                }
                if ($pscmdlet.ParameterSetName -eq 'literalPath') {
                    $fileParent = Split-Path $literalPath -Parent
                    if (!(test-path $fileparent)) {
                        Write-Verbose "Directory of $literalpath didnt exist, trying to create it"
                        New-Item -ItemType Directory -Path $fileParent
                    }
                    Write-Verbose "Will create a file according to $literalpath definition"
                    [IO.File]::WriteAllBytes($literalpath, $bytes)
                    Write-Information "Written file to $literalPath"
                }
            }
            catch {
                Write-Error "An error occured, see $error"
            }
        }
}
#>

function Import-SMACustomer
{
    [CmdletBinding(DefaultParameterSetName = 'Path',SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Customer name (Case sensitive!)'
            )]
        [ValidatePattern('[a-zA-Z0-9\-_]')]
        [string]$name,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Secure password for encrypted ZIP'
            )]
        [SecureString]$encryptionPassword,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName                = 'Path',
            HelpMessage                     = 'Relative Path for ZIP-File, i.e. .\contoso.zip'
            )]
        [string]$path,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName                = 'LiteralPath',
            HelpMessage                     = 'Literal path for ZIP-File, i.e. c:\temp\contoso.zip'
            )]
        [string]$literalPath,

        [Parameter(
            Mandatory=$false
            )]
            [System.Management.Automation.PSCredential]$cred=$Script:activeCfg.SMACred,
            [Parameter(Mandatory = $false)]
            [String]$host = $Script:activeCfg.SMAHost,

            [Parameter(Mandatory = $false)]
            [int]$port = $Script:activeCfg.SMAPort,
            [Parameter(
                Mandatory=$false
                )]
            [switch]$SkipCertCheck=$Script:activeCfg.SMAskipCertCheck,

            [Parameter(Mandatory = $false)]
            [String]$version = $Script:activeCfg.SMAPIVersion
        )

    if (! (verifyVars -VarList $Script:requiredVarList))  # no version needed
    {
        Throw($missingVarsMessage);
    }; # end if

    try {
        
        Write-Verbose "Creating URI path"
        $uripath = "{0}/{1}" -f 'customer', 'import'
    
        Write-verbose "Creating SMA Query String"
        $smaParams = @{
            Host    = $Host
            Port    = $Port
            Version = $Version
        } # end smaParams
        $uri = New-SMAQueryString -uriPath $uriPath @smaParams

        Write-verbose "Packing password into body JSON"
        $encryptionPasswordPlain = ConvertFrom-SMASecureString -securePassword $encryptionPassword

        $jsonZIP = $null
        Write-Verbose "Convert ZIPFile to JSON Zip Data"
        if ($psCmdLet.ParameterSetName -eq 'Path')
        {
            if (!(Test-Path $path))
            {
                Write-Error "$Path does not exist - please enter a valid path"
                break
            }
            else
            {
                  $truePath = Resolve-Path $path
                $zipContent = [IO.File]::ReadAllBytes($truePath)
                   $jsonZip = [System.Convert]::ToBase64String($zipContent)
            }
        }

        if ($psCmdLet.ParameterSetName -eq 'LiteralPath') {
            if (!(Test-path $literalPath)) {
                Write-Error "$literalPath does not exist - please enter a valid path"
                break
            } else {
                $truePath = Resolve-Path $literalPath
                $zipContent = [IO.File]::ReadAllBytes($truePath)
                $jsonZip = [System.Convert]::ToBase64String($zipContent)
            }
        }

        $bodyHt = @{
            zippedData = $jsonZip
            encryptionpassword = $encryptionPasswordPlain
            name = $name
        }
        $body = ConvertTo-Json $bodyHt

        Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
        $invokeParam = @{
            Uri           = $uri 
            Method        = 'POST'
            body          = $body
            Cred          = $cred
            SkipCertCheck = $SkipCertCheck
        }

        if ($PSCmdLet.ShouldProcess($name,"Import customer")) {
            Write-Verbose "Call Invoke-SMARestMethod $uri" 
            #Wait-Debugger
            Invoke-SMARestMethod @invokeParam
        }

    }
    catch {
        Write-Error "An error occured, see $error"
    }
}

<#
.SYNOPSIS
	Add admins to a customer
.DESCRIPTION
	This CmdLet lets you add administrators to an existing SEPPmail customer.
    You need the e-Mail addresses of the admins.
.EXAMPLE
	PS C:\> Add-SMAcustomerAdmin -customer 'Contoso' -email 'john.doe@contoso.com'
#>
function Add-SMAcustomerAdmin
{
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter(
			Mandatory                       = $true,
			ValueFromPipelineByPropertyName = $true,
			ValueFromPipeline               = $true,
			HelpMessage                     = "Admin E-Mail addresses in an array @('john.doe@contoso.com','jane.black@fabrikam.com')"
			)]
		[string[]]$admins,

		[Parameter(
			Mandatory                       = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage                     = 'Customer name'
			)]
		[string]$customer,

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
			$uriPath = "{0}/{1}/{2}" -f 'customer', $customer, 'adminuser'
		}
		catch {
			Write-Error "Error$.categoryInfo happened"
		}
	}
	process {
		try {
			Write-Verbose "Building full request uri"
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
			$uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams;

			Write-verbose "Crafting body ht for list of admins"
            $bodyht = @{
                admins = $admins
            }

            $body = $bodyht|ConvertTo-JSON
			Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
			$invokeParam = @{
				Uri         = $uri 
				Method      = 'POST'
                body        = $body
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
				}
			
			if ($PSCmdLet.ShouldProcess($customer,"Adding admin users")) {
				Write-Verbose "Call Invoke-SMARestMethod $uri"
				$adminUsers = Invoke-SMARestMethod @invokeParam
				Write-Verbose 'Returning changes'
                $adminusers
                #($userraw.message -split ' ')[3]
			}
		}
		catch {
			Write-Error "An error occured, see $error.CategoryInfo"
		}
	}
}

<#
.SYNOPSIS
	Removes admins from a customer
.DESCRIPTION
	This CmdLet lets you remove administrators from an existing SEPPmail customer.
    You need the e-Mail addresses of the admins and the customers name.
.EXAMPLE
	PS C:\> Remove-SMAcustomerAdmin -customer 'Contoso' -email 'john.doe@contoso.com'
#>
function Remove-SMAcustomerAdmin
{
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter(
			Mandatory                       = $true,
			ValueFromPipelineByPropertyName = $true,
			ValueFromPipeline               = $true,
			HelpMessage                     = "Admin E-Mail addresses in an array @('john.doe@contoso.com','jane.black@fabrikam.com')"
			)]
		[string[]]$admins,

		[Parameter(
			Mandatory                       = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage                     = 'Customer name'
			)]
		[string]$customer,

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
            [switch]$SkipCertCheck=$Script:activeCfg.SkipCertCheck 
	)

	begin {
        if (! (verifyVars -VarList $Script:requiredVarList))
        {
            Throw($missingVarsMessage);
        }; # end if
        
		try {
			Write-Verbose "Creating URL path"
			$uriPath = "{0}/{1}/{2}" -f 'customer', $customer, 'adminuser'
		}
		catch {
			Write-Error "Error$.categoryInfo happened"
		}
	}
	process {
		try {
			Write-Verbose "Building full request uri"
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
			$uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams;

			Write-verbose "Crafting body ht for list of admins"
            $bodyht = @{
                admins = $admins
            }

            $body = $bodyht|ConvertTo-JSON
			Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
			$invokeParam = @{
				Uri         = $uri 
				Method      = 'PUT'
                body        = $body
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
				}
			
			if ($PSCmdLet.ShouldProcess($customer,"Removing admin users")) {
				Write-Verbose "Call Invoke-SMARestMethod $uri"
				$adminUsers = Invoke-SMARestMethod @invokeParam
				Write-Verbose 'Returning changes'
                $adminusers
                #($userraw.message -split ' ')[3]
			}
		}
		catch {
			Write-Error "An error occured, see $error.CategoryInfo"
		}
	}
}

Write-Verbose 'Create CmdLet Alias for Customers' 
$custVerbs = ('Add','Remove','Get','Import','Export','Find','Set')

Foreach ($custverb in $custVerbs) {
    $aliasname1 = $custverb + '-SMACust'
    $aliasname2 = $custverb + '-SMATen'
    $cmdName = $custverb + '-SMACustomer'
    New-Alias -Name $aliasName1 -Value $cmdName
    New-Alias -Name $aliasName2 -Value $cmdName
}

# SIG # Begin signature block
# MIIVzAYJKoZIhvcNAQcCoIIVvTCCFbkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBoJAt2XKEaj3ZO
# 6O0Qtu2MHIMJqWtdo8Rv6hNSljOxjKCCEggwggVvMIIEV6ADAgECAhBI/JO0YFWU
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
# BgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCD0uGNIIkDQM0w5INgZ7umeRo/n
# kl+eNFim1bIgcms0yTANBgkqhkiG9w0BAQEFAASCAgBD3uNTe/UnFce2Qtt73wKd
# P3gFm5JX9erUQWYjrH39UXKtYeNQdTS8RBKGVTq1p4DP1yYkltsmsb7vYqcwfGL6
# DY3sqddaIT2oGeyEA4kOC9FPEOaian+P8xZCBIbEZmX5BhEHtHzFkOoxUuV/mkcb
# FNrHOV7jCVqyR5wji6thugQMFqgOwuZJK4oqQlRffWOMW4XiK3b5/XATLkxp5PX7
# JNesASJjjGuvcN1AhBxoP4vJxreURQnHGu8XMpJt9y4XSt9WH92aD57KTvtYbz6I
# CV773lfiX+Ir57DyD02VqWcZOvfHGUKQxLcvBw24p2ViuAmb1Lni3KbPxy71+8uc
# k4QctuBjwFlvv4JvnTHFtBsoEmibv7Qn5z/qcXpYowrjJh6k/pwugYDG7ZQVBbrG
# K7lKlBrH3ItX7gVMpGQb68UYG07yUXExQLqe1Q8qwPcFiQZYlTFEgDEHTOKJ11r2
# 4qBWq6SCgMEeuSSv8Rsi0T4WNDDxhLJjNLZzbFVb3aKNpYJ3cYZM+5HawshDlivl
# hnqjFhC1rahCt5Jy3iO+116V9FhGMbT/asN/kKPVXjFXCRqOp8zJkO8PPs150ekV
# S5PdtrTqlusHhKLtIYkbfpJr1Z3sSAJYmMHUzbw0dJhUxwGayM6BYL17g9Ena2tG
# ASf98ju4y4gAZqtlrdjJbQ==
# SIG # End signature block
