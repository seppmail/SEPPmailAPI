function Get-SMAConfiguration
{
<#
.SYNOPSIS 
Lists the configuration for SEPPmailAPI.
.DESCRIPTION
The cmdlet lists the configurations for SEPPmailAPI. With the appropriate parameters the default or all configurations can be listed. Without a parameter, the active configuration will be displayed.
.PARAMETER ConfigurationName
The parameter is optional. The data type is string.
The name of the configuration which should be listed. The parameter cannot be used with the parameters
-	Default
-	ListAll

.PARAMETER Default
The parameter is optional. Data type SwitchParameter.
If the parameter is used, the configuration, which is configured as default configuration will be displayed. The parameter cannot be used with the parameters
-	ConfigurationName
-	ListAll

.PARAMETER ListAll
The parameter is optional. Data type SwitchParameter.
If the parameter is used all configurations will be displayed. The parameter cannot be used with the parameters
-	ConfigurationName
-	Default

.PARAMETER Format
The parameter is optional. Data type string.
The parameter defines the format how the configuration(s) will be displayed. Default is Table. Possible values are:
-	Table
-	List
-	PassValue (unformatted)
.EXAMPLE
Get-SMAConfiguration -Default
Lists the default configuration.

.EXAMPLE
Get-SMAConfiguration -ListAll
Lists all configurations.

.EXAMPLE
Get-SMAConfiguration 
Lists the currently active configuration.
#>
[cmdletbinding(DefaultParametersetName='__AllParameter')]    
param([Parameter(ParameterSetName='CfgFromVault',Mandatory = $false,
    Position = 0)][ArgumentCompleter( {
    param ( $CommandName,
        $ParameterName,
        $WordToComplete,
        $CommandAst,
        $FakeBoundParameters )  
    $tmpList=$__SEPPmailAPI_ModuleData.getConfigList();
    $cfgList=@();
    foreach ($item in $tmpList)
    {
        if ($item.contains(' '))
        {
            $cfgList+="'"+$item+"'";
        } # end if
        else {
            $cfgList+=$item;
        }; # end else
    };
    $cfgList.Where({ $_ -like "$wordToComplete*" });
    } )][string]$ConfigurationName,
      [Parameter(ParameterSetName='Default',Mandatory = $false, Position = 0)][switch]$Default=$false,
      [Parameter(ParameterSetName='ListAll',Mandatory = $false, Position = 0)][switch]$List=$false,
      [Parameter(Mandatory = $false, Position = 2)][Validateset('Table','List','PassValue')][String]$Format='Table'      
     )

    begin {

    }; # end begin

    process {
        try {
            $getData=$true;
            $msg='Failed to get the default configuration'
            $DefaultCfgName = Get-SecretInfo -Vault $script:vaultName -Name ($script:SMAModuleCfgName );
            $msg='Failed to read the configuration';
            switch ($PSCmdlet.ParameterSetName)
            {
                'ListAll'       {
                    $msg='Failed to read the config data';
                    writeLogOutput -LogString ('Reading all configuraiton items')
                    $cfgList = @(Get-SecretInfo -Name ($script:cfgNamePrefix + '*' ) -Vault $Script:vaultName); 
                    if ($cfgList.Count -eq 0)
                    {
                        writeLogOutput -LogString ('No configuration found.') -LogType Warning;
                        return;
                    }; # end if 
                    break;
                }; # end ListAll
                'CfgFromVault'  {
                    $msg=('Failed to read the config data from configuration ' + $ConfigurationName);
                    writeLogOutput -LogString ('Reading configuration ' + $ConfigurationName);
                    $cfgList=@(Get-SecretInfo -Name ($script:cfgNamePrefix +  $ConfigurationName) -Vault $Script:vaultName);  
                    if ($cfgList.Count -eq 0)
                    {
                        writeLogOutput -LogString ('A configuration with the name ' + $ConfigurationName + ' does not exist.') -LogType Warning;
                        return;
                    }; # end if   
                    break;     
                }; # end CfgFromVaul
                'Default'       {
                    $msg=('Failed to read the default config ');
                    writeLogOutput -LogString ('Reading default config from module configuration')
                    #$DefaultCfgName = Get-SecretInfo -Vault $script:vaultName -Name ($script:SMAModuleCfgName );
                    if ([System.String]::IsNullOrEmpty($DefaultCfgName.Metadata.DefaultCfgName))
                    {
                        $getData=$false;
                        writeLogOutput -LogString 'No default config defined. Please run the cmdle Set-SMAConfiguration -Name <config name> -SetAsDefault' -LogType Warning;
                    } # end if
                    else {
                        writeLogOutput -LogString ('Verifing if config ' + $DefaultCfgName.Metadata.DefaultCfgName + ' exist');
                        $msg=('Failed to load the default config ' + $DefaultCfgName.Metadata.DefaultCfgName + ' from configuration');
                        $cfgList=@(Get-SecretInfo -Name ($script:cfgNamePrefix  + $DefaultCfgName.Metadata.DefaultCfgName) -Vault $Script:vaultName);  
                        if ($cfgList.Count -eq 0)
                        {
                            writeLogOutput -LogString ('A configuration with the name ' + $ConfigurationName + ' does not exist.') -LogType Warning;
                            return;
                        }; # end if        
                    }; # end else
                    break;
                }; # end Default
                Default         {
                    if ([System.String]::IsNullOrEmpty( $Script:activeCfg.SMACfgName))
                    {
                        writeLogOutput 'No active SeppMail configuration found.' -LogType Warning;
                        return;
                    } # end if
                    else {
                        $cfgData=formatConfigData -ActiveConfigData -DefaultCfgName ($DefaultCfgName.Metadata.DefaultCfgName);
                        $getData=$false;
                    }; # end else
                   
                }; # active config
            }; # end switch
            if ($getData)
            {
                $cfgData=formatConfigData -ConfigData $cfgList -DefaultCfgName ($DefaultCfgName.Metadata.DefaultCfgName);
            }; # end if            
        } # end try
        catch {
            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_; 
        }; # end catch
                
        switch ($Format)
        {
            'Table' {
                $cfgData | Format-Table $fieldList;
                break;
            }; # format tabel
            'List'  {
                $cfgData | Format-List $fieldList;
                break;
            }; # format list
            'PassValue'  {
                $cfgData;
                break;
            }; # format list                                        
        }; # end switch           
    }; # end process

    end {

    }; # end END
    
}; # end funciton Get-SMAConfiguration

function New-SMAConfiguration
{
<#
.SYNOPSIS 
Creates a new configuration.
.DESCRIPTION
The command creates a new configuration, which can be used to connect to a SeppMail appliance.
.PARAMETER ConfigurationName
The parameter is mandatory. Data type string.
The name of the new configuration.

.PARAMETER SMAHost
The parameter is mandatory. Data type string.
The FQDN of the SeppMail appliance. 

.PARAMETER SMACred
The parameter is mandatory. Data type PSCredential.
The parameter expects the API-key and the secret for the SeppMail appliance.

.PARAMETER SMAPort
The parameter is optional. Data type int32.
The parameter expects the value for the port of the SeppMail appliance. If the parameter is omitted, the default value 8445 will be used.

.PARAMETER SMAPIversion
The parameter is optional. Data type enumerator.
The parameter expects the version of the SeppMail API. If the parameter is omitted, the default value of 
-	v1
will be used. Currently only the value v1 is a valid value.

.PARAMETER SMASkipCertCheck
The parameter is optional. Data type SwitchParameter.
If the parameter is used, the certificate check will be suppressed.
.EXAMPLE
New-SMAConfiguration -Name <config name> -SMAHost host.name.com -SMAPort 1234
A configuration with a non-default port will be created.

.EXAMPLE
New-SMAConfiguration -Name <config name> -SMAHost host.name.com 
A configuration with default values for
-	Port (8445)
-	Version (v1)
will be created. The certificate will be checked.
#>
[cmdletbinding()]    
param([Parameter(Mandatory = $true, 
      HelpMessage='Enter a unique configuration name',
      Position = 0)]
      [string]$ConfigurationName,
      [Parameter(Mandatory = $true, 
      HelpMessage='Enter the name of the SeppMail host',
      Position = 1)][string]$SMAHost,
      [Parameter(Mandatory = $true, 
      HelpMessage='Enter the SeppMail credential',
      Position = 2)][System.Management.Automation.PSCredential]$Credential,
      [Parameter(Mandatory = $false, Position = 3)][int]$SMAPort=$Script:SMADefaultPort, #$__SEPPmailAPI_ModuleData.SMADefaultPort,
      [Parameter(Mandatory = $false,
      HelpMessage='Enter the SeppMail API version',
      Position = 3)][SMAPIVer]$SMAIPVersion=$Script:DefaultAPIVer,
      [Parameter(Mandatory = $false,
      Position = 4)][switch]$SMASkipCertCheck=$false
     )

    begin {

    }; # end begin

    process {
        $configName= ($Script:cfgNamePrefix +  $ConfigurationName)
        if (Get-SecretInfo -Name $configName -Vault $Script:vaultName)
        {
            writeLogOutput -LogString ('A configuration with the name ' + $ConfigurationName + ' already exist') -LogType Error;
            return;
        } # end if
        else {
            $parmList=@{
                Name=$configName;
                Secret=$Credential;
                Vault=$Script:vaultName;
                ErrorAction='Stop';
                Metadata=@{
                    SMAHost=$SMAHost;
                    SMAPort=$SMAPort;
                    SMAPIVersion=($SMAIPVersion.ToString());
                    SMASkipCertCheck=[int]($SMASkipCertCheck.IsPresent);
                }; # Metadata
            }; #end paramList
            try {
                writeLogOutput -LogString ('Create entry for configuration ' + $ConfigurationName);
                Set-Secret @parmList;
            } # end try
            catch {
                $msg=('Failed to create the configuration ' + $ConfigurationName);
                writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
            }; # end catch
        }; # end else
    }; #end process
    
    end {

    }; # end END
}; # end function New-SMAConfiguration


function Remove-SMAConfiguration
{
<#
.SYNOPSIS 
Removes a configuration.
.DESCRIPTION
The cmdlet removes a SeppMail configuration.
If the configuration to remove is configured either as active configuration or as default configuration, a warning message will be displayed. Configuration which are configured as active or default configuration can only be removed with the Force switch.

.PARAMETER ConfigurationName
The parameter is mandatory. Data type string.
The name of the configuration to remove.

.PARAMETER Force
The parameter is optional. Data type SwitchParameter
If a configuration, which should be removed, is configured as default or active configuration, this parameter must be used

.EXAMPLE
Remove-SMAConfiguraiton -ConfigurationName <name of config>
Removes a particular configuration.

.EXAMPLE
Remove-SMAConfiguraiton -ConfigurationName <name of config> -Force
Removes a particular configuration. Even the configuration is configured as default or active configuration, the configuration will be removed.
#>

[cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='High')]    
param([Parameter(Mandatory = $true, HelpMessage='Enter the name of the configuration to remove',Position = 0)][ArgumentCompleter( {
    param ( $CommandName,
        $ParameterName,
        $WordToComplete,
        $CommandAst,
        $FakeBoundParameters )  
    $tmpList=$__SEPPmailAPI_ModuleData.getConfigList();
    $cfgList=@();
    foreach ($item in $tmpList)
    {
        if ($item.contains(' '))
        {
            $cfgList+="'"+$item+"'";
        } # end if
        else {
            $cfgList+=$item;
        }; # end else
    };
    $cfgList.Where({ $_ -like "$wordToComplete*" });
    } )][string]$ConfigurationName,
    [Parameter(Mandatory = $false, Position = 2)][switch]$Force
            
     )

    begin {

    }; # end begin

    process {
        
        try {
            writeLogOutput -LogString ('Reading configuration for ' + $ConfigurationName);
            $msg=('Failed to read configuration ' + $ConfigurationName);
            $cfgFullName=($script:cfgNamePrefix +  $ConfigurationName);
            $tmp=Get-SecretInfo -Name $cfgFullName -Vault $Script:vaultName;
            if ($tmp)
            {                
                writeLogOutput -LogString ('Removing configuration ' + $ConfigurationName);
                if ($WhatIfPreference)
                {
                    writeLogOutput -LogString ('What if: Configuration ' + $ConfigurationName + ' would be removed.') -ShowInfo;
                } # end if
                else {
                    if($PSCmdlet.ShouldProcess('Performing on ',('SMA configuraiton ' + $ConfigurationName),'DELETION'))
                    {
                        try {
                            if (removeDefaultOrActiveCfg -ConfigurationName $ConfigurationName -Force:$Force.IsPresent)
                            {
                                Remove-Secret -Name $cfgFullName -Vault $script:vaultName -ErrorAction Stop;
                            } # end if
                            else {
                                writeLogOutput -LogString ('The configuration ' + $ConfigurationName + ' is either active or is configured as the default configuration. To remove the configuration use the parameter Force.') -LogType Warning;
                            }; # end if remove default cfg
                        } # end try
                        catch {
                            $msg=('Failed to remove the configuration ' + $ConfigurationName);
                            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_; 
                        }; # end catch
                    }; # end if confirm
                }; # end else WhatIF                                                   
            } # end if
            else {
                writeLogOutput -LogString ('Configuration ' + $ConfigurationName + ' not found.') -LogType Warning;
            }; # end else
        } # end try
        catch {
            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
        }; # end catch        
    }; # end process

    end {

    }; # end END
    
}; # end function Remove-SMAConfiguration

function Test-SMAConfiguration
{
<#
.SYNOPSIS 
Test a configuration.
.DESCRIPTION
The cmdlet performs some tests against a SeppMail appliance.
.PARAMETER ConfigurationName
The parameter is mandatory. Data type string.
The name of a configuration, which should be tested against a SeppMail appliance.

.EXAMPLE
Test-SMAConfiguration -ConfigurationName <name of config>
#>
[cmdletbinding()]    
param([Parameter(Mandatory = $true, HelpMessage='Enter the name of the configuration to test',Position = 0)][ArgumentCompleter( {
    param ( $CommandName,
        $ParameterName,
        $WordToComplete,
        $CommandAst,
        $FakeBoundParameters )  
    $tmpList=$__SEPPmailAPI_ModuleData.getConfigList();
    $cfgList=@();
    foreach ($item in $tmpList)
    {
        if ($item.contains(' '))
        {
            $cfgList+="'"+$item+"'";
        } # end if
        else {
            $cfgList+=$item;
        }; # end else
    };
    $cfgList.Where({ $_ -like "$wordToComplete*" });
    } )][string]$ConfigurationName
            
     )

    begin {

    }; # end begin

    process {
        
        try {
            writeLogOutput -LogString ('Reading configuration for ' + $ConfigurationName);
            $msg=('Failed to read configuration ' + $ConfigurationName);
            $cfgFullName=($script:cfgNamePrefix + $ConfigurationName);
            $tmp=Get-SecretInfo -Name $cfgFullName -Vault $Script:vaultName;
            $tmpCred=Get-Secret -Name $cfgFullName -Vault $Script:vaultName;

            if ($tmp)
            {
                $smaHostName=$tmp.Metadata.SMAHost
                writeLogOutput -LogString ('Testing host ' + $smaHostName);
                writeLogOutput -LogString ('Trying to resolve host ' + $smaHostName);
                try {
                    $msg=('Failed to resolve host ' + $smaHostName);
                    [System.Net.Dns]::GetHostByName($smaHostName);
                } # end try
                catch {
                    writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
                }; # end catch
                $msg=('Failed to test prot ' + ($tmp.Metadata.SMAPort) + ' on server ' + $smaHostName)
                If (! (testPort -ComputerName $smaHostName -Port $tmp.Metadata.SMAPort))
                {
                    writeLogOutput -LogString ('Failed to reach the host ' + $smaHostName + ' on port ' + ($tmp.Metadata.SMAPort)) -LogType Warning;
                }; # end if
                $msg=('Failed to test the access to SeppMail on server ' + $smaHostName);
                $paramList=@{
                    SMACred=(New-Object System.Management.Automation.PSCredential ($tmpCred.UserName, $tmpCred.Password));
                    SMAHost=$smaHostName;
                    SMAPort=$tmp.Metadata.SMAPort;
                    SMASkipCertCheck=[bool]$tmp.Metadata.SMASkipCertCheck;
                    SMAPIVersion=$tmp.Metadata.SMAPIVersion;
                }; # end paramList
                if (! (testSMALocalAdmin @paramList))
                {
                    writeLogOutput -LogString ('Failed to access SeppMail on server ' + $smaHostName) -LogType Warning;
                }; # end if
            } # end if
            else {
                writeLogOutput -LogString ('Configuration ' + $ConfigurationName + ' not found.') -LogType Warning;
            }; # end else
        } # end try
        catch {
            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
        }; # end catch        
    }; # end process

    end {

    }; # end END
}; # end function Test-SMAConfiguration



function Set-SMAConfiguration
{
<#
.SYNOPSIS 
Updates a configuration.
.DESCRIPTION
The cmdlet can update some attributes of an existing configuration. The cmdlet can configure a configuration as
-	Default configuration
-	Active configuration

.PARAMETER ConfigurationName
The parameter is mandatory. Data type string.
The name of the configuration which should be updated.

.PARAMETER SMAHost
The parameter is optional. Data type string.
The FQDN of the SeppMail appliance.

.PARAMETER SMACred
The parameter is optional. Data type PSCredential
The parameter expects API key and the secret for the SeppMail Appliance.

PARAMETER SMAPort
The parameter is optional. Data type Int32
The parameter expects port for the SeppMail Appliance.

PARAMETER SMAPIVersion
The parameter is optional. Data type custom enumerator.
The parameter expects the version for the SeppMail API. Currently only
-	v1
is a valid value.

PARAMETER SMASkipCertCheck
The parameter is optional. Data type Boolean.
The parameter expects a Boolean value (if certificate check should be skipped). 

PARAMETER SetAsDefault
The parameter is optional. Data type SwitchParameter.
If the parameter is used, the configuration will be configured as default configuration. The default configuration will be loaded ad active configuration, when the PowerShell module SeppMail will be loaded. 
The parameter cannot be used with any other parameters except the parameter ConfigurationName.

PARAMETER SetActive
The parameter is optional. Data type SwitchParameter.
If the parameter is used, the configuration will be configured as active configuration. The active configuration will provide the default values for the *-SMA* cmdlets for the configuration and administration of the SeppMail appliance. The active configuration provides the following parameters:
-	SMAHost
-	SMACred
-	SMAPort
-	SMAPIVersion
-	SMASkipCertCheck
Every administration cmdlet uses these parameters. The cmdlets provide parameters, which can overwrite the values of the active configuration.
The parameter cannot be used with any other parameters except the parameter ConfigurationName.

.EXAMPLE
Set-SMAConfiguration -ConfigurationName <config name> -SetAsDefault
The configuration will be configured as default configuration.

.EXAMPLE
Set-SMAConfiguration -ConfigurationName <config name> -SetActive
The configuration will be configured as active configuration.

.EXAMPLE
Set-SMAConfiguration -ConfigurationName <config name> -SMAHost <host name FQDN>
The attribute SMAHost of the configuration will be updated.

#>
[cmdletbinding(DefaultParameterSetName='__AllParameter',SupportsShouldProcess=$true)]
param([Parameter(Mandatory = $true, HelpMessage='Enter the name of the configuration to reconfigure', Position = 0)][ArgumentCompleter( {
    param ( $CommandName,
        $ParameterName,
        $WordToComplete,
        $CommandAst,
        $FakeBoundParameters )  
    $tmpList=$__SEPPmailAPI_ModuleData.getConfigList();
    $cfgList=@();
    foreach ($item in $tmpList)
    {
        if ($item.contains(' '))
        {
            $cfgList+="'"+$item+"'";
        } # end if
        else {
            $cfgList+=$item;
        }; # end else
    };
    $cfgList.Where({ $_ -like "$wordToComplete*" });
    } )][string]$ConfigurationName,

      [Parameter(ParametersetName='Cfg',Mandatory = $false,
      Position = 1)][string]$SMAHost,
      [Parameter(ParametersetName='Cfg',Mandatory = $false,
      Position = 2)][System.Management.Automation.PSCredential]$SMACredential,
      [Parameter(ParametersetName='Cfg',Mandatory = $false,
      Position = 3)][int]$SMAPort,
      [Parameter(ParametersetName='Cfg',Mandatory = $false,
      Position = 4)][SMAPIVer]$SMAPIVersion,
      [Parameter(ParametersetName='Cfg',Mandatory = $false,
      Position = 5)][Boolean]$SMASkipCertCheck,
      [Parameter(ParametersetName='SetDef',Mandatory = $false,
      Position = 6)][switch]$SetAsDefault=$false,
      [Parameter(ParametersetName='SetActive',Mandatory = $false,
      Position = 6)][switch]$SetActive=$false
     )

    begin {

    }; # end begin

    process {
        $configName= ($Script:cfgNamePrefix + $ConfigurationName);
        if (!(Get-SecretInfo -Name $configName -Vault $Script:vaultName))
        {
            writeLogOutput -LogString ('A configuration with the name ' + $ConfigurationName + ' does not exist') -LogType Error;
            return;
        } # end if
        else {
            switch ($PSCmdlet.ParameterSetName)
            {
                'SetActive'    {
                    if ($WhatIfPreference)
                    {
                        writeLogOutput -LogString ('Setting  configuration ' + $ConfigurationName + ' as active configuration') -ShowInfo;
                    } # end if
                    else {
                        setConfigAsActive -ConfigurationName $ConfigurationName;
                    }; # end if                    
                    break;
                }; # end Cfg
                'Cfg'           {
                    if ($WhatIfPreference)
                    {
                        writeLogOutput -LogString ('Changing  configuration settings for ' + $ConfigurationName) -ShowInfo;
                    } # end if
                    else {
                        $tmpCfg=@{};
                        $paramsToExclude=[System.Management.Automation.PSCmdlet]::CommonParameters;
                        $paramsToExclude+=[System.Management.Automation.PSCmdlet]::OptionalCommonParameters;
                        $paramsToExclude+='ConfigurationName';
                        $paramList=$PSBoundParameters.Keys;
                        $tmp=[System.Linq.Enumerable]::Except([string[]]$paramList,[string[]]$paramsToExclude);
                        $attribList=[System.Collections.ArrayList]::new();
                        [void]$attribList.AddRange([array]$tmp);
                        foreach ($attrib in $attribList)
                        {
                            $val=(Get-Variable -Name $attrib -ValueOnly);
                            switch ($val.GetType().name)
                            {
                                {$_ -in @('String','Int32')}    {
                                    $tmpCfg.Add($attrib,$val);
                                    break;
                                }; # end string
                                'SMAPIVer'  {
                                    $tmpCfg.Add($attrib,($val.ToString()));
                                    break;
                                }; # end SMAPIVer
                                'SwitchParameter'   {
                                    $tmpCfg.Add($attrib,([int]$val.IsPresent));
                                    break;
                                }; # end Boolean
                                'Boolean'   {
                                    $tmpCfg.Add($attrib,([int]$val));
                                    break;
                                }; # end Boolean
                                Default     {                                    
                                    $tmpCfg.Add($attrib,$val);
                                }; #end default
                            }; # end switch                            
                        }; # end foreach
                        setConfigAttributes -ConfigurationName $ConfigurationName -CfgItems $tmpCfg -KeyList $attribList;                        
                    }; # end if
                    break;
                }; # end Cfg
                'SetDef'        {
                    if ($WhatIfPreference)
                    {
                        writeLogOutput -LogString ('Setting  configuration ' + $ConfigurationName + ' as default configuration') -ShowInfo;
                    } # end if
                    else {    
                        setDefaultCfg -ConfigurationName $ConfigurationName;                
                    }; # end if
                    break;
                }; # end setDef                
            }; # end switch
            
        }; # end else        
    }; #end process
    
    end {

    }; # end END
}; # end function Set-SMAConfiguration
