<#
.SYNOPSIS
    Get a list of locally existing groups
.DESCRIPTION
    This CmdLet shows locally existing grops from the SEPPmail appliance.
.EXAMPLE
    PS C:\> Find-SMAGroup
.EXAMPLE
    # Get list of groups and filter by group name
    PS C:\> Find-SMAgroup -list|Where-Object {$_ -like '*P*'}
.EXAMPLE
    # Get groups and filter by group name
    PS C:\> Find-SMAgroup|Where-Object {$_.name -like '*P*'}
#>
function Find-SMAGroup
{
    [CmdletBinding()]
    param (
        #region REST-API path and query parameters
        [Parameter(
            Mandatory                       = $false,
            HelpMessage                     = 'List only of extended output'
            )]
        [switch]$list = $false,
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
            $uriPath = "{0}" -f 'group'
    
            Write-Verbose "Building full request uri"
            $boundParam = @{}
                if ($list -eq $true) {$boundparam.list = $true}
                if ($list -eq $false) {$boundparam.list = $false}
                
            $smaParams = @{
                Host    = $Host;
                Port    = $Port;
                Version = $Version;
            }
            
            $uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams
            
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri 
                Method      = 'GET'
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }
    
            Write-Verbose "Call Invoke-SMARestMethod $uri" 
            $groupRaw = Invoke-SMARestMethod @invokeParam
    
            #Write-Verbose 'Filter data and return as PSObject'
            #$getGroup = $groupRaw.Psobject.properties.value
    
            Write-Verbose 'Converting Umlauts from ISO-8859-1'
            $group = ConvertFrom-SMAPIFormat -inputObject $groupRaw
    
            # Userobject
            if ($group) {
                return $group
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
    Create a new SEPPmail local administrative groups
.DESCRIPTION
    This CmdLet lets you create a new group. You need at least 3 properties to create a user (name, description and at leaset one member)
.EXAMPLE
    PS C:\> New-SMAGroup -name 'MyAdmins' -description 'my special admins' -members 'admin1@contoso.de','admin2@contoso.de'
#>
function New-SMAGroup
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'The groupss full name'
            )]
        [string]$name,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'The groups description'
            )]
        [string]$description,

        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'The groups members e-mail adresses'
            )]
        [string[]]$members,


        #region Host configuration parameters
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
        #endregion
    )

    begin {
        if (! (verifyVars -VarList $Script:requiredVarList))
        {
            Throw($missingVarsMessage);
        }; # end if

        try {
            Write-Verbose "Building full request uri"
            $smaParams = @{
                Host    = $Host;
                Port    = $Port;
                Version = $Version;
            }; # end smaParams

            $uri = New-SMAQueryString -uriPath 'group' @smaParams;
        }
        catch {
            Write-Error "Error $error.CategoryInfo occured"
        }
    }

    process {
        try {
            Write-Verbose 'Crafting mandatory $body JSON'
            $bodyht = @{
                name        = $name
                description = $description
                members     = @($members)
            }
            
            $body = $bodyht | ConvertTo-JSON
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri           = $uri 
                Method        = 'POST'
                body          = $body
                Cred          = $cred
                SkipCertCheck = $SkipCertCheck
            }

            if ($PSCmdLet.ShouldProcess($($bodyht.name), "Create group")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri"
                $groupRaw = Invoke-SMARestMethod @invokeParam
                #debug $userraw
                #Write-Verbose 'Returning e-Mail address of new users'
                #($groupRaw.message -split ' ')[3]
                return $groupraw
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
    Modyfies a SEPPmail group
.DESCRIPTION
    This CmdLet lets you modity an existing user. You need the email address to identify the user.
.EXAMPLE
    PS C:\> Set-SMAGroup -name 'myGroup'
    Change the UserName of m.musterfrau@contoso.com
.EXAMPLE
    PS C:\> $groupinfo = @{
        Name = 'myGroup'
        description = 'This group is for demo purposes'
        members = @('admin@contoso.de','admin@contoso.chS')
    }
    PS C:\> Set-SMAgroup @groupInfo
    Example of all parameters possible to change a user using parameter splatting
#>
function Set-SMAGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        #region
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The groups name'
        )]
        [string]$name,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'The groups description'
        )]
        [string]$description,

        [Parameter(
            Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Array of group mambers'
        )]
        [string[]]$members,
        #endregion data parameter

        #region Host parameter
        [Parameter(Mandatory = $false)]
        [String]$host = $Script:activeCfg.SMAHost,

        [Parameter(Mandatory = $false)]
        [int]$port = $Script:activeCfg.SMAPort,

        [Parameter(Mandatory = $false)]
        [String]$version = $Script:activeCfg.SMAPIVersion,

        [Parameter(
            Mandatory = $false
        )]
        [System.Management.Automation.PSCredential]$cred = $Script:activeCfg.SMACred,

        [Parameter(
            Mandatory = $false
        )]
        [switch]$SkipCertCheck = $Script:activeCfg.SMAskipCertCheck 
        #endregion Host parameter
    )
    begin {
        if (! (verifyVars -VarList $Script:requiredVarList)) {
            Throw($missingVarsMessage);
        }; # end if
    }
    process {
        try {
            
            Write-Verbose "Creating URL path"
            $uriPath = "{0}/{1}" -f 'group', $name
            Write-Verbose "Building full request uri"
            $boundParam = @{
                customer = $customer
            }
            $smaParams = @{
                Host    = $Host;
                Port    = $Port;
                Version = $Version;
            }

            $uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams;
            
            Write-Verbose 'Crafting mandatory $body JSON'
            $bodyht = @{
                name        = $name
                description = $description
                members     = @($members)
            }
            
            $body = $bodyht | ConvertTo-JSON

            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri           = $uri 
                Method        = 'PUT'
                body          = $body
                Cred          = $cred
                SkipCertCheck = $SkipCertCheck
            }
            #debug $uri
            if ($PSCmdLet.ShouldProcess($($bodyht.Email), "Change user")) {
                Write-Verbose "Call Invoke-SMARestMethod $uri" 
                $groupRaw = Invoke-SMARestMethod @invokeParam
            }
            if ($groupRaw) {
                return $groupRaw
            }
            else {
                Write-Information 'Nothing to return'
            }

        }
        catch {
            Write-Error "An error occured, see $error.CategoryInfo"
        }
    }
}

<#
.SYNOPSIS
    Get a list of locally existing groups
.DESCRIPTION
    This CmdLet shows locally existing grops from the SEPPmail appliance.
.EXAMPLE
    # Get details of a specific group
    PS C:\> Get-SMAGroup -Name 'myGroup'
#>
function Get-SMAGroup
{
    [CmdletBinding()]
    param (
        #region REST-API path and query parameters
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'The groupss full name'
            )]
        [string]$name,
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
            $uriPath = "{0}/{1}" -f 'group',$name
    
            $smaParams = @{
                Host    = $Host;
                Port    = $Port;
                Version = $Version;
            }
            
            $uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams
            
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri           = $uri 
                Method        = 'GET'
                Cred          = $cred
                SkipCertCheck = $SkipCertCheck
            }
    
            Write-Verbose "Call Invoke-SMARestMethod $uri" 
            $groupRaw = Invoke-SMARestMethod @invokeParam
    
            #Write-Verbose 'Filter data and return as PSObject'
            #$getGroup = $groupRaw.Psobject.properties.value
    
            Write-Verbose 'Converting Umlauts from ISO-8859-1'
            $group = ConvertFrom-SMAPIFormat -inputObject $groupRaw
    
            # Userobject
            if ($group) {
                return $group.psobject.properties.value
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
    Remove a SEPPmail group
.DESCRIPTION
    This CmdLet lets you delete a SEPPmail group. You need the name of the group.
.EXAMPLE
    PS C:\> Remove-SMAgroup -name 'myGroup'
    Delete a locally existing group.
#>
function Remove-SMAGroup
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        #region API Params
        [Parameter(
            Mandatory                       = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromPipeline               = $true,
            HelpMessage                     = 'User E-Mail address'
            )]
        [string]$name,

        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage                     = 'If all also users in this group will be deleted, if -allButKeepKeys- is selected the keys are preserved'
            )]
        [validateSet('no', 'allButKeepKeys', 'all')]
        [string]$deleteUsers = 'no',
        #endregion

        #region Hostpaameters
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
        #endregion
    )

    begin {
        if (! (verifyVars -VarList $Script:requiredVarList))
        {
            Throw($missingVarsMessage);
        }; # end if

        try {
            Write-Verbose "Creating URL path"
            $uriPath = "{0}/{1}" -f 'group', $name
        }
        catch {
            Write-Error "Error$.categoryInfo happened"
        }
    }
    process {
        try {
            Write-Verbose "Building full request uri"
            $boundParam = @{
                deleteUsers  = $deleteUsers
            }
            
            $smaParams = @{
                Host    = $Host;
                Port    = $Port;
                Version = $Version;
            }
            
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
                $groupRaw = Invoke-SMARestMethod @invokeParam

                Write-Verbose 'Converting Umlauts from ISO-8859-1'
                $group = ConvertFrom-SMAPIFormat -inputObject $groupRaw #|convertfrom-Json -AsHashtable
    
                # Gina-Userobject
                if ($group) {
                    return $group
                }
                else {
                    Write-Information 'No matching group found, nothing to return'
                }
            }
        }
        catch {
            Write-Error "An error occured, see $error.CategoryInfo"
        }
    }
}
#>

Write-Verbose 'Create CmdLet Alias for GINA users' 
$custVerbs = ('New','Remove','Get','Find','Set')

Foreach ($custverb in $custVerbs) {
    $aliasname1 = $custverb + '-SMAGR'
    $cmdName = $custverb + '-SMAGroup'
    New-Alias -Name $aliasName1 -Value $cmdName
}

# SIG # Begin signature block
# MIIL1wYJKoZIhvcNAQcCoIILyDCCC8QCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUHfvrkBBDVQpS5u7WI/ARHc1v
# LqSggglAMIIEmTCCA4GgAwIBAgIQcaC3NpXdsa/COyuaGO5UyzANBgkqhkiG9w0B
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
# MRYEFMyN62X73XVa3JQPxrVeulwBhXVnMA0GCSqGSIb3DQEBAQUABIIBAG3ygbMn
# U5oLSEMHPrl47RaXKkRT/iN689LLj+cH4LscZK2CAsrRzuGQUhPu21NcAjzO7IyN
# j/M/kPGaLzM4cnbSjQdJNEW0iEQWtjU1SnRNxD4/HWPCHNjeyS+gAq4gETaU7tds
# O3xoD7SCGezZbCCrqvd5QQzsuywEtRB0DYpTBjU79yqHZKqpTnJKJ9tbNYmbjcri
# VEe0k/UxMUXXU9J7vLGOJ+KW/bN/4jEzrKQNGpKw3n5iqjB3uURm7gjqCakVPOH7
# 2BNumyazUhtY7zHbn9LWZyevQ0A+WYOlXP2QUYTyrdOY9YkmMmeGzKSquI9OK+yl
# ohwE/J/vgZzqjGg=
# SIG # End signature block
