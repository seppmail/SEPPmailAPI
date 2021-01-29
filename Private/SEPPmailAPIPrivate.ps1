# Place for module - internal functions
<#
.SYNOPSIS
    Creates a URL out of FQDN and the admin-Port defined in the configuation file
.DESCRIPTION
    This is for module internal use only
#>
function New-SMUrlRoot {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        $SMHost,
        
        [Parameter(
            Mandatory                       = $false,
            ValueFromPipelineByPropertyName = $true
            )]
        $SMPort = '8445'
    )
    begin {
    }
    process {
        'https://' + $SMHost + ':' + $SMport + '/v1/'
    }
    end {
    }
}

<#
.SYNOPSIS
    Calls the REST interface with Parameters
.DESCRIPTION
    Depending on the PS Version/Edition, calls the REST Method with proper settings and valid parameters.
    For Module internal use only.
#>
function Invoke-SMRestMethod {
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
        [bool]$skipCertCheck = $SMskipCertCheck,

        [Parameter(
            Mandatory=$false
            )]
        [string[]]$body
    )

    begin {
        Write-Verbose "convert Securestring to encrypted Key"
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SMKey)
        $RESTKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        Write-Verbose "Crafting Header-JSON"
        $headers = @{
            'X-SM-API-KEY' = $RESTKey
            'accept' = 'application/json'
            'content-type' = 'application/json'
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
            Invoke-RestMethod @SMinvokeParam -SkipCertificateCheck
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
                Invoke-RestMethod @SMinvokeParam
                [System.Net.ServicePointManager]::CertificatePolicy = $DefaultPolicy
            }
        }
        # Valid Certificate
        else {
            Write-verbose 'Calling Invoke-ResrMethod with valid Certificate'
            Invoke-RestMethod @SMinvokeParam
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
    Converts REST Errors to readable errors
.DESCRIPTION
    The REST-API returns 11 different error numeric codes, this cmdLet transforms them into written messages.
#>
function Convert-SMRestError {
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(
            Mandatory=$true
            )]
            [ValidateSet('-2','-3','-4','-5','-6','-8','-9','-11','-12','-13','-14')]
            [string]$interror
    )
    begin {
    }
    process {
        switch ($interror) {
            {$_ -eq '-2'} {'Unknown command'}
            {$_ -eq '-3'} {'Unknown category'}
            {$_ -eq '-4'} {'Invalid HTTP Method'}
            {$_ -eq '-5'} {'POST-Data error'}
            {$_ -eq '-6'} {'Error when parsing JSON POST-data'}
            {$_ -eq '-8'} {'Error while reading/writing database'}
            {$_ -eq '-9'} {'Unknown error'}
            {$_ -eq '-11'} {'Invalid REST-Path'}
            {$_ -eq '-12'} {'Invalid parameter in REST-Path'}
            {$_ -eq '-13'} {'Invalid data in REST-query'}
            {$_ -eq '-14'} {'Internal Error'}
        }
    }
    end {
    }
}