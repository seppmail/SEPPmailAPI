[CmdLetBinding()]
$ModulePath = $PSScriptroot
. $ModulePath\Private\SEPPmailAPIPrivate_Cfg.ps1;

. $ModulePath\Public\SEPPmailAPI-Customer.ps1
. $ModulePath\Public\SEPPmailAPI-Disclaimer.ps1
. $ModulePath\Public\SEPPmailAPI-Info.ps1
. $ModulePath\Public\SEPPmailAPI-Group.ps1
. $ModulePath\Public\SEPPmailAPI-ManagedDomain.ps1
. $ModulePath\Public\SEPPMailAPI-ModuleCfg.ps1
. $ModulePath\Public\SEPPmailAPI-Statistics.ps1
. $ModulePath\Public\SEPPmailAPI-Template.ps1
. $ModulePath\Public\SEPPmailAPI-User.ps1
. $ModulePath\Public\SEPPmailAPI-UserCrypto.ps1
. $ModulePath\Public\SEPPmailAPI-Webmail.ps1

$script:requiredVarList=@(
    'Host',
    'Port',
    'Version'
    'Cred'
    'SkipCertCheck'
);
$Script:missingVarsMessage='Missing variables';
#>

# get module name and version
$mfp=($MyInvocation.MyCommand.path)
$Script:ModuleName=(([System.IO.Path]::GetFileNameWithoutExtension(($mfp))).ToUpper())
$mList=(Get-Module -Name $Script:ModuleName -ListAvailable); # get list of names of the module (more then one if diffrent versions)
$refPath=[System.IO.Path]::ChangeExtension($mfp,'psd1'); # get path of the module file
New-Variable -Name 'ModuleCfgVer' -Value 1 -Scope Script -Option Constant;
New-Variable -Name 'SMAPIPrefix' -Value 'SEPPmail' -Scope Script -Option Constant; # prefix for entries in vault
New-Variable -Name 'VaultName' -Value ($script:SMAPIPrefix) -Scope Script -Option Constant; # name of the vault the module using (it will be created if not exist)
New-Variable -Name 'SecureVaultModuleName' -Value 'Microsoft.PowerShell.SecretStore' -Scope Script -Option Constant; # name of the microsoft vault
New-Variable -Name 'SMAModuleCfgName' -Value ($script:SMAPIPrefix+'_ModuleCfg') -Scope Script -Option Constant;
New-Variable -Name 'ShowMsgIfNoCfgLoaded' -Value $true -Scope Script -Option Constant;
New-Variable -Name 'SMADefaultPort' -Value 8445 -Scope Script -Option Constant; # default port SeppMail appliance
New-Variable -Name 'cfgNamePrefix' -Value ($script:SMAPIPrefix+'Cfg_') -Scope Script -Option Constant; # prefix for config enties in vault
New-Variable -Name 'LoadCfgIfOnlyOneExist' -Value $true -Scope Script -Option Constant; # if only one config exist, and not default, load it on module start
New-Variable -Name 'DefaultAPIVer' -Value 'v1' -Scope Script -Option Constant; # version of the SeppMail appliance API
New-Variable -Name 'ShowIntConversionWarning' -Value $false -Scope Script -Option Constant; # set it only for development to TRUE
New-Variable -Name 'SuppressNativeTestError' -Value $false -Scope Script -Option Constant; # if set to TRUE the native error, in cmdlet Test-SMAConfiguration,  from Get-SMAUser, will be suppressed

$script:activeCfg=@{
    SMACfgName='';
    SMACred=[System.Management.Automation.PSCredential]::empty;
    SMAHost='';
    SMAPort=$null;
    SMAPIVersion='';
    SMASkipCertCheck=$false;
}; # end activeCfg

foreach ($entry in $mList)
{
    if ($entry.path -eq $refPath)
    {
        $Script:ModuleVersion=($entry.version)
        break;
    }; # end if
}; # end foreach

#$vStr=(($Script:ModuleVersion).ToString()).Replace('.','_');
$vName='__' + $Script:ModuleName +'_ModuleData'; 
New-Variable -Name $vName -Value ([GetModuleData]::new()); # export object, needed for argument completer
Export-ModuleMember -Variable $vName;

#As some CmdLets get pretty long, we add aliases here.
Export-ModuleMember -Alias * -Function *

initEnumerator;
initModule;
# SIG # Begin signature block
# MIIL1wYJKoZIhvcNAQcCoIILyDCCC8QCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDD7IJDkCD3WUixECvY8W2Nyk
# PpyggglAMIIEmTCCA4GgAwIBAgIQcaC3NpXdsa/COyuaGO5UyzANBgkqhkiG9w0B
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
# MRYEFKoDyORV9T6u8CoUofaKayqbvs/LMA0GCSqGSIb3DQEBAQUABIIBAF8gHNt3
# aSJTkY+F+A+RCNsk5Fo0P2OWdpLcWvEi/uY2V7wIGfbDch5rbiIEVWt7DmevX27V
# 5b/fyDRFoGuvFRtNmEf6pCNnOZrExsM0qcOYemDgcB5XY+KWmvGdBYLdsi94Y7Lw
# G0f0WpbyKoWmyQ1zoLyQm0IjvX4az3GHl2kL1hsMiHjtd0ueDDEYoqwgWBWNxuS0
# slv5lR6wEJ5KjvMdxrP/cNnNhDqQPhagXlTdXQJoH+GNMcym8YPK4Mg+C/ijR+tt
# 1u0eMGqcKs6mOEBX9oSmbovP7vQmMn5nFIwLf9EMgERSbT+WW9V5eVACDo4ozm3O
# 60ntHzGug92A3rs=
# SIG # End signature block
