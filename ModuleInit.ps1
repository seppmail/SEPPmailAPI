<#
.SYNOPSIS
    Module init script
.DESCRIPTION
    This script sets some global variables for the configuration and access
.EXAMPLE
    no examples
.INPUTS
.OUTPUTS
.NOTES
#>
[CmdLetBinding()]
param()

try {
    Write-Verbose 'Checking Variables'
    if ($null -eq $global:SMHost) {
        Write-Warning "No SEPPmail Host set - Add a Variable i.e. https://securemail.contoso.de"
        $global:SMHost = Read-Host "Enter SEPPmail host name in FQDN format (i.e.securemail.contoso.de)"
        }
    if ($null -eq $global:SMKey) {
        Write-Warning "No REST-API Key set - Enter the API Key"
        $global:SMKey = Read-Host "Enter SEPPmail REST-API Key (the one from the Admin-Portal)" -AsSecurestring
        }
    if ($null -eq $global:SMskipCertCheck) {
        Write-Verbose 'Variable $SMskipCertCheck not found setting to default value $false'
        $global:SMskipCertCheck = $false
        }
    if ($null -eq $global:SMPort) {
        Write-Verbose 'Variable $SMPort not found. Setting to default value 8445'
            $global:SMPort = '8445'
        }
    Write-Warning 'If your SEPPmail Appliance does not have a valid SSL certificate, set the valiable $SMskipCertCheck to $true'
    
    "SM-Host: " + $SMHost
    "SM-Port: " + $SMPort
    "SM-Skip certificate check ?: " + $SMskipCertCheck
    #Write-Verbose "Testing connction to $smHost on port $smPort"
    #Test-NetConnection -Computername $smhost -Port $smport
    }
catch {
    Write-Error "ModuleInit.ps1 failed with error $_"
}
