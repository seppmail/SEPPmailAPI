<#
.SYNOPSIS
List your disclaimers.
.DESCRIPTION
This CmdLet lets you read the detailed properties of your disclaimers.
.EXAMPLE
    PS C:\> Find-SMADisclaimer
    Emits all disclaimers and their details - may take some time
.EXAMPLE
    PS C:\> Find-SMADisclaimer -List
    Emits all disclaimer names
#>
function Find-SMADisclaimer
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'Show list with disclaimer names only'
            )]
        [switch]$list,

        [Parameter(
             Mandatory = $false,
             HelpMessage = "Limit output to a specific disclaimer"
         )]
        [string] $name,

        [Parameter(
             Mandatory = $false,
             HelpMessage = "Also return base64 encoded data of inlines and attachments"
         )]
        [switch] $withData,

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
        $uriPath = 'mailsystem/disclaimer'

        Write-verbose "Build Parameter hashtable"
        $boundParam = @{}

        if($list)
        {$boundParam["list"] = $true}
        if($name)
        {$boundParam["name"] = $name}
        if($customer)
        {$boundParam["withData"] = $true}

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
    Get information about a specific disclaimer
.DESCRIPTION
    This CmdLet lets you read the detailed properties of an existing disclaimer.
.EXAMPLE
    PS C:\> Get-SMADisclaimer -name 'Example'
    Get information about a disclaimer.
.EXAMPLE
    PS C:\> 'example1','example2'|Get-SMADisclaimer
    Use the pipeline to query multiple disclaimers.
#>
function Get-SMADisclaimer
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'Diclaimer name'
            )]
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
            $uriPath = "{0}" -f 'mailsystem/disclaimer'

            Write-Verbose "Build QueryString"
            $smaParams=@{
                Host=$Host;
                Port=$Port;
                Version=$Version;
            }; # end smaParams
            $uri = New-SMAQueryString -uriPath $uriPath @smaParams -qParam @{name = $name}

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
    Create a new SEPPmail disclaimer
.DESCRIPTION
    This CmdLet lets you create a new disclaimer.
#>
function New-SMADisclaimer
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
             Mandatory                       = $true,
             ValueFromPipelineByPropertyName = $true,
             ValueFromPipeline               = $true,
             HelpMessage                     = 'The disclaimer name'
         )]
        [string]$name,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [switch]$addHtmlPart,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [switch]$addTextPart,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [switch]$forceUtf8,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [switch]$addEmptyParts,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$html,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string] $plainText,

        [Parameter(
            Mandatory = $false,
             ValueFromPipelineByPropertyName = $true,
             HelpMessage = 'An array of hashtables like so: @{fileName = "logo.gif"; fileData  = "base64"; contentType = "image/gif"; contentID = "logo"}'
        )]
        [hashtable[]] $inlines,

        [Parameter(
             Mandatory                       = $false,
             ValueFromPipelineByPropertyName = $true,
             HelpMessage = 'An array of hashtables like so: @{fileName = "logo.gif"; fileData = "base64"; contentType = "image/gif"; contentID = "logo" }'

            )]
        [hashtable[]]$attachments,

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
            $uriPath = "{0}" -f 'mailsystem/disclaimer'

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
                disclaimerName = $name
                addHTMLPart = $addHtmlPart.ToBool()
                addTextPart = $addTextPart.ToBool()
                forceUTF8 = $forceUtf8.ToBool()
                addEmptyParts = $addEmptyParts.ToBool()
            }

            Write-Verbose 'Adding Optional values to $body JSON'

            if($html)
            {$bodyht.html = $html}
            if($plainText)
            {$bodyht.text = $plainText}

            if($inlines)
            {$bodyht.inlines = $inlines}
            if($attachments)
            {$bodyht.attachments = $attachments}

            $body = $bodyht|ConvertTo-JSON

            $invokeParam = @{
                Uri         = $uri
                Method      = 'POST'
                body        = $body
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }

            if ($PSCmdLet.ShouldProcess($($bodyht.Name),"Create disclaimer")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $tmp = Invoke-SMARestMethod @invokeParam

                Write-Verbose 'Returning name of disclaimer'
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
    Modifies a SEPPmail disclaimer
.DESCRIPTION
    This CmdLet lets you modify a disclaimer.
#>
function Set-SMADisclaimer
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
             Mandatory                       = $true,
             ValueFromPipelineByPropertyName = $true,
             ValueFromPipeline               = $true,
             HelpMessage                     = 'The disclaimer name'
         )]
        [string]$name,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [switch]$addHtmlPart,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [switch]$addTextPart,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [switch]$forceUtf8,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [switch]$addEmptyParts,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$html,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string] $plainText,

        [Parameter(
            Mandatory = $false,
             ValueFromPipelineByPropertyName = $true,
             HelpMessage = 'An array of hashtables like so: @{fileName = "logo.gif"; fileData  = "base64"; contentType = "image/gif"; contentID = "logo"}'
        )]
        [hashtable[]] $inlines,

        [Parameter(
             Mandatory                       = $false,
             ValueFromPipelineByPropertyName = $true,
             HelpMessage = 'An array of hashtables like so: @{fileName = "logo.gif"; fileData = "base64"; contentType = "image/gif"; contentID = "logo" }'

            )]
        [hashtable[]]$attachments,

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
            $uriPath = "{0}/{1}" -f 'mailsystem/disclaimer', $name

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
                disclaimerName = $name
                addHTMLPart = $addHtmlPart.ToBool()
                addTextPart = $addTextPart.ToBool()
                forceUTF8 = $forceUtf8.ToBool()
                addEmptyParts = $addEmptyParts.ToBool()
            }

            Write-Verbose 'Adding Optional values to $body JSON'

            if($html)
            {$bodyht.html = $html}
            if($plainText)
            {$bodyht.text = $plainText}

            if($inlines)
            {$bodyht.inlines = $inlines}
            if($attachments)
            {$bodyht.attachments = $attachments}

            $body = $bodyht|ConvertTo-JSON

            $invokeParam = @{
                Uri         = $uri
                Method      = 'PUT'
                body        = $body
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }

            if ($PSCmdLet.ShouldProcess($($bodyht.Name),"Modfy disclaimer")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $tmp = Invoke-SMARestMethod @invokeParam

                Write-Verbose 'Returning name of disclaimer'
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
    Remove a SEPPmail disclaimer
.DESCRIPTION
    This CmdLet lets you delete a SEPPmail disclaimer.
.EXAMPLE
    PS C:\> Remove-SMADisclaimer -name 'example'
    Delete a disclaimer.
.EXAMPLE
    PS C:\> 'example1','example2'|Remove-SMADisclaimer
    Delete a disclaimer by using the pipeline
.EXAMPLE
    PS C:\> Remove-SMADisclaimer -name 'example' -WhatIf
    Simulate the disclaimer deletion
#>
function Remove-SMADisclaimer
{
    [CmdletBinding(DefaultParameterSetName = 'Default',SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            ParameterSetName                = 'Default',
            Position                        = 0,
            HelpMessage                     = 'The disclaimer you want to delete'
            )]
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
            $uriPath = "{0}/{1}" -f 'mailsystem/disclaimer', $name

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
            if ($PSCmdLet.ShouldProcess($name, "Remove disclaimer")){
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


    <#
.SYNOPSIS
List your disclaimer includes.
.DESCRIPTION
This CmdLet lets you read the detailed properties of your disclaimer includes.
.EXAMPLE
    PS C:\> Find-SMADisclaimerInclude
    Emits all disclaimer includes and their details - may take some time
.EXAMPLE
    PS C:\> Find-SMADisclaimerInclude -List
    Emits all disclaimer names
#>
function Find-SMADisclaimerInclude
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'Show list with disclaimer include names only'
            )]
        [switch]$list,

        [Parameter(
             Mandatory = $true,
             HelpMessage = "Limit output to a specific disclaimer"
         )]
        [string] $disclaimer,

        [Parameter(
             Mandatory = $false,
             HelpMessage = "Also return base64 encoded data of inlines and attachments"
         )]
        [switch] $withData,

        [Parameter(
             Mandatory = $true,
             HelpMessage = "Type of the include (inline or attachment)"
         )]
        [ValidateSet('inline', 'attachment')]
        [string] $type,

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
        $uriPath = 'mailsystem/disclaimer/{0}/{1}' -f $disclaimer, $type

        Write-verbose "Build Parameter hashtable"
        $boundParam = @{}

        if($list)
        {$boundParam["list"] = $true}
        if($customer)
        {$boundParam["withData"] = $true}

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
    Create a new SEPPmail disclaimer include
.DESCRIPTION
    This CmdLet lets you create a new disclaimer include.
#>
function New-SMADisclaimerInclude
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
             Mandatory                       = $true,
             ValueFromPipelineByPropertyName = $true,
             HelpMessage                     = 'The disclaimer name'
         )]
        [string]$disclaimer,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true
            )]
        [ValidateSet('inline', 'attachment')]
        [string]$type,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$fileName,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$fileData,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$contentType,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$contentId,

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
            $uriPath = "{0}/{1}/{2}" -f 'mailsystem/disclaimer', $disclaimer, $type

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
                fileName = $fileName
                fileDate = $fileData
                contentType = $contentType
                contentID = $contentId
            }

            Write-Verbose 'Adding Optional values to $body JSON'

            $body = $bodyht|ConvertTo-JSON

            $invokeParam = @{
                Uri         = $uri
                Method      = 'POST'
                body        = $body
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }

            if ($PSCmdLet.ShouldProcess($($bodyht.Name),"Create disclaimer include")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $tmp = Invoke-SMARestMethod @invokeParam

                Write-Verbose 'Returning name of disclaimer include'
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
    Remove a SEPPmail disclaimer include
.DESCRIPTION
    This CmdLet lets you delete a SEPPmail disclaimer include.
.EXAMPLE
    PS C:\> Remove-SMADisclaimerInclue -name 'logo' -type inline -disclaimer example
    Delete a disclaimer include.
#>
function Remove-SMADisclaimerInclude
{
    [CmdletBinding(DefaultParameterSetName = 'Default',SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            ParameterSetName                = 'Default',
            Position                        = 0,
            HelpMessage                     = 'Name of the includes you want to delete'
            )]
        [string[]]$name,

        [Parameter(
             Mandatory = $true,
             ValueFromPipelineByPropertyName = $true,
             HelpMessage = 'The disclaimer name'
         )]
        [string]$disclaimer,

        [Parameter(
             Mandatory = $true,
             ValueFromPipelineByPropertyName = $true
         )]
        [ValidateSet('inline', 'attachment')]
        [string]$type,

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
            $uriPath = "{0}/{1}/{2}" -f 'mailsystem/disclaimer', $disclaimer, $type

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
            if ($PSCmdLet.ShouldProcess($name, "Remove disclaimer")){
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                # Wait-Debugger
                $tmp = Invoke-SMARestMethod @invokeParam -Body $name
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
# MIIL1wYJKoZIhvcNAQcCoIILyDCCC8QCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUWmQ+9IU/9Zigc5puBlBNzFqh
# uRSggglAMIIEmTCCA4GgAwIBAgIQcaC3NpXdsa/COyuaGO5UyzANBgkqhkiG9w0B
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
# MRYEFG5SwvMv9DWWUejQPlZ+pJfXtcaXMA0GCSqGSIb3DQEBAQUABIIBABQiIkxg
# 9TbAqyHK+Yhn6BHg9qZ/QNABI2qT69uTC6isBE63SMkZgXhrOqGfUcQ0lAiTQHo/
# +vQhAii1dLhtfMg7h1WLwTYa8o0aPVVNslEAiCPsNJ6FLhWkzFf1J2QPjWnxRHaF
# TQxHaLKuaw4/sxEpWpeYxKFa/x+dnW1YaYEXY79jqzoBQfuYH/mL8aBMszTyTu1j
# oymNdeSrbKkzk8qCpQhA41EWGpaXLdp7U3RC0Y/qLT9yb0fWW2GTOAJgaIlj+sRd
# 7iPgXDodyCDeori4KP8qeF1WrBGOPfcgsMyh5ieD3p8Pn/49w/HBBVNTyXKOwdGK
# d9cAEj1/nsNr3Ek=
# SIG # End signature block
