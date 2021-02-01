# Place for module - internal functions
<#
.SYNOPSIS
    Creates a URL out of FQDN and the admin-Port defined in the configuation file
.DESCRIPTION
    This is for module internal use only
#>
function New-SMAUrlRoot {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        $SMAHost,
        
        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        $SMAPort = '8445'
    )
    begin {
    }
    process {
        'https://' + $SMAHost + ':' + $SMAPort + '/v1/'
    }
    end {
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

    $outputobject = $inputObject

    # Convert Names to Umlauts
    if ($inputobject.Name) {
        $bytes = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($inputobject.Name)
        $outputobject.Name = [System.Text.Encoding]::UTF8.GetString($bytes)
    }

    # Convert strig to Date
    if ($inputobject.createddate) {
        $outputobject.createdDate = [Datetime]::ParseExact($inputobject.createdDate, 'yyyyMMddHHmmssZ', $null)
    }
    return $outputobject
}

function ConvertTo-SMAPIFormat {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory         = $true,
            ValueFromPipeline = $true
            )]
        [PSobject]$inputObject
    )

    $outputobject = $inputObject

    # Convert Umlauts to Names API understands
    if ($inputobject.Name) {
        #$bytes = [System.Text.Encoding]::Unicode.GetBytes($inputobject.Name);
        #$outputobject.Name = [System.Text.Encoding]::UTF8.GetString($bytes);

        $bytes = [System.Text.Encoding]::GetEncoding("UTF-8").GetBytes($inputobject.Name)
        $outputobject.Name = [System.Text.Encoding]::UTF7.GetString($bytes)
    }

    return $outputobject
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
        [Parameter(
            Mandatory=$true
            )]
        [string]$uri,

        [Parameter(
            Mandatory=$true
            )]
        [ValidateSet('GET','POST','PUT','DELETE','PATCH')]
        [string]$method,

        [Parameter(
            )]
        [bool]$skipCertCheck = $SMASkipCertCheck,

        [Parameter(
            Mandatory=$false
            )]
        [string[]]$body
    )

    begin {
        Write-Verbose "convert Securestring to encrypted Key"
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SMAKey)
        $RESTKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        Write-Verbose "Crafting Header-JSON"
        $headers = @{
            'X-SM-API-KEY' = $RESTKey
            'accept' = 'application/json'
            'content-type' = 'application/json; charset=utf-8'
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
        if (($PSversiontable.PSEdition -like 'Core') -and ($skipCertCheck = $true)) {
            Write-verbose 'Calling Invoke-RestMethod on Core edition with skip Certificate'
            try {
                Invoke-RestMethod @SMinvokeParam -SkipCertificateCheck
            }
            catch {
                $RestErr = ($_.ErrorDetails.Message|convertfrom-JSON).errorMessage
                Write-Error "$RestErr"
            }
        }
        # Desktop and skip
        elseif (($PSversiontable.PSedition -like 'Desktop') -and ($skipCertCheck = $true)) {
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
                    Invoke-RestMethod @SMinvokeParam
                }
                catch {
                    $RestErr = ($_.ErrorDetails.Message|convertfrom-JSON).errorMessage
                    Write-Error "$RestErr"
                }
                [System.Net.ServicePointManager]::CertificatePolicy = $DefaultPolicy
            }
        }
        # Valid Certificate
        else {
            Write-verbose 'Calling Invoke-RestMethod with valid Certificate'
            try {
                Invoke-RestMethod @SMinvokeParam
            }
            catch {
                $RestErr = ($_.ErrorDetails.Message|convertfrom-JSON).errorMessage
                Write-Error "$RestErr"
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
