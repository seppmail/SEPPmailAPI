<#
.SYNOPSIS
    Gets Information about statistics of your SEPPmail appliance
.DESCRIPTION
    This CmdLet emits information about what the SEPPmail has done over time. Options are all/user or domain .
.EXAMPLE
    PS C:\> Get-SMAStatistics
    With this CmdLet you get information about the statistics information.
    This returns all available statistics (Default value -type all)
.EXAMPLE
    PS C:\> Get-SMAEncInfo -type user
    This provides the same information as without parameters, just filters to users
.EXAMPLE
    PS C:\> Get-SMAEncInfo -type domain
    This provides the same information as without parameters, just filters to users
.EXAMPLE
    PS C:\> Get-SMAStatistics -rebuildList
    The -rebuild switch parameter rebuilds the statistic database to get accurate information. Makes the request slower. The -rebuildList switch can be combined with the -type parameter -type
#>
function Get-SMAStatistics
{
    [CmdletBinding()]
    param (
        [Parameter(
                   Mandatory = $false,
                 HelpMessage = 'Rebuild statistics database'
        )]
        [switch]$rebuildList,
    
        [Parameter(
                   Mandatory = $false,
                 HelpMessage = 'Filter to a specific statistics type'
        )]
        [ValidateSet('user', 'domain', 'all')]
        [String]$type = 'all',

        #region Config parameters block
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
                $uriPath = "statistics"
        }
        catch {
            Write-Error "Error$.categoryInfo happened setting REST-Path variables "
        }
    }
    process {
        try {
    
            Write-Verbose "Building full request uri"
            $smaParams = @{
                Host    = $Host
                Port    = $Port
                Version = $Version
            } # end smaParams

            $uri = $null
            $boundParam = @{
                type = $type
                rebuildList = if ($rebuildList) {$true} else {$false}
            }
            $uri = New-SMAQueryString -uriPath $uriPath -qParam $boundParam @smaParams

            
            Write-verbose "Crafting Invokeparam for Invoke-SMARestMethod"
            $invokeParam = @{
                Uri         = $uri 
                Method      = 'GET'
                Cred        =  $cred
                SkipCertCheck = $SkipCertCheck
            }
    
            Write-Verbose "Replace wrong '%40' value with '@'"
            $invokeparam.Uri = ($invokeParam.Uri).Replace('%40','@')

            Write-Verbose "Call Invoke-SMARestMethod $uri" 
            $statsInfo = Invoke-SMARestMethod @invokeParam

            #Write-Verbose 'Converting Umlauts from ISO-8859-1'
            #Encinfo = ConvertFrom-SMAPIFormat -inputObject $encInfoRaw
    
            # Userobject
            if ($statsInfo) {
                return $statsInfo
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

New-Alias -Name Get-SMAStat -Value Get-SMAStatistics

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
