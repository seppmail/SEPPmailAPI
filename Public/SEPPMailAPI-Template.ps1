<#
.SYNOPSIS
List your templates.
.DESCRIPTION
This CmdLet lets you read the detailed properties of your templates.
.EXAMPLE
    PS C:\> Find-SMATemplate
    Emits all templates and their details - may take some time
.EXAMPLE
    PS C:\> Find-SMATemplate -List
    Emits all template names
#>
function Find-SMATemplate
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'Show list with template names only'
            )]
        [switch]$list,

        [Parameter(
             Mandatory = $false,
             HelpMessage = "Limit output to a specific template"
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
        $uriPath = 'mailsystem/template'

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
    Get information about a specific template
.DESCRIPTION
    This CmdLet lets you read the detailed properties of an existing template.
.EXAMPLE
    PS C:\> Get-SMATemplate -name 'Example'
    Get information about a template.
.EXAMPLE
    PS C:\> 'example1','example2'|Get-SMATemplate
    Use the pipeline to query multiple templates.
#>
function Get-SMATemplate
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'Template name'
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
            $uriPath = "{0}" -f 'mailsystem/template'

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
    Create a new SEPPmail template
.DESCRIPTION
    This CmdLet lets you create a new template.
#>
function New-SMATemplate
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
             Mandatory                       = $true,
             ValueFromPipelineByPropertyName = $true,
             ValueFromPipeline               = $true,
             HelpMessage                     = 'The template name'
         )]
        [string]$name,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$subject,

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
            $uriPath = "{0}" -f 'mailsystem/template'

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
                templateName = $name
                subject = $subject
                addHTMLPart = $addHtmlPart.ToBool()
                addTextPart = $addTextPart.ToBool()
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

            if ($PSCmdLet.ShouldProcess($($bodyht.Name),"Create template")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $tmp = Invoke-SMARestMethod @invokeParam

                Write-Verbose 'Returning name of template'
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
    Modifies a SEPPmail template
.DESCRIPTION
    This CmdLet lets you modify a template.
#>
function Set-SMATemplate
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
             Mandatory                       = $true,
             ValueFromPipelineByPropertyName = $true,
             ValueFromPipeline               = $true,
             HelpMessage                     = 'The template name'
         )]
        [string]$name,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        [string]$subject,

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
            $uriPath = "{0}/{1}" -f 'mailsystem/template', $name

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
                templateName = $name
                addHTMLPart = $addHtmlPart.ToBool()
                addTextPart = $addTextPart.ToBool()
                subject = $subject
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

            if ($PSCmdLet.ShouldProcess($($bodyht.Name),"Modfy template")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $tmp = Invoke-SMARestMethod @invokeParam

                Write-Verbose 'Returning name of template'
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
    Remove a SEPPmail template
.DESCRIPTION
    This CmdLet lets you delete a SEPPmail template.
.EXAMPLE
    PS C:\> Remove-SMATemplate -name 'example'
    Delete a template.
.EXAMPLE
    PS C:\> 'example1','example2'|Remove-SMATemplate
    Delete a template by using the pipeline
.EXAMPLE
    PS C:\> Remove-SMATemplate -name 'example' -WhatIf
    Simulate the template deletion
#>
function Remove-SMATemplate
{
    [CmdletBinding(DefaultParameterSetName = 'Default',SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            ParameterSetName                = 'Default',
            Position                        = 0,
            HelpMessage                     = 'The template you want to delete'
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
            $uriPath = "{0}/{1}" -f 'mailsystem/template', $name

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
            if ($PSCmdLet.ShouldProcess($name, "Remove template")){
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
List your template includes.
.DESCRIPTION
This CmdLet lets you read the detailed properties of your template includes.
.EXAMPLE
    PS C:\> Find-SMATemplateInclude
    Emits all template includes and their details - may take some time
.EXAMPLE
    PS C:\> Find-SMATemplateInclude -List
    Emits all template names
#>
function Find-SMATemplateInclude
{
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'Show list with template include names only'
            )]
        [switch]$list,

        [Parameter(
             Mandatory = $true,
             HelpMessage = "Limit output to a specific template"
         )]
        [string] $template,

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
        $uriPath = 'mailsystem/template/{0}/{1}' -f $template, $type

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
    Create a new SEPPmail template include
.DESCRIPTION
    This CmdLet lets you create a new template include.
#>
function New-SMATemplateInclude
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
             Mandatory                       = $true,
             ValueFromPipelineByPropertyName = $true,
             HelpMessage                     = 'The template name'
         )]
        [string]$template,

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
            $uriPath = "{0}/{1}/{2}" -f 'mailsystem/template', $template, $type

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

            if ($PSCmdLet.ShouldProcess($($bodyht.Name),"Create template include")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $tmp = Invoke-SMARestMethod @invokeParam

                Write-Verbose 'Returning name of template include'
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
    Remove a SEPPmail template include
.DESCRIPTION
    This CmdLet lets you delete a SEPPmail template include.
.EXAMPLE
    PS C:\> Remove-SMATemplateInclue -name 'logo' -type inline -template example
    Delete a template include.
#>
function Remove-SMATemplateInclude
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
             HelpMessage = 'The template name'
         )]
        [string]$template,

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
            $uriPath = "{0}/{1}/{2}" -f 'mailsystem/template', $template, $type

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
            if ($PSCmdLet.ShouldProcess($name, "Remove template")){
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
