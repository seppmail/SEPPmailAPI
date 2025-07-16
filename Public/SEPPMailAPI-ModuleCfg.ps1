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
function Get-SMAConfiguration
{
[cmdletbinding(DefaultParametersetName='__AllParameter')]    
param(
    [Parameter(
        ParameterSetName='CfgFromVault',
        Mandatory = $false,
        Position = 0
        )
    ]
    [ArgumentCompleter( 
            {
                param ( 
                    $CommandName,
                    $ParameterName,
                    $WordToComplete,
                    $CommandAst,
                    $FakeBoundParameters
                )  
                $tmpList=$__SEPPmailAPI_ModuleData.getConfigList();
                $cfgList=@();
                
                foreach ($item in $tmpList) {
                    if ($item.contains(' ')) {
                        $cfgList+="'"+$item+"'";
                        } # end if
                    else {
                        $cfgList+=$item;
                        }; # end else
                    };
                
                    $cfgList.Where({ $_ -like "$wordToComplete*" }
                );
            } 
        )
    ]
    [string]$ConfigurationName,
      
    [Parameter(
        ParameterSetName='Default',
        Mandatory = $false, 
        Position = 0)
    ]
    [switch]$Default=$false,
    
    [Parameter(
        ParameterSetName = 'ListAll',
        Mandatory = $false,
        Position = 0
        )
    ]
    [switch]$List = $false,

    [Parameter(
        Mandatory = $false,
        Position = 2
        )
    ]
    [Validateset('Table','List','PassValue')]
    [String]$Format='Table'      
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
    
} # end funciton Get-SMAConfiguration

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
function New-SMAConfiguration
{
[cmdletbinding()]    
    param(  
        [Parameter(
            Mandatory = $true, 
            HelpMessage='Enter a unique configuration name',
            Position = 0)
        ]
        [string]$ConfigurationName,

        [Parameter(
            Mandatory = $true, 
            HelpMessage='Enter the name of the SeppMail host',
            Position = 1)
        ]
        [string]$SMAHost,

        [Parameter(
            Mandatory = $true, 
            HelpMessage='Enter the SeppMail credential',
            Position = 2)
        ]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(
            Mandatory = $false,
            Position = 3
            )
        ]
        [int]$SMAPort=$Script:SMADefaultPort, #$__SEPPmailAPI_ModuleData.SMADefaultPort,

        [Parameter(
            Mandatory = $false,
            HelpMessage='Enter the SeppMail API version',
            Position = 3
            )
        ]
        [SMAPIVer]$SMAIPVersion=$Script:DefaultAPIVer,

        [Parameter(
            Mandatory = $false,
            Position = 4
            )
        ]
        [switch]$SMASkipCertCheck=$false
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
} # end function New-SMAConfiguration

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
function Remove-SMAConfiguration
{
    [cmdletbinding(
            SupportsShouldProcess=$true,
            ConfirmImpact='High'
        )
    ]    
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage='Enter the name of the configuration to remove',
            Position = 0
            )
        ]
        [ArgumentCompleter( 
                {
                param ( 
                    $CommandName,
                    $ParameterName,
                    $WordToComplete,
                    $CommandAst,
                    $FakeBoundParameters 
                )  
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
                }
                $cfgList.Where({ $_ -like "$wordToComplete*" })
                }
            )
        ]
        [string]$ConfigurationName,
        [Parameter(
            Mandatory = $false,
            Position = 2)
        ]
        [switch]$Force
    )

    begin {

    } # end begin

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

function Test-SMAConfiguration
{
    [cmdletbinding()]    
        param(
            [Parameter(
                Mandatory = $true,
                HelpMessage='Enter the name of the configuration to test',
                Position = 0
                )
            ]
            [ArgumentCompleter( 
                    {
                    param (
                        $CommandName,
                        $ParameterName,
                        $WordToComplete,
                        $CommandAst,
                        $FakeBoundParameters 
                        )  
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
                    } 
                )
            ]
            [string]$ConfigurationName
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
                $msg=('Failed to test port ' + ($tmp.Metadata.SMAPort) + ' on server ' + $smaHostName)
                If (! (testPort -ComputerName $smaHostName -Port $tmp.Metadata.SMAPort))
                {
                    writeLogOutput -LogString ('Failed to reach the host ' + $smaHostName + ' on port ' + ($tmp.Metadata.SMAPort)) -LogType Warning;
                }; # end if
                $msg=('Failed to test the access to SEPPMail on server ' + $smaHostName);
                $paramList=@{
                    SMACred=(New-Object System.Management.Automation.PSCredential ($tmpCred.UserName, $tmpCred.Password));
                    SMAHost=$smaHostName;
                    SMAPort=$tmp.Metadata.SMAPort;
                    SMASkipCertCheck=[bool]$tmp.Metadata.SMASkipCertCheck;
                    SMAPIVersion=$tmp.Metadata.SMAPIVersion;
                }; # end paramList
                if (! (testSMAUserStats @paramList))
                {
                    writeLogOutput -LogString ('Failed to access Statistics on server ' + $smaHostName + ' and port ' + $tmp.Metadata.SMAPort) -LogType Error;
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
function Set-SMAConfiguration
{
    [cmdletbinding(
        DefaultParameterSetName='__AllParameter',
        SupportsShouldProcess=$true)
    ]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage='Enter the name of the configuration to reconfigure',
            Position = 0)
        ]
        [ArgumentCompleter(
            {
                param ( 
                    $CommandName,
                    $ParameterName,
                    $WordToComplete,
                    $CommandAst,
                    $FakeBoundParameters
                    )  
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
                } 
            )
        ]
        [string]$ConfigurationName,

        [Parameter(
            ParametersetName='Cfg',
            Mandatory = $false,
            Position = 1
            )
        ]
        [string]$SMAHost,
        [Parameter(
            ParametersetName='Cfg',
            Mandatory = $false,
            Position = 2
            )
        ]
        [System.Management.Automation.PSCredential]$SMACredential,
        [Parameter(
            ParametersetName='Cfg',
            Mandatory = $false,
            Position = 3
            )
        ]
        [int]$SMAPort,
        [Parameter(
            ParametersetName='Cfg',
            Mandatory = $false,
            Position = 4
            )
        ]
        [SMAPIVer]$SMAPIVersion,
        [Parameter(
            ParametersetName='Cfg',
            Mandatory = $false,
            Position = 5
            )
        ]
        [Boolean]$SMASkipCertCheck,
        [Parameter(
            ParametersetName='SetDef',
            Mandatory = $false,
            Position = 6
            )
        ]
        [switch]$SetAsDefault=$false,
        [Parameter(
            ParametersetName='SetActive',
            Mandatory = $false,
            Position = 6
            )
        ]
        [switch]$SetActive=$false
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
                } # end setDef                
            } # end switch
            
        } # end else        
    } #end process
    
    end {

    } # end END
} # end function Set-SMAConfiguration
# SIG # Begin signature block
# MIIVzAYJKoZIhvcNAQcCoIIVvTCCFbkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD8YpQmURnDlcfw
# B3EveeZROaPVAlf6/EehMwgRTQ5KPqCCEggwggVvMIIEV6ADAgECAhBI/JO0YFWU
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
# BgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCDrsRxTJJ7BUlh+4XOLRX2lYH+p
# Ia1k49h4T50ocxl/nDANBgkqhkiG9w0BAQEFAASCAgBQ11XZv3EIYYL0YH/P6zZI
# p2Q9JxYvu5BbXqtxiX2PZurA2mIK96CrAvV0mBmStSXMUTvROT1DNXotfEIIjCNZ
# 8AqK5u6X8uTA5barqzaN+FLXwPpHaNtoAJw+HGDg1oQaYrEQcVGw1NO8h6zxUQ6f
# 5ofgt+Y6vVcTLwM0L2lH8D3s0qjybIKMllcu9yoAyGAzEcg9pZDw2eG+JUuQbqdo
# /WURHUSDIZx4dTmOT+QDw8XctN/6HuvpXXPCEmkUuu8atU5IrV+pfZbTKFi/N+PB
# Qi0hdxb50BEJPR5eawzLJ63LCvusb0s/woYlAnb34eAEN5lwkp91eCCzFoI38uQ2
# 5ML9XacFOjZlPO6WqtUckTdOIY+bhJ/4ZQHfAG54StB67wdgVw1vNczCRffV+epB
# bGd0M7U+11BH+x3AM42TqOO+2QTSVw9DvFSwrSkiJzMk+rz4Fu2kv5QMIc/xiHgb
# e6BUoes7pjogMnB0/0XqEE7zYAS08srPO9702gojXaLIAsaQbHLc2BuaquvWazDl
# tSZH54UUuaW8qmF8VHh17d3z96zSO1kzNnrWv7EtJlJIWnRs3cjCwdUKAagjs0Xn
# 1wabzChPgNw07ca7NMbZg8mlS79YjZ4h8SqMEbG5GSbioXclk3VVQ3MaPbH3Di8c
# tOyYXNzalaMDR/r/QSl9vw==
# SIG # End signature block
