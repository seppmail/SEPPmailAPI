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
param(
    [Parameter(
        Mandatory                       = $false,
        HelpMessage                     = 'Test Connection on Port SMAPort to SMAHost'
        )]
    [bool]$connTest = $false
)

try {    
    <#Write-Verbose 'Checking Variables'
    if (!($SMAHost)) {
        Write-Warning "No SEPPmail Host set - Add a Variable i.e. https://securemail.contoso.de"
        $global:SMAHost = Read-Host "Enter SEPPmail host name in FQDN format (i.e.securemail.contoso.de)"
        }
    if ((!($SMACred)) -or ($SMACred.GetType().Name -ne 'PSCredential')){
        Write-Warning "No REST-API Access Credentials found or API access credentials are not a credential object - Enter the API key and secret below"
        $global:SMACred = Get-Credential -Message 'Enter API key and secret you have entered in the "System"==>"Advanced View" section of your SEPPmail'
        }
    if (!($SMASkipCertCheck)) {
        Write-Verbose 'Variable $SMASkipCertCheck not found setting to default value $false'
        $global:SMASkipCertCheck = $false
        }
    if (!($global:SMAPort)) {
        Write-Verbose 'Variable $global:SMAPort not found. Setting to default value 8445'
            $global:SMAPort = '8445'
        }
    if (!($global:SMAPIVersion)) {
        Write-Verbose 'Variable $global:SMAPIVersion not found. Setting to default value v1'
            $global:SMAPort = 'v1'
        }
    #>
    Write-Verbose 'Check/set TLS Version 1.2'
    if (([Net.ServicePointManager]::SecurityProtocol) -eq 'Ssl3, Tls') {
            Write-Verbose "TLS was 1.0, set to version 1.2"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    else 
    {
        Write-Verbose "TLS is version 1.2"
    }

    if ($testConn) {
        Write-Verbose "Testing connection to $SMAHost on port $SMAPort"
        $SMAConnTest = Test-NetConnection -Computername $SMAHost -Port $SMAPort
        if ($SMAConntest.TcptestSucceeded -eq $true) {
            Write-Host "Connection to host $SMAHost on port $SMAPort was established successfully" -ForegroundColor Green
            Write-Host "Start your journey with the SEPPmail API Module i.e. with Find-SMAUser -List" -ForegroundColor Green
            }
        else {
            Write-Error "Connection to Host $SMAHost on Port $SMAPort FAILED. Fix this before using the module."
            }
        }
    }
catch {
    Write-Error "ModuleInit.ps1 failed with error $_"
}

