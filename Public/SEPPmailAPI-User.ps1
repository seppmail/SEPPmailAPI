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
    Find a locally existing users by email address, name or uid.
.DESCRIPTION
    This CmdLet lets you quickly find users in the SEPPmail Database by various properties. 
    It may be used with 4 different variants.
    1. By Name with the -name parameter and a part of the users name.
    2. By uid with the -uid parameter and an EXACT match of the uid.
    3. By email address with the -email parameter and and EXACT match of the email address
    4. By a part of the email address with the -partialMatch parameter.

    By Default
.EXAMPLE
    PS C:\> Find-SMAUser
    Emits all users and their details - may take some time
.EXAMPLE
    PS C:\> Find-SMAUser -email 'john.doe@fabrikam.eu'
    Emits the specific user with this email address.
.EXAMPLE
    PS C:\> Find-SMAUser -name 'john'
    Emits all users with john in the email address
.EXAMPLE
    PS C:\> Find-SMAUser -partialMatch 'fabrikam.eu'
    Emits all users with fabrikam.eu in the email address
.EXAMPLE
    PS C:\> Find-SMAUser -uid 'john'
    Emits the specific user john as UID
.EXAMPLE
    PS C:\> Find-SMAUser -customer 'Contoso'
    Emits e-mail addresses of all users of a particular customer
.EXAMPLE
    PS C:\> Find-SMAUser -List
    Emits all users and their details
.EXAMPLE
    PS C:\> Find-SMAUser -limit 5
    Emits all users but stop output at 5 objects
.EXAMPLE
    PS C:\> Find-SMAUser -active:$false
    Emits only active users
.EXAMPLE
    PS C:\> Find-SMAUser -activeWithinDays 14
    Emits only users which have sent emails within the last 14 days
.EXAMPLE
    PS C:\> Find-SMAUser -partialMatch 'tailspintoys.com' -activeWithinDays 14 -customer 'tailspintoys' -Limit 50
    Use a combination of parameters to pre-filter the output as good as possible.
#>
function Find-SMAUser
{
    [CmdletBinding(
        DefaultParameterSetName             = 'partialMatch'
    )]

    param (
        #region Define the 4 parametersets and the uniqe params in it
        [Parameter(
            ParameterSetName                = 'email',
            Mandatory                       = $true,
            Position                        = 0,
            HelpMessage                     = 'Find users by their e-Mail address'
            )]
        [string]$email,

        [Parameter(
            ParameterSetName                = 'partialMatch',
            Mandatory                       = $false,
            Position                        = 0,
            HelpMessage                     = 'Find users by a partial match of their e-Mail address'
            )]
        [string]$partialMatch = ' ',

        [Parameter(
            ParameterSetName                = 'name',
            Mandatory                       = $true,
            Position                        = 0,
            HelpMessage                     = 'Find users by their display name (parts of the name allowed)'
            )]
        [string]$name,

        [Parameter(
            ParameterSetName                = 'uid',
            Mandatory                       = $true,
            Position                        = 0,
            HelpMessage                     = 'Find users by their exact uid' 
            )]
        [string]$uid,
        #endregion

        #region common API params for all parametersets
        [Parameter(
                Mandatory                   = $false,
                HelpMessage                 = 'For MSP´s and multi-customer environments, limit query for a specific customer'
                )]
        [string]$customer,

        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'Show list with e-mail address only'
            )]
        [bool]$list = $true,

        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'limit output to <n> objects' 
            )]
        [int]$limit = 0,

        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'limit output to active or inactive objects' 
            )]
        [bool]$active,

        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'limit output to users which have sent e-mails within a certain timeframe (days)'
            )]
        [int]$activeWithinDays,
        #endregion

        #region SMAParameters
        [Parameter(Mandatory = $false)]
        [String]$host = $Script:activeCfg.SMAHost,

        [Parameter(Mandatory = $false)]
        [int]$port = $Script:activeCfg.SMAPort,

        [Parameter(Mandatory = $false)]
        [String]$version = $Script:activeCfg.SMAPIVersion,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$cred=$Script:activeCfg.SMACred,

        [Parameter(Mandatory=$false)]
        [switch]$SkipCertCheck=$Script:activeCfg.SMAskipCertCheck
        #endregion SMAParameters
    )

    if (! (verifyVars -VarList $Script:requiredVarList))
    {
        Throw($missingVarsMessage);
    }; # end if

    try {
        Write-Verbose "Building full request uri icluding all bound parameters"
        #$boundParam = $psCmdLet.MyInvocation.BoundParameters
        # Build querystring hashtable for conversion from parameters. Boundparams are eiter mandatory or have default values
        $boundParam = @{
                   'list' = $list
                  'limit' = $limit
            }

            # Now check if any of the parameters was set by the commandline and set their values for the querystring
                     if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('name')) {$boundParam.name = $name}
                    if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('email')) {$boundParam.email = $email}
             if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('partialMatch')) {$boundParam.partialMatch = $partialMatch}
                      if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('uid')) {$boundParam.uid = $uid}
                 if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('customer')) {$boundParam.customer = $customer}
                   if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('active')) {$boundParam.active = $active}
         if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('activeWithinDays')) {$boundParam.activeWithinDays = $activeWithinDays}

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
        #region REST-API Parameters
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

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'SEPPmail group membership'
            )]
        [string[]]$memberOf,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'POP (IMAP) account userID (e-mail address)'
            )]
        [string]$mailAccountUID,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'POP (IMAP) account password as securestring'
            )]
        [secureString]$mailAccountPassword,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'POP (IMAP) account host'
            )]
        [string]$mailAccountHost,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'POP (IMAP) account host uses SSL'
            )]
        [boolean]$mailAccountSSL,
        #endregion

        #region SMAparams
        [Parameter(Mandatory = $false)]
        [String]$host = $Script:activeCfg.SMAHost,

        [Parameter(Mandatory = $false)]
        [int]$port = $Script:activeCfg.SMAPort,

        [Parameter(Mandatory = $false)]
        [String]$version = $Script:activeCfg.SMAPIVersion,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$cred=$Script:activeCfg.SMACred,

        [Parameter(Mandatory=$false)]
        [switch]$SkipCertCheck=$Script:activeCfg.SMAskipCertCheck
        #endregion
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
                    if ($notifications) {$bodyht.notifications = $notifications}
                        if ($password) {$bodyht.password = ($password|ConvertFrom-SecureString -asplaintext)}
                 if ($mpkiSubjectPart) {$bodyht.mpkiSubjectPart = $mpkiSubjectPart}
                        if ($memberOf) {$bodyht.memberOf = $memberOf}
                  if ($mailAccountUID) {$bodyht.mailAccountUID = $mailAccountUID}
             if ($mailAccountPassword) {$bodyht.mailAccountPassword = ($mailAccountPassword|ConvertFrom-Securestring -AsPlainText)}
                 if ($mailAccountHost) {$bodyht.mailAccountHost = $mailAccountHost}
                  if ($mailAccountSSL) {$bodyht.mailAccountSSL = $mailAccountSSL}

            
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
        password = 'aBc1$6tgR'  # (As securestrig)
        customer = 'Contoso'
        notifications = 'never'
        mpkiSubjectPart = ''
        notifications = 'never'
        memberOf = 'myOwnGroup'
        mailAccountUID = 'm.musterfrau'
        mailAccountPassword = 'aBc1$6tgR'  # (As securestrig)
        mailAccountHost = 'mail.contoso.com'
        mailAccountSSL = $true
    }
    PS C:\> Set-SMAUser @userInfo
    Example of all parameters possible to change a user using parameter splatting
#>
function Set-SMAUser
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        #region API parameters
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
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

<#        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = '!!CASE_SENSITIVE!! For MSP´s, multi-customer and cloud environments, set the users customer, API default is blank'
            )]
        [string]$customer,
#>
        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Disable the encrypt functionality for the user, API default is $false'
            )]
        [boolean]$mayNotEncrypt,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Disable the sign functionality for the user, API default is $false'
            )]
        [boolean]$mayNotSign,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Lock this user, API default is $false'
            )]
        [boolean]$locked,

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

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'SEPPmail group membership'
            )]
        [string[]]$memberOf,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'POP (IMAP) account userID (e-mail address)'
            )]
        [string]$mailAccountUID,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'POP (IMAP) account password as securestring'
            )]
        [secureString]$mailAccountPassword,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'POP (IMAP) account host'
            )]
        [string]$mailAccountHost,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'POP (IMAP) account host uses SSL'
            )]
        [boolean]$mailAccountSSL,    
        #endregion

        #region SMAParams
        [Parameter(Mandatory = $false)]
        [String]$host = $Script:activeCfg.SMAHost,

        [Parameter(Mandatory = $false)]
        [int]$port = $Script:activeCfg.SMAPort,

        [Parameter(Mandatory = $false)]
        [String]$version = $Script:activeCfg.SMAPIVersion,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$cred=$Script:activeCfg.SMACred,

        [Parameter(Mandatory=$false)]
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
        try  {
            
            Write-Verbose "Creating URL path"
            $uriPath = "{0}/{1}" -f 'user', $eMail
            Write-Verbose "Building full request uri"
            $boundParam = @{}
            
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
                                                  if ($locked) {$bodyht.locked = $locked}
                                           if ($mayNotEncrypt) {$bodyht.mayNotEncrypt = $mayNotEncrypt}
                                              if ($mayNotSign) {$bodyht.mayNotSign = $mayNotSign}
                                         if ($mpkiSubjectPart) {$bodyht.mpkiSubjectPart = $mpkiSubjectPart}
                                            if ($notifications) {$bodyht.notifications = $notifications}
                                                if ($password) {$bodyht.password = ($password|ConvertFrom-SecureString -asplaintext)}
                                                if ($memberOf) {$bodyht.memberOf = $memberOf}
                                          if ($mailAccountUID) {$bodyht.mailAccountUID = $mailAccountUID}
                                     if ($mailAccountPassword) {$bodyht.mailAccountPassword = ($mailAccountPassword|ConvertFrom-Securestring -AsPlainText)}
                                         if ($mailAccountHost) {$bodyht.mailAccountHost = $mailAccountHost}
                                          if ($mailAccountSSL) {$bodyht.mailAccountSSL = $mailAccountSSL}

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

        #region API Parameters
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
            HelpMessage                     = 'If true, certificates and private keys will not be deleted'
            )]
        [switch]$keepKeys,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'If true, the user is REALLY deleted from the database and is LOST forever'
            )]
        [switch]$purge,
        #endregion

        #region SMA Parameters
        [Parameter(Mandatory = $false)]
        [String]$host = $Script:activeCfg.SMAHost,

        [Parameter(Mandatory = $false)]
        [int]$port = $Script:activeCfg.SMAPort,

        [Parameter(Mandatory = $false)]
        [String]$version = $Script:activeCfg.SMAPIVersion,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$cred=$Script:activeCfg.SMACred,

        [Parameter(Mandatory=$false)]
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
            $uriPath = "{0}/{1}" -f 'user', $eMail
        }
        catch {
            Write-Error "Error$.categoryInfo happened"
        }
    }
    process {
        try {
            Write-Verbose "Building full request uri"
            $boundParam = @{ }

            if ($keepkeys) {$boundParam.keepkeys = $keepkeys}
               if ($purge) {$boundParam.purge = $purge}

            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
            $uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams;
    
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri           = $uri 
                Method        = 'DELETE'
                Cred          = $cred
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
# MIIVzAYJKoZIhvcNAQcCoIIVvTCCFbkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBON4USCSKwSMu3
# cRa9iW6i8IhVH2/V9l2iZhaAcaFc2KCCEggwggVvMIIEV6ADAgECAhBI/JO0YFWU
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
# BgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCCrIzcJqmagzdDuUEqJfN/jjt2p
# Q45J2IUXjLRP2qWO5zANBgkqhkiG9w0BAQEFAASCAgCSO9lZxBMiIzkRdsxmgZSn
# kC7OXLKoXCIhPAk5l8T8MGhe7BpjnxPafNV9mpn8hgMugszGljbF/wIwlw//05k4
# rIORsAp78DJYR71fkfXslAwFgADb/tjx/oD8e+pfn6t6v+dXG/eWizySMBLRS6sz
# QaGbhCjKGJ9k2tIMUR0W09pF+w02lwO5FnE1t0Al1heNb0cCAWhZoEfgJr3dYjcJ
# UQEdXNrXNqq/ggEuGSWowNlje5NPOvT/kh9Uo6gHlem3eOKCclywtRVzm4Ups+2k
# Wqdl+7pEpeYT9rY0ecdSbXTVBFBz4ZqCdSKwjEcPqDEqdQgGcF/oQzgBKXH5qOAv
# h5tpWYvQdbN7sACBDSscUnzxzjK0VdUBGt/22VDMlVrD5Y8bM9bVVj0KH4pQiVFQ
# msqk9MoXegsdeGZ74zaGFFt21pueFNS/3FJhIfwKbywrRo+0IyhgWNcroRP5jG60
# 1A7/TkY/7IsmR5LZjIHv6yiuqMDVsVSfQidtAPiJkVsggu5V5Wurhe98cMKZnF4A
# 2B+M3bvTgWSLUw3W8qBcjl9o7QuxJFbzeAfYmbXQMtEWOasgEvmQmpyvcV4kwA9i
# M3sM7Wd+6Nvexl0XhVGqDGGWI7sgmYQTn2vWZbdqhsU+bzog7SUljhjF+zw1a1+Z
# BtrRXSI6McVSRGx5PaV7zA==
# SIG # End signature block
