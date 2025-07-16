# Place for module - internal functions

function New-SMAQueryString {
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory = $false)]
        [String]$host = $SMAHost,

        [Parameter(Mandatory = $false)]
        [int]$port = $SMAPort,

        [Parameter(Mandatory = $false)]
        [String]$schema = 'https',

        [Parameter(Mandatory = $false)]
        [String]$version = $SMAPIVersion,

        [Parameter(Mandatory = $true)]
        [String]$uriPath,

        [Parameter(Mandatory = $false)]
        [Hashtable]$qParam
    )

    try {
        # Add System.Web
        Add-Type -AssemblyName System.Web

        # Create a http name value collection from an empty string
        Write-Verbose "Build the uri based on $schema and $host"
        $schemeHost = "{0}://{1}/ " -f $schema, $host
        $queryString = [System.UriBuilder]$schemeHost

        Write-Verbose "Add path based on parameters from $($qparam)"
        $ParamCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty) 
        if ($qparam) {
            $qparam.GetEnumerator()|ForEach-Object {
                $ParamCollection.Add("$($_.Key)","$($_.Value)")
            }
            $queryString.Query = $ParamCollection.ToString().Replace('=True','=true').Replace('=False','=false')
        }

        Write-Verbose "Finally building Querystring"
        $queryString.Port = $port
        $queryString.Path = "/$version/" + $uriPath
        return $queryString.Uri.OriginalString
    }
    catch {
        Write-Error "Error $_ occured!"
    }
}

function ConvertFrom-SMAPIFormat {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory         = $true,
            ValueFromPipeline = $true
            )]
        [PSobject]$inputObject
    )

      # Convert Names to Umlauts
    if ($inputObject.Name) {
        $bytes = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($inputObject.Name)
        $inputObject.Name = [System.Text.Encoding]::UTF8.GetString($bytes)
    }

    # Convert comments to Umlauts
      if ($inputObject.comment) {
        $bytes = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($inputObject.comment)
        $inputObject.comment = [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    # Convert description to Umlauts
    if ($inputObject.description) {
        $bytes = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($inputObject.description)
        $inputObject.description = [System.Text.Encoding]::UTF8.GetString($bytes)
    }

    # Convert strig to Date
    if ($inputObject.createddate) {
        $inputObject.createdDate = [Datetime]::ParseExact($inputObject.createdDate, 'yyyyMMddHHmmssZ', $null)
    }
    return $inputObject
}

function ConvertFrom-SMASecureString {
    param(
        [Parameter(
            Mandatory           = $true,
            ValueFromPipeline   = $true
        )]
        [SecureString]$securePassword
    )

    try {
        [string]$plainpassword = $null
        if ($psversiontable.PsEdition -eq 'Desktop') {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
            $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        } else {
            $plainPassword = $securePassword|ConvertFrom-SecureString -AsPlainText
        }
        return $plainPassword
    }
    catch {
        Write-Error "Error $_ occured!"
    }    
}
<#
.SYNOPSIS
    Calls the REST interface with Parameters
.DESCRIPTION
    Depending on the PS Version/Edition, calls the REST Method with proper settings and valid parameters.
    For Module internal use only.
#>
function Invoke-SMARestMethod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$uri,

        [Parameter(
            Mandatory=$true
            )]
        [ValidateSet('GET','POST','PUT','DELETE','PATCH')]
        [string]$method,

        [Parameter(
            Mandatory=$false
            )]
        [string[]]$body,

        [Parameter(
            Mandatory=$false
            )]
            [System.Management.Automation.PSCredential]$cred=$SMACred,

            [Parameter(
                Mandatory=$false
                )]
            [switch]$SkipCertCheck=$SMAskipCertCheck    
    )

    begin {
        Write-Verbose "Crafting Header-JSON"
        $headers = @{
            ##'X-SM-API-TOKEN' = $SMACred.UserName
            'X-SM-API-TOKEN' = $Cred.UserName;
            ##'X-SM-API-SECRET' = (ConvertFrom-SMASecureString -securePassword $SMACred.Password)
            'X-SM-API-SECRET' = (ConvertFrom-SMASecureString -securePassword $Cred.Password)
            'accept' = 'application/json'
        }
        
        Write-Verbose "Crafting the parameters for invoke-RestMethod"
        $SMinvokeParam = @{
            Uri         = $uri
            Method      = $Method
            header      = $headers
        }
        if ($null -ne $body) { $SMinvokeParam.body = $body }

        function Get-SMARestError {
            if ($_.ErrorDetails.Message -like '*errorcode*') {
                $RestErr = ($_.ErrorDetails.Message|convertfrom-JSON).errorMessage
                Write-Error "$RestErr"
            }
            else {
                Write-Error "Calling SEPPmail API failed with error: $_"
            }
        }
    }
    process {
        # Core and Skip
        if (($PSversiontable.PSEdition -like 'Core') -and ($SkipCertCheck)) {
            Write-verbose 'Calling Invoke-RestMethod on Core edition with skip Certificate'
            try {
                Invoke-RestMethod @SMinvokeParam -SkipCertificateCheck -ContentType 'application/json; charset=utf-8'
            }
            catch {
                #$RestErr = ($_.ErrorDetails.Message|convertfrom-JSON).errorMessage
                #Write-Error "$RestErr"
                Get-SMARestError
            }
        }
        # Desktop and skip
        elseif (($PSversiontable.PSedition -like 'Desktop') -and ($SkipCertCheck)) {
            Write-Verbose "Change endpoint to skipCertificateCheck and call url"
            if ([System.Net.ServicePointManager]::CertificatePolicy -like 'System.Net.DefaultCertPolicy') {
                $DefaultPolicy = [System.Net.ServicePointManager]::CertificatePolicy
                add-type @"
                using System.Net;
                using System.Security.Cryptography.X509Certificates;
                public class IDontCarePolicy : ICertificatePolicy {
                    public IDontCarePolicy() {}
                    public bool CheckValidationResult(
                        ServicePoint sPoint, X509Certificate cert,
                        WebRequest wRequest, int certProb) {
                            return true;
                    }
                }
"@
                [System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy 
                Write-verbose 'Calling Invoke-RestMethod on Dektop edition with skip Certificate'
                try {
                    Invoke-RestMethod @SMinvokeParam -ContentType 'application/json; charset=utf-8'
                }
                catch {
                    #$RestErr = ($_.ErrorDetails.Message|convertfrom-JSON).errorMessage
                    #Write-Error "$RestErr"
                    Get-SMARestError
                }
                [System.Net.ServicePointManager]::CertificatePolicy = $DefaultPolicy
            }
        }
        # Valid Certificate
        else {
            Write-verbose 'Calling Invoke-RestMethod with valid Certificate'
            try {
                Invoke-RestMethod @SMinvokeParam -ContentType 'application/json; charset=utf-8'
            }
            catch {
                #$RestErr = ($_.ErrorDetails.Message|convertfrom-JSON).errorMessage
                #Write-Error "$RestErr"
                Get-SMARestError
            }        
        }
    }
    end {
        #if ($result -notlike '0') {
        #    $textError  = Convert-SMRestError -interror $result.error
        #    Write-Error "SEPPmail REST-API returned Error $textError"
        #}
    }
}

<#
.SYNOPSIS
    Converts (and sorts) a hashtable to an ordered hashtable
.DESCRIPTION
    If indexing is needed on a hashtable, a conversion to [ordered] is needed. This function simply does this.
#>
function ConvertTo-OrderedDictionary {
    [CmdletBinding()]
    [OutputType([Collections.Specialized.OrderedDictionary])]
    Param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $HashTable
    )
    $OrderedDictionary = [ordered]@{ }
    if ($HashTable -is [System.Collections.IDictionary]) {
        $Keys = $HashTable.Keys | Sort-Object
        foreach ($_ in $Keys) {
            $OrderedDictionary.Add($_, $HashTable[$_])
        }
    } elseif ($HashTable -is [System.Collections.ICollection]) {
        for ($i = 0; $i -lt $HashTable.count; $i++) {
            $OrderedDictionary.Add($i, $HashTable[$i])
        }
    } else {
        Write-Error "ConvertTo-OrderedDictionary - Wrong input type."
    }
    return $OrderedDictionary
}

function Get-EmailFlat {
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $InputObj
    )
    $emails = @()
    if ($null -eq $InputObj) { return $emails }
    foreach ($prop in $InputObj.PSObject.Properties) {
        $val = $prop.Value
        if ($val -is [PSCustomObject]) {
            foreach ($subProp in $val.PSObject.Properties) {
                $subVal = $subProp.Value
                if (($subVal -is [PSCustomObject]) -and ($subVal.PSObject.Properties["email"])) {
                    $emailValue = $subVal.email
                    if (($emailValue -is [string]) -and ($emailValue -ne "")) {
                        $emails += $emailValue
                    }
                } elseif ($subVal -is [PSCustomObject]) {
                    $emails += Get-EmailFlat $subVal
                }
            }
        }
    }
    return $emails
}


# SIG # Begin signature block
# MIIL1wYJKoZIhvcNAQcCoIILyDCCC8QCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUD8pFpKWEhEItMNG3pv+q7/GD
# YqmggglAMIIEmTCCA4GgAwIBAgIQcaC3NpXdsa/COyuaGO5UyzANBgkqhkiG9w0B
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
# MRYEFP5pOVACIGTuBRa6T3P2qkwrhT3VMA0GCSqGSIb3DQEBAQUABIIBAJus9KBJ
# 6gZsr4x9/5+n3iJnQAcJ4P3ThwGMOIrFWQN7HCxZ1jX8WVo1lRSABc+hbwrKwJ4J
# gQD+pSz6XOoCRVKgRP0mMrix8Fx2JEbnUTlZsuJ82uErolItb6+bmjCq9oNo3oZa
# 6Pr87+owQiMJVIMEV6RYDtEtQsbZHKjSqpRV8oxhVTTwyq8WqCG+ZDZu4mf6lvbF
# /s4vMLHfZkx40Vhx28QKph/sK7nyPDCUzKrNI0c+Sm3DDrymtmBP0LHoJYu+RKdH
# L4bg9yWkH24ZtWCZ32dBR+8WtCEYfu/ILRzpKjd5lHG9FiJx/QIUaCwKCV+Ua1pC
# CCHweSCm7qi3z/A=
# SIG # End signature block
