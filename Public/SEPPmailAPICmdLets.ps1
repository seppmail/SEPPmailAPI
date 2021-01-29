<#
.SYNOPSIS
    Get a single locally existing users properties
.DESCRIPTION
    This CmdLet lets you read the detailed properties of an existing user.
.EXAMPLE
    PS C:\> Get-SMUser 
.EXAMPLE
    PS C:\> Get-SMUser -eMailAddress 'alice.miller@contoso.com'
    Get information about a SEPPmail user
.EXAMPLE
    PS C:\> Get-SMUser -eMailAddress 'alice.miller@contoso.com' -Customer 'Contoso'
    Get information about a SEPPmail user
#>
function Get-SMUser
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'User E-Mail address'
            )]
        [ValidatePattern('([a-z0-9][-a-z0-9_\+\.]*[a-z0-9])@([a-z0-9][-a-z0-9\.]*[a-z0-9]\.(arpa|root|aero|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|net|org|pro|tel|travel|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)|([0-9]{1,3}\.{3}[0-9]{1,3}))')]
        [string]$eMail,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'For MSP´s and multi-customer environments, set the GINA users customer'
            )]
        [string]$customer
    )

    try {
        Write-Verbose "Creating URL root"
        $urlRoot = New-SMUrlRoot -SMHost $SMHost -SMPort $SMPort
        if ($customer) {
            $uri = "{0}{1}/{2}?customer={3}" -f $urlroot, 'user', $eMail, $customer
        }
        else {
            $uri = "{0}{1}/{2}" -f $urlroot, 'user', $eMail
        }

        Write-verbose "Crafting Invokeparam for Invoke-SMrestMethod"
        $invokeParam = @{
            Uri         = $uri 
            Method      = 'GET'
        }

        Write-Verbose "Call Invoke-SMRestMethod $uri" 
        $UserRaw = Invoke-SMRestMethod @invokeParam

        Write-Verbose 'Filter data and return as PSObject'
        $GetUser = $userraw.Psobject.properties.value

        if ($GetUser) {return $GetUser}
        else {Write-Information 'Nothing to return'}

    }
    catch {
        Write-Error "An error occured, see $error"
    }
}

<#
.SYNOPSIS
    Find a locally existing users and details
.DESCRIPTION
    This CmdLet lets you read the detailed properties of multiple users.
.EXAMPLE
    PS C:\> Find-SMUser
    Emits all users and their details - may take some time
.EXAMPLE
    PS C:\> Find-SMUser -customer 'Contoso'
    Emits all users of a particular customer
#>
function Find-SMUser
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'For MSP´s and multi-customer environments, limit query for a specific customer'
            )]
        [string]$customer

        <#
        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Show list with e-mail address only'
            )]
        [switch]$list
        #>

    )

    try {
        Write-Verbose "Creating URL root"
        $urlRoot = New-SMUrlRoot -SMHost $SMHost -SMPort $SMPort
        if ($customer) {
            $uri = "{0}{1}?customer={2}" -f $urlroot, 'user', $customer
        }
        else {
            $uri = "{0}{1}" -f $urlroot, 'user'
        }

        <#Write-Verbose "Adding Listonly if requested"
        if ($list) {
            $uri = "{0}{1}" -f $uri, '?list=true'
        }
        #>

        Write-verbose "Crafting Invokeparam for Invoke-SMrestMethod"
        $invokeParam = @{
            Uri         = $uri 
            Method      = 'GET'
        }

        Write-Verbose "Call Invoke-SMRestMethod $uri" 
        $UserRaw = Invoke-SMRestMethod @invokeParam

        Write-Verbose 'Filter data and return as PSObject'

        <#if ($list) {
            $FindUser = $userraw
        }
        #>
        #else {
            $FindUser = $userraw.Psobject.properties.value
        #}

        if ($FindUser) {return $FindUser}
        else {Write-Information 'Nothing to return'}

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
    PS C:\> New-SMUser -uid 'm.musterfrau@contoso.com' -email 'm.musterfrau@contoso.com' -Name 'Maria Musterfrau'
    Basic information about a user. uid and email are identical
.EXAMPLE
    PS C:\> $UID = (New-Guid).guid
    PS C:\> New-SMUser -uid $uid -email 'm.musterfrau@contoso.com' -Name 'Maria Musterfrau'
    Basic information about a user. uid is a GUID
.EXAMPLE
    PS C:\> $userinfo = @{
        uid = '245b8741-4724-4434-8343-bc26c9a10586'
        email = 'm.musterfrau@contoso.com'
        Name = 'Maria Musterfrau'
        locked = $false
        mayNotEncrypt = $false
        mayNotSign = $false
        password = 'aBc1$6tgR'
        customer = 'Contoso'
        notifications = 'never'
        mpkiSubjectPart = ''
    }
    PS C:\> New-SMUser @userInfo
    Example of all parameters possible to create a user using parameter splatting
#>
function New-SMUser
{
    [CmdletBinding()]
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
        [ValidatePattern('([a-z0-9][-a-z0-9_\+\.]*[a-z0-9])@([a-z0-9][-a-z0-9\.]*[a-z0-9]\.(arpa|root|aero|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|net|org|pro|tel|travel|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)|([0-9]{1,3}\.{3}[0-9]{1,3}))')]
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
        [string]$password,

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
        [bool]$mayNotEncrypt,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Disable the sign functionality for the user, API default is $false'
            )]
        [bool]$mayNotSign,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Lock this user, API default is $false'
            )]
        [bool]$locked,

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
        [string]$mpkiSubjectPart
    
    )

    try {
        Write-Verbose "Creating URL root"
        $urlRoot = New-SMUrlRoot -SMHost $SMHost -SMPort $SMPort
        $uri = "{0}{1}/" -f $urlroot, 'user'

        Write-Verbose 'Crafting mandatory $body JSON'
        $bodyht = @{
            uid = $uid
            name = $name
            email = $email
        }
        Write-Verbose 'Adding Optional values to $body JSON'
        if ($customer) {$bodyht.customer = $customer}
        if ($locked) {$bodyht.locked = $false}
        if ($mayNotEncrypt) {$bodyht.mayNotEncrypt = $mayNotEncrypt}
        if ($mayNotSign) {$bodyht.mayNotSign = $mayNotSign}
        if ($mpkiSubjectPart) {$bodyht.mpkiSubjectPart = $mpkiSubjectPart}
        if ($notifications) {$bodyht.notifications = $notifications}
        
        $body = $bodyht|ConvertTo-JSON
        Write-verbose "Crafting Invokeparam for Invoke-SMrestMethod"
        $invokeParam = @{
            Uri         = $uri 
            Method      = 'POST'
            body        = $body
        }
        #debug $uri
        Write-Verbose "Call Invoke-SMRestMethod $uri" 
        $UserRaw = Invoke-SMRestMethod @invokeParam
        #debug $userraw
        Write-Verbose 'Returning e-Mail addresses of new users'
        ($userraw.message -split ' ')[3]
    }
    catch {
        Write-Error "An error occured, see $error"
    }
}

<#
.SYNOPSIS
    Modyfies a SEPPmail user
.DESCRIPTION
    This CmdLet lets you modity an existing user. You need the email address to identify the user.
.EXAMPLE
    PS C:\> Set-SMUser -email 'm.musterfrau@contoso.com' -Name 'Martha Musterfrau'
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
    PS C:\> New-SMUser @userInfo
    Example of all parameters possible to create a user using parameter splatting
#>
function Set-SMUser
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'User E-Mail address'
            )]
        [ValidatePattern('([a-z0-9][-a-z0-9_\+\.]*[a-z0-9])@([a-z0-9][-a-z0-9\.]*[a-z0-9]\.(arpa|root|aero|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|net|org|pro|tel|travel|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)|([0-9]{1,3}\.{3}[0-9]{1,3}))')]
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
        [string]$password,

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
        [bool]$mayNotEncrypt,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Disable the sign functionality for the user, API default is $false'
            )]
        [bool]$mayNotSign,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'Lock this user, API default is $false'
            )]
        [bool]$locked,

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
        [string]$mpkiSubjectPart
    
    )

    try {
        Write-Verbose "Creating URL root"
        $urlRoot = New-SMUrlRoot -SMHost $SMHost -SMPort $SMPort
        $uri = "{0}{1}/{2}" -f $urlroot, 'user', $eMail

        Write-Verbose 'Crafting mandatory $body JSON'
        $bodyht = @{
            email = $email
        }
        Write-Verbose 'Adding optional values to $body JSON'
        if ($name) {$bodyht.name = $name}
        if ($customer) {$bodyht.customer = $customer}
        if ($locked) {$bodyht.locked = $false}
        if ($mayNotEncrypt) {$bodyht.mayNotEncrypt = $mayNotEncrypt}
        if ($mayNotSign) {$bodyht.mayNotSign = $mayNotSign}
        if ($mpkiSubjectPart) {$bodyht.mpkiSubjectPart = $mpkiSubjectPart}
        if ($notifications) {$bodyht.notifications = $notifications}
        
        $body = $bodyht|ConvertTo-JSON
        Write-verbose "Crafting Invokeparam for Invoke-SMrestMethod"
        $invokeParam = @{
            Uri         = $uri 
            Method      = 'PUT'
            body        = $body
        }
        #debug $uri
        Write-Verbose "Call Invoke-SMRestMethod $uri" 
        $UserRaw = Invoke-SMRestMethod @invokeParam
        #debug $userraw
        Write-Verbose 'Returning e-Mail addresses of new users'
        ($userraw.message -split ' ')[3]
    }
    catch {
        Write-Error "An error occured, see $error"
    }
}


<#
.SYNOPSIS
    Remove a SEPPmail user
.DESCRIPTION
    This CmdLet lets you delete a SEPPmail user. You need the e-Mail address of the user. Optionally it is possible to leave the certificates and keys in the appliance.
.EXAMPLE
    PS C:\> Remove-SMUser -email 'm.musterfrau@contoso.com'
    Delete a user and all keys and certificates.
.EXAMPLE
    PS C:\> Remove-SMUser -email 'm.musterfrau@contoso.com' -keepKeys
    Delete a user but leave the keys. If you recreate the user with the same email address, the keys will be re-attached.
#>
function Remove-SMUser
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'User E-Mail address'
            )]
        [ValidatePattern('([a-z0-9][-a-z0-9_\+\.]*[a-z0-9])@([a-z0-9][-a-z0-9\.]*[a-z0-9]\.(arpa|root|aero|biz|cat|com|coop|edu|gov|info|int|jobs|mil|mobi|museum|name|net|org|pro|tel|travel|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)|([0-9]{1,3}\.{3}[0-9]{1,3}))')]
        [string]$eMail,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'if true certificates and private keys will not be deleted'
            )]
        [switch]$keepKeys,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'For MSP´s and multi-customer environments'
            )]
        [string]$customer
    )

    try {
        Write-Verbose "Creating URL root"
        $urlRoot = New-SMUrlRoot -SMHost $SMHost -SMPort $SMPort
        if ($customer) {
            $uri = "{0}{1}/{2}?customer={3}" -f $urlroot, 'user', $eMail, $customer
            }
        else {
            $uri = "{0}{1}/{2}" -f $urlroot, 'user', $eMail
            }

        Write-verbose "Crafting Invokeparam for Invoke-SMrestMethod"
        $invokeParam = @{
            Uri         = $uri 
            Method      = 'DELETE'
            }
        Write-Verbose "Call Invoke-SMRestMethod $uri" 
        $UserRaw = Invoke-SMRestMethod @invokeParam
        Write-Verbose 'Returning e-Mail addresses of new users'
        ($userraw.message -split ' ')[3]
    }
    catch {
        Write-Error "An error occured, see $error"
    }
}
