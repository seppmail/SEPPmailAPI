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
    if ($null -eq $global:SMAHost) {
        Write-Warning "No SEPPmail Host set - Add a Variable i.e. https://securemail.contoso.de"
        $global:SMAHost = Read-Host "Enter SEPPmail host name in FQDN format (i.e.securemail.contoso.de)"
        }
    if ($null -eq $global:SMAKey) {
        Write-Warning "No REST-API Key set - Enter the API Key"
        $global:SMAKey = Read-Host "Enter SEPPmail REST-API Key (the one from the Admin-Portal)" -AsSecurestring
        }
    if ($null -eq $global:SMASkipCertCheck) {
        Write-Verbose 'Variable $SMASkipCertCheck not found setting to default value $false'
        $global:SMASkipCertCheck = $false
        }
    if ($null -eq $global:SMAPort) {
        Write-Verbose 'Variable $SMAPort not found. Setting to default value 8445'
            $global:SMAPort = '8445'
        }
    Write-Warning 'If your SEPPmail Appliance does not have a valid SSL certificate, set the valiable $SMASkipCertCheck to $true'
    
    "SMA-Host: " + $SMAHost
    "SMA-Port: " + $SMAPort
    "SMA-Skip certificate check ?: " + $SMASkipCertCheck
    #Write-Verbose "Testing connction to $SMAHost on port $SMAPort"
    #Test-NetConnection -Computername $SMAHost -Port $SMAPort
    }
catch {
    Write-Error "ModuleInit.ps1 failed with error $_"
}
