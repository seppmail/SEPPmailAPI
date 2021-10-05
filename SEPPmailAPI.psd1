#
# Module manifest for module 'SEPPmailAPI'
#
# Generated by: Roman Stadlmair
#
# Generated on: 26.01.2021
#

@{

# Script module or binary module file associated with this manifest.
RootModule = '.\SEPPmailAPI.psm1'

# Version number of this module.
ModuleVersion = '0.9.5'

# Supported PSEditions
CompatiblePSEditions = @('Desktop','Core')

# ID used to uniquely identify this module
GUID = 'fe22be24-92f4-4e63-ba8d-5e9f26779d9d'

# Author of this module
Author = 'stadlmair@seppmail.at'

# Company or vendor of this module
CompanyName = 'SEPPmail AG'

# Copyright statement for this module
Copyright = '(c) SEPPmail AG. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Receive and manipulate your SEPPmail Appliance beginning with SEPPmail Version 12.1.0.
With the REST-API you can retrieve and set information via REST, including the option to mass-generate users.
This PowerShell module is a wrapper around this API to allow more convenient operation and interaction from the command line.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @('Configuration','Microsoft.PowerShell.SecretsManagement')
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @(
        '.\Private\SEPPmailAPIPrivate.ps1'
        )

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
      'Find-SMACustomer'
       'Get-SMACustomer'
       'New-SMACustomer'
       'Set-SMACustomer'
    'Remove-SMACustomer'
    'Export-SMACustomer'
    'Import-SMACustomer'
       'Get-SMAEncInfo'
       'Add-SMACustomerAdmin'
    'Remove-SMACustomerAdmin'
       'Set-SMAConfiguration'
       'Get-SMAConfiguration'
       'New-SMAConfiguration'
    'Remove-SMAConfiguration'
      'Test-SMAConfiguration'
      'Find-SMADisclaimer'
       'Get-SMADisclaimer'
       'New-SMADisclaimer'
       'Set-SMADisclaimer'
    'Remove-SMADisclaimer'
      'Find-SMADisclaimerInclude'
       'New-SMADisclaimerInclude'
    'Remove-SMADisclaimerInclude'
      'Find-SMAGinaUser'
       'New-SMAGinaUser'
       'Set-SMAGinaUser'
    'Remove-SMAGinaUser'
      'Find-SMAGroup'
       'New-SMAGroup'
       'Set-SMAGroup'
 #   'Remove-SMAGroup'
      'Find-SMAManagedDomain'
       'Get-SMAManagedDomain'
       'New-SMAManagedDomain'
       'Set-SMAManagedDomain'
    'Remove-SMAManagedDomain'
      'Find-SMATemplate'
       'Get-SMATemplate'
       'New-SMATemplate'
       'Set-SMATemplate'
    'Remove-SMATemplate'
      'Find-SMATemplateInclude'
       'Get-SMATemplateInclude'
       'New-SMATemplateInclude'
    'Remove-SMATemplateInclude'
       'Get-SMAStatistics'
       'Get-SMAUser'
      'Find-SMAUser'
       'New-SMAUser'
       'Set-SMAUser'
    'Remove-SMAUser'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @('*')

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = @(
    '.\SEPPmailAPI.psm1',
    '.\SEPPmailAPI.psd1',
    '.\Readme.MD',
    '.\LICENSE',
    '.\examples\examples.md',
    '.\examples\customers.csv',
    '.\examples\NewUsers.csv',
    '.\examples\RemoveUsers.csv',
    '.\examples\UpdateUsers.csv',
    '.\Private\SEPPmailAPIPrivate.ps1',
    '.\Private\SEPPmailAPIPrivate_Cfg.ps1',
    '.\Public\SEPPmailAPI-Customer.ps1',
    '.\Public\SEPPMailAPI-Disclaimer.ps1',
    '.\Public\SEPPMailAPI-Group.ps1',
    '.\Public\SEPPmailAPI-Info.ps1',
    '.\Public\SEPPmailAPI-ManagedDomain.ps1',
    '.\Public\SEPPMailAPI-ModuleCfg.ps1',
    '.\Public\SEPPMailAPI-Statistics.psd1',
    '.\Public\SEPPMailAPI-Template.ps1',
    '.\Public\SEPPmailAPI-User.ps1'
    '.\Public\SEPPmailAPI-Webmail.ps1'
)

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @(
                'SEPPmail',
                'REST-API',
                'PSEdition_Desktop',
                'PSEdition_Core',
                'Windows',
                'Linux'
                #'MacOS'
                )

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/seppmail/SEPPmailAPI/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/seppmail/SEPPmailAPI'

        # A URL to an icon representing this module.
        IconUri = 'https://avatars1.githubusercontent.com/u/55975553?s=400&u=ab22c52a439397dca458e58dfcec9f0a9dd347db&v=4'

        # ReleaseNotes of this module
        ReleaseNotes =
@'
260121: Initial release - preparation for SM Release 12.1.0 - User path only

050221: User management stable - working with SM Dev Release 12.1.0

080221: 0.5.3 - Fixed TLS issue on older PS5 (WS2016) machines, cleanup exported commands

110321: 0.8.0 - All v1 CmdLets done, cosmetics and testing starting now

020421: 0.8.1 - Adding Support for Credential based security with Token/secret

070721: 0.9.0 - Adding Support for multiple configs and SecretStore

260721: 0.9.1 - Adding Support for Encryption Information

170921: 0.9.2 - Adding Support for ManagedDomain, MailTemplate, Disclaimer

180921: 0.9.3 - Adding Support for Statistics

270921: 0.9.4 - Adding Support for Webmail (GINA) users

031021: 0.9.5 - Adding Support for Groups

'@

        # Prerelease string of this module
        Prerelease = 'beta5'

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/seppmail/SEPPmailAPI/blob/main/examples/examples.md'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''
}

# SIG # Begin signature block
# MIIL1wYJKoZIhvcNAQcCoIILyDCCC8QCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUK30Gz3vSdVxzvuRTyq/nppCu
# w/SggglAMIIEmTCCA4GgAwIBAgIQcaC3NpXdsa/COyuaGO5UyzANBgkqhkiG9w0B
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
# MRYEFKi55oZ0CFj5F68eMxZ9jJqF3KCmMA0GCSqGSIb3DQEBAQUABIIBABCL2KtI
# Zqq44g3oerh6HaNu7r0R2I7ozwZtAbY8Hh7zJWSM8mfO+W+qP2BVD2AWXjUkBHAw
# GfdG9ZZaQjiFW/NpZgUyfstXoJRUqRNsIjwPyRwqqvwrvCQE8GHExLkR0En6XM4E
# 9NsqfFjIs58yJZ+OdI5QeNxbwfid1/qECR78OmjnWVpUD+gQZp2sqXW7ZzN/YwvE
# Ort39HjHuTHLNMqs5QEs1FATFtWOO3GA264QxKHkj+/AEgNU6wJxsXodaWd2fQu1
# 8zx80fdVgj/bqkT9YAH9A0S5jrQdYZhOlF8MCMeBHrCkJ7+4WWUKW9wPKdBgcg5e
# 0/5Oiy02MXYB+oc=
# SIG # End signature block
