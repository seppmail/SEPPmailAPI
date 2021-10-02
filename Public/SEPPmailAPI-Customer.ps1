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
                Uri         = $uri 
                Method      = 'POST'
                body        = $body
                Cred        =  $cred
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
# MIIL1wYJKoZIhvcNAQcCoIILyDCCC8QCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+POFKiqyTUPHYY2zawasFwAZ
# +q2ggglAMIIEmTCCA4GgAwIBAgIQcaC3NpXdsa/COyuaGO5UyzANBgkqhkiG9w0B
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
# MRYEFNZp4hMnjdV9w5WzpbQES1RPYGMRMA0GCSqGSIb3DQEBAQUABIIBACSW3/4Q
# ztYUnnZyIKijCQpJnRJD+RCDQFoP09AR15AIXzZiFpaQ0ctGDhDNhL5m23rJUQUs
# Sij8WY1BEY3fMIW5Si+mTcTxxp6AgVL2uH/na8E2Ohpg8Zm2oOvTNJ4RoYuaXPQM
# x1Qvcx8zxzfHs+im7BJAPo0dHRgWmuXLE29IMR1ckHwXtu5EfL5N/3pmTHMprKEd
# bxXdiqsE0XTfPcy7Ww/tNkvR4huwhpC7UBSDh2bamfI/r7EUh65+vRWPcZD0qjzM
# P0dykwt9b0zxHDyEoTaWGLCXdhP1VDWz1NTvymE/LDh4jnb8yeYOQYczIYn7bz+p
# FXalua4x0eqQh00=
# SIG # End signature block
