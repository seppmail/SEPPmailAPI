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
            'X-SM-API-TOKEN' = $Cred.UserName;
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

    }
    process {
        # Core and Skip
        if (($PSversionTable.PSEdition -like 'Core') -and ($SkipCertCheck)) {
            Write-verbose 'Calling Invoke-RestMethod on Core edition with skip Certificate'
            try {
                #Invoke-RestMethod @SMinvokeParam -SkipCertificateCheck -ContentType 'application/json; charset=utf-8'
                Invoke-RestMethod @SMinvokeParam -SkipCertificateCheck -ContentType 'application/json'
            }
            catch {
                Get-SMARestError
            }
        }
        # Desktop and skip
        elseif (($PSversionTable.PSedition -like 'Desktop') -and ($SkipCertCheck)) {
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
                    Invoke-RestMethod @SMinvokeParam -ContentType 'application/json'
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
                Invoke-RestMethod @SMinvokeParam -ContentType 'application/json'
            }
            catch {
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

function Get-SMARestError {
    if ($_.Exception.Response) {
        $response = $_.Exception.Response
        $statusCode = $response.StatusCode.value__
        $statusDescription = $response.StatusDescription
        
        Write-Verbose "HTTP Status Code: $statusCode"
        Write-Verbose "Status Description: $statusDescription"
        Write-Verbose "Request URI: $($_.Exception.Response.ResponseUri)"

        try {
            $reader = [System.IO.StreamReader]::new($response.GetResponseStream())
            $errorContent = $reader.ReadToEnd()
            $reader.Close()
            
            Write-Verbose "Raw Response: $errorContent"

            # Bei HTTP 500 detailliertere Informationen ausgeben
            if ($statusCode -eq 500) {
                Write-Error "Server Error (HTTP 500)`nURI: $($_.Exception.Response.ResponseUri)`nResponse: $errorContent"
                Write-Verbose "Request Method: $($invokeParam.Method)"
                if ($invokeParam.body) {
                    Write-Verbose "Request Body: $($invokeParam.body)"
                }
                return
            }

            try {
                $errorJson = $errorContent | ConvertFrom-Json
                Write-Error "$($errorJson.errorMessage)"
            }
            catch {
                Write-Error "API Error: $errorContent"
            }
        }
        catch {
            Write-Error "API call failed: $statusCode - $statusDescription"
        }
    }
    else {
        Write-Error "Error calling SEPPmail API: $_"
    }
}

# SIG # Begin signature block
# MIIVzAYJKoZIhvcNAQcCoIIVvTCCFbkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCVPjOVKjQ+aMhE
# f9R4pv0WP+vIDWBwP3mmXHNUuVKRe6CCEggwggVvMIIEV6ADAgECAhBI/JO0YFWU
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
# BgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCC2RroHft65lETP34VosmqBFiAF
# A5hVihtS5UAKqedI4TANBgkqhkiG9w0BAQEFAASCAgC+KpJDTBlaAkZcsAdB4TY+
# 1ssDpeMMIfYr2o6k2QpPC9DPE7MVLB5OkLAEMQwYXlgDSpkCLUUvof2nZOzOdDTN
# k3H7TRwVMy1pLAx9YgJKIhsInxHVUa6KExocA1AMTQve64xwj2/mHIUE+iFfKvUb
# Y2USAwzEvZsIKC7Lu909KVQwvB899AZQlJdCJ88tJuC57BVdAuPYOOotc1O0xEpi
# O/F9ZaKpZ/KdgE9tNvT6CAcLfou+E8/RQpB46C/XYG5KLQte/JhOj4JQs59b0SAW
# gFCieS7t+pT/0WcizXEpsAqBAerNXOLpJNADZRbcAUTUUKoL8RBxZghXZdURyQfT
# 9KpFhkCT5UP2f4xM9nPcxKLq0CmIHzovdglxxvbtXqQroF8T3kYsFVh13NFjuJDM
# E2u25CXTuP+aWGJvZDlnUsE/x9NgWiLqly+qO0rZrJEvnqN30BhEx3VkVqM8C3bb
# Pk0xzsY7lbVDjRGUmJz8PpxhRAr/OwmFcZJ1KAXsRTZ9I0TmUvvdk4vT4KMI1qks
# yc9HWI8i6jZIQmN6pDP6A35jm8PfhfCZ8zE791Yse8ddJhf4KZWfF3ROszL5ihsC
# sIgUeMcLdSHg4VmLhuW8ChQ/nBOw3GK2fq4pKNoVohQjXuL1V1Q/MbylVHJ1gPDd
# fJhY9P161PPeF6lHN1AvlQ==
# SIG # End signature block
