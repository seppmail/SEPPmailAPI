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