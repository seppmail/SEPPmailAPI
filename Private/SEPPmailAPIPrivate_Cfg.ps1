function initModule
{
    
    try
    {
        $vaultList=@(Get-SecretVault -ErrorAction Stop | Where-Object {$_.ModuleName -eq $script:SecureVaultModuleName} );
    } # end try
    catch
    {
        $msg='Failed to search for a vault';
        writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
        return;
    }; # end catch

    if (!($vaultList.name -contains $Script:vaultName))  # verify if vault exist
    {
        $msg=('Creating vault ' + $Script:vaultName);
        writeLogOutput -LogString $msg;
        try {
            writeLogOutput -LogString 'Setting authentication for secret store to NONE! - This is not the most secure setup. To change use Set-SecretStoreConfiguration' -LogType Warning
            $tempPassword = 'SEPPmail' |Convertto-SecureString -Asplaintext -Force
            Set-SecretStoreConfiguration -Authentication None -Interaction None -Password $tempPassword -Confirm:$false
            writeLogOutput -Logstring 'Registering the SEPPmail Vault without password required.' -LogType Info
            $storeVaultParam = @{Authentication = 'none';Interaction = 'none'}
            Register-SecretVault -ModuleName $script:SecureVaultModuleName -Name $Script:vaultName -Description 'Created by SMA PS module' -VaultParameters $storeVaultParam            
        } # end try
        catch {
            $msg=('Failed to register vault ' + $Script:vaultName);
            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
            return;
        }; # end catch
    }; # end if
    
    getModuleConfig;
    loadModuleConfig;
    checkTLS;

}; # end function initModule

function checkTLS
{
    writeLogOutput -LogString  'Check/set TLS Version 1.2'
    if (([Net.ServicePointManager]::SecurityProtocol) -eq 'Ssl3, Tls') {
        writeLogOutput -LogString  "TLS was 1.0, set to version 1.2"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    } # end if
    else 
    {
        writeLogOutput -LogString  "TLS is version 1.2"
    }; # end else
}; # end function checkTLS

function getModuleConfig
{
    
    if (!($script:ModuleCfg=Get-SecretInfo -Name $Script:SMAModuleCfgName -Vault $Script:vaultName -ErrorAction SilentlyContinue)) # check if the module config exist
    {
        try { # if module cfg does not exist, create an empty cfg
            Set-Secret -Name $Script:SMAModuleCfgName -Secret 'SeppMail' -Metadata @{Version=$script:ModuleCfgVer;DefaultCfgName='';LastLoadedCfgName='';} -Vault $Script:vaultName;
            $Script:ModuleCfg=Get-SecretInfo -Name $Script:SMAModuleCfgName -Vault $Script:vaultName -ErrorAction Stop;
        } # end try
        catch {
            $msg='Failed to initialize the module configuration.';
            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
        }; # end catch
    };# end if
    
}; # end function getModuleConfig

function loadModuleConfig
{   
    try {
        $defCfg=(Get-SecretInfo -Vault $Script:vaultName -Name $script:SMAModuleCfgName -ErrorAction Stop).Metadata;
    } # end try
    catch {
        $msg='Failed to load the module configuration.'
        writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
    }; #end catch
    switch ($defCfg)
    {
        {!([system.string]::IsNullOrEmpty($_.DefaultCfgName))}      {
            If (loadSMAConfigFromVault -ConfigName ($script:cfgNamePrefix + $_.DefaultCfgName) -ReturnLoadSuccess -ModuleCfgItem 'DefaultCfgName')
            {
                break;
            }; # end if            
        }; # end is default cfg available
        {!([system.string]::IsNullOrEmpty($_.LastLoadedCfgName))}   {
            if (loadSMAConfigFromVault -ConfigName ($script:cfgNamePrefix + $_.LastLoadedCfgName) -ReturnLoadSuccess -ModuleCfgItem 'LastLoadedCfgName')
            {
                break; 
            }; # end if             
        }; # end is last loaded cfg available
        Default                                                     {
            try {
                $cfgList=(Get-SecretInfo -Vault $Script:vaultName -Name ($script:cfgNamePrefix + '*'))
                switch ($cfgList.count)
                {
                    0       {
                        writeLogOutput -LogString 'No SeppMail configuration found. Please create a config with the cmdlet New-SMAConfiguration.' -ShowInfo:$Script:ShowMsgIfNoCfgLoaded;
                    }; # end no cfg found
                    1       {                        
                        if ($Script:LoadCfgIfOnlyOneExist)
                        {
                            loadSMAConfigFromVault -ConfigName ($cfgList[0].name);
                            writeLogOutput -LogString ('Configuration ' + (($cfgList[0].name).Replace(($script:cfgNamePrefix),'')) + ' loaded.') -ShowInfo:$Script:ShowMsgIfNoCfgLoaded;                            
                        }; # end if                                                
                    }; # end one config found
                    Default {
                        writeLogOutput -LogString 'Multiple SeppMail configurations found. Please select the appropriate configuration with the cmdlet Set-SMAConfiguration.' -ShowInfo:$Script:ShowMsgIfNoCfgLoaded;
                    }; # end multiple configs found
                }; # end switch
            } # end try
            catch {
                $msg='Failed to load a SeppMail configuration.'
                writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
            }; # end catch            
        }; # end default
    }; # end switch
}; # end function loadModuleConfig

function createNewTable
{
[cmdletbinding()]
param([Parameter(Mandatory = $true, Position = 0)][string]$TableName,
      [Parameter(Mandatory = $true, Position = 1)][array]$FieldList
     )
    
    $tmpTable = New-Object System.Data.DataTable $TableName; # init table   
    $fc=$FieldList.Count;
        
    for ($i=0;$i -lt $fc;$i++)
    {
        if ((!($null -eq $FieldList[$i][1])) -and ($FieldList[$i][1].GetType().name -eq 'runtimetype'))
        {
            [void]($tmpTable.Columns.Add(( New-Object System.Data.DataColumn($FieldList[$i][0],$FieldList[$i][1])))); # add columns to table
        } # end if
        else
        {
            [void]($tmpTable.Columns.Add(( New-Object System.Data.DataColumn($FieldList[$i][0],[System.String])))); # add columns to table
        }; #end else
    }; #end for
    
    return ,$tmpTable;
}; # end createNewTable

function testPort
{
[CmdLetBinding()]            
param([Parameter(Mandatory = $true, Position = 0)][string]$ComputerName,
      [Parameter(Mandatory = $true, Position = 1)][int]$Port
     # [Parameter(Mandatory = $false, Position = 2)][int]$TcpTimeout=100    
     )

    begin {        
    }; #end begin
    
    process {
        writeLogOutput -LogString ('Testing port ' + $Port.ToString() + ' on computer ' + $computerName);
        $msg=('Failed to access server ' + $ComputerName + ' on port ' + $Port);
        try {
            if (($PSVersiontable.Platform -eq 'Win32NT') -or ($PSVersiontable.PSEdition -eq 'Desktop')) 
            {
                # Windows
                $tmp=Test-NetConnection -ComputerName $ComputerName -Port $Port -ErrorAction Stop;
                return ($tmp.TcpTestSucceeded)
            } else 
            {
                # Linux/MacOS
                $tmp = Test-Connection -TargetName $Computername -TcpPort $Port -ErrorAction Stop;
                return ($tmp);  # return bool
            }; # end else
        }
        catch {
            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
            return $false;
        }    
    }

    end {        
    } # end END

}; # end function testPort
#>

function loadSMAConfigFromVault
{
[cmdletbinding()]
param([Parameter(Mandatory = $true, Position = 0)][string]$ConfigName,
      [Parameter(Mandatory = $false, Position = 1)][switch]$ReturnLoadSuccess=$false,
      [Parameter(Mandatory = $false, Position = 2)][string]$ModuleCfgItem
     )
    
    $loadSuccess=$false;
    if (Get-SecretInfo -Name $ConfigName -Vault $Script:vaultName)
    {
        try {
            $cfgFreindlyName=($ConfigName.Replace(($Script:cfgNamePrefix),''));
            $msg='Faild to get cred info.';
            $tmpVal=(Get-Secret -Name $ConfigName -Vault $Script:vaultName -ErrorAction Stop);
            if ($tmpVal.GetType().Name -eq 'PSCredential')
            {
                $script:activeCfg.SMACred=$tmpVal;
            } # end if
            else {
                writeLogOutput -LogString ('Credential in configuration ' + $cfgFreindlyName + ' is not valid.') -LogType Warning;
            }; # end else
            $msg='Failed to read the config data';
            $tmpVal=((Get-SecretInfo -Name $ConfigName -Vault $Script:vaultName -ErrorAction Stop).Metadata);
            $msg='Failed to copy the SMAPort value';
            $script:activeCfg.SMAPort=($tmpVal.SMAPort);
            $msg='Failed to copy the SMAHost value';
            $script:activeCfg.SMAHost=($tmpVal.SMAHost);
            $msg='Failed to copy the SAMSkipCertCheck value';
            $script:activeCfg.SMASkipCertCheck=[bool]($tmpVal.SMASkipCertCheck);  
            $msg='Failed to copy the SAMPIVersion value';
            $script:activeCfg.SMAPIVersion=($tmpVal.SMAPIVersion);
            $script:activeCfg.SMACfgName=$cfgFreindlyName;
            $loadSuccess=$true;      
        } # end try
        catch {            
            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
        }; # end catch
    } # end if, check if cfg exist 
    else {
        if ($PSBoundParameters.ContainsKey('ModuleCfgItem'))
        {
            clearCfgEntry -EntryName $ModuleCfgItem -CfgName $ConfigName;
        }; # end if
    }; # end if

    if ($ReturnLoadSuccess)
    {
        return $loadSuccess;
    }; # end if
}; # end loadSMAConig

function clearCfgEntry
{
[cmdletbinding()]
param([Parameter(Mandatory = $true, Position = 0)][string]$EntryName,
      [Parameter(Mandatory = $false, Position = 1)][string]$CfgName
     )

    try {
        if ($PSBoundParameters.ContainsKey('CfgName'))
        {
            writeLogOutput -LogString ('Resetting value for ' + $EntryName + ' to a blank value, because the configuration ' + ($CfgName.Replace(($Script:cfgNamePrefix),'')) + ' is missing') -LogType Warning;
        }; # end if        
        [hashTable]$cfg=(Get-SecretInfo -Name $Script:SMAModuleCfgName -Vault $Script:vaultName -ErrorAction Stop).Metadata;
        $cfg.$EntryName='';
        $newHashTable=@{};
        foreach ($entry in $cfg.Keys)
        {
            if ($cfg.$entry.gettype().Name.startswith('Int'))
            {
                $newHashTable.Add($entry,([int]$cfg.$entry));
            } # end if
            else {
               $newHashTable.Add($entry,$cfg.$entry); 
            }; # end else
            
        }; # end foreach
        Set-SecretInfo -Name $Script:SMAModuleCfgName -Vault $Script:vaultName -Metadata $newHashTable -ErrorAction Stop;
    } # end try
    catch {
        $msg=('Failed to clear the module configuration attribute ' + $EntryName);
        writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
    }; # end catch
     
}; # end if clearCfgEntry

function writeLogError
{
[cmdletbinding()]
param([Parameter(Mandatory = $true, Position = 0)][string]$ErrorMessage,
      [Parameter(Mandatory = $true, Position = 1)][string]$PSErrMessage,
      [Parameter(Mandatory = $true, Position = 2)][string]$PSErrStack
     )

    writeLogOutput -LogString $ErrorMessage -LogType Error;
    writeLogOutput -LogString $PSErrMessage -LogType Error;
}; # end function writeLogError

function testSMARequieredParameters
{
[cmdletbinding()]
param([Parameter(Mandatory = $true, Position = 0)][AllowEmptyString()][string]$SMAHost,
      [Parameter(Mandatory = $false, Position = 1)][AllowEmptyString()][string]$SMAPort,
      [Parameter(Mandatory = $false, Position = 2)][System.Management.Automation.PSCredential]$SMACredential
     )

    switch ($true)
    {
        {($null -eq $SMACredentials)} {
            Throw ('SMACredential requiered.')
        }; # end SMACredentials
        {[System.String]::IsNullOrEmpty($SMAHost)} {
            Throw ('SMAHost requiered.')
        }; # end SMAHost
        {[System.String]::IsNullOrEmpty($SMAPort)} {
            Throw ('SMAPort requiered.')
        }; # end SMA Port
    };
}; # end function testSMARequieredParameters


function writeLogOutput
{
[CmdLetBinding()]
param([Parameter(Mandatory = $true, Position = 0)]
      [string]$LogString,
      [Parameter(Mandatory = $false, Position = 2)]
      [ValidateSet('Info','Warning','Error')] 
      [string]$LogType="Info",      
      [Parameter(Mandatory = $false, Position = 10)]
      [switch]$ShowInfo=$false
     )

    if (($LogType -eq 'Info') -and ($ShowInfo.IsPresent -eq $false))
    {
        Write-Verbose -Message $LogString;
    }; # end if

    switch ($LogType)
    {
        {$_ -eq 'Info' -and $ShowInfo}  {
            Write-Host $LogString;
            break;
        }; # end info and ShowInfo
        'Warning'                       {
            Write-Warning $LogString;
            break;
        }; # end warning
        'Error'                         {
            Write-Host $LogString -ForegroundColor Red -BackgroundColor Black;
            break;
        }; # end Error
    }; # end switch
}; # end function writeLogOutput


function formatConfigData
{
[cmdletbinding()]
param([Parameter(ParametersetName='StoreCfg',Mandatory = $true, Position = 0)][Array]$ConfigData,
      [Parameter(ParametersetName='ActiveCfg',Mandatory = $true, Position = 0)][switch]$ActiveConfigData,
      [Parameter(Mandatory = $true, Position = 1)][string]$DefaultCfgName
     )
    
    $fieldList=@(
        @('ConfigName',[System.String]),
        @('UserName',[System.String]),
        @('SMAHost',[System.String]),
        @('SMAPort',[system.int32]),
        @('SMASkipCertCheck',[System.Boolean]),
        @('SMAPIVersion',[System.String]),
        @('Active Cfg',[System.Boolean]),
        @('Default Cfg',[System.Boolean])
    ); # end fieldList
    $dataTable=createNewTable -TableName 'SMACfg' -FieldList $fieldList;
    if ($PSCmdlet.ParameterSetName -eq 'StoreCfg')
    {
        foreach ($cfgEntry in $ConfigData)
        {
            try {
                $userName=(Get-Secret -Name ($cfgEntry.Name) -Vault $Script:vaultName).UserName;
            } # end try
            catch {
                $userName='unknown';
                $msg=('Failed to get the user name for the configuration ' + $entry.name)
                writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
            }; # end catch
            $entryName=(($cfgEntry.name).Replace($script:cfgNamePrefix,'')).Replace(($Script:cfgNamePrefix),'');
            $dataRow=@(
                $entryName,
                $userName,
                $cfgEntry.MetaData.SMAHost,
                $cfgEntry.MetaData.SMAPort,
                ([bool]$cfgEntry.MetaData.SMASkipCertCheck),
                $cfgEntry.MetaData.SMAPIVersion,
                ($entryName -eq $Script:activeCfg.SMACfgName),
                ($DefaultCfgName -eq $entryName)
            ); # end dataRow
            [void]($dataTable.Rows.Add($dataRow));
        }; # end foreach
    } # end if
    else
    {                
        $dataRow=@(
            ($Script:activeCfg.SMACfgName),
            $Script:activeCfg.SMACred.userName,
            $Script:activeCfg.SMAHost,
            $Script:activeCfg.SMAPort,
            ([bool]$Script:activeCfg.SMASkipCertCheck),
            ($Script:activeCfg.SMAPIVersion),
            $true,
            ($DefaultCfgName -eq ($Script:activeCfg.SMACfgName))
        );
        [void]($dataTable.Rows.Add($dataRow));
    };
    return ,$dataTable;
}; # end function formatConfigData


function isConfigurationDefaultOrActive
{
[CmdLetBinding()]            
param([Parameter(Mandatory = $true, Position = 0)][string]$ConfigurationName,
      [Parameter(Mandatory = $true, Position = 1)][ValidateSet('Default','Active')][string]$ConfigurationType
     )

    if ($ConfigurationType -eq 'Default')
    {
        try {            
            writeLogOutput ('Determining the default configuration')
            $defCfgName = (Get-SecretInfo -Name $Script:SMAModuleCfgName -Vault $Script:vaultName).Metadata.DefaultCfgName;
            return ($defCfgName -eq $ConfigurationName);
        } # end try
        catch {
            $msg='Failed to verify the default configuration.';
            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;;
        }; # end catch
    } # end if
    else {
        writeLogOutput ('Determining the active configuration')
        return ($ConfigurationName -eq $Script:activeCfg.SMACfgName);
    }; # end else
}; # end funciton getCfgNameFromConfig

function removeDefaultOrActiveCfg
{
[CmdLetBinding()]            
param([Parameter(Mandatory = $true, Position = 0)][string]$ConfigurationName,
      [Parameter(Mandatory = $false, Position = 1)][switch]$Force=$false
     )
    
    $testVal=0;
    $testVal=($testVal -bor (1*[int](isConfigurationDefaultOrActive -ConfigurationName $ConfigurationName -ConfigurationType 'Default')));
    $testVal=($testVal -bor (2*[int](isConfigurationDefaultOrActive -ConfigurationName $ConfigurationName -ConfigurationType 'Active')));
    $testVal=($testVal -bor (4*[int]($force.IsPresent)));
    If ((($testVal -band 1) -eq 1) -and (($testVal -band 4) -eq 4))
    {
        try {
            writeLogOutput -LogString ('Removing entry from default config');
            clearCfgEntry -EntryName 'DefaultCfgName';
        } # end try
        catch {
            $msg='Failed to clear the configuration value for the default configuration.';
            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
        }; # end catch
    }; # end if
    return (($testVal -eq 0) -or (($testVal -band 4) -eq 4));
}; # end if
function testSMAUserStats
{
[CmdLetBinding()]            
param([Parameter(
          Mandatory = $true, 
           Position = 0)]
        [string]$SMAHost,
      [Parameter(
          Mandatory = $true, 
           Position = 1)]
        [int]$SMAPort, 
      [Parameter(
          Mandatory = $false,
           Position = 2)]
        [bool]$SMASkipCertCheck,
      [Parameter(
          Mandatory = $true,
           Position = 3)]
        [string]$SMAPIVersion,
      [Parameter(
          Mandatory = $true,
          Position = 4)]
        [PSCredential]$SMACred
     )

     begin {

        $errAP=$ErrorActionPreference;
        if ($Script:SuppressNativeTestError -eq $true)
        {
            $ErrorActionPreference='Stop'; # set errorActionPreference to STOP
        }; # end if
     }; # end begin

     process {

         try {
            $tmpRv=Get-SMAStatistics -type 'user' -cred $SMACred -host $SMAHost -port $SMAPort -version $SMAPIVersion -SkipCertCheck:$SMASkipCertCheck;
            return ($null -ne $tmpRv);
         } # end try
         catch {
            return $false;
         }; # end catch     
     }; # end process

     end {
        $ErrorActionPreference=$errAP;
     }; # end END
}; # end funciton testSMALocalAdmin

function setDefaultCfg
{
[CmdLetBinding()]            
param([Parameter(Mandatory = $true, Position = 0)][string]$ConfigurationName
     )

    try {
        $msg='Failed to load the module configuration.';
        writeLogOutput 'Loading module configuration';
        [hashtable]$Cfg=(Get-SecretInfo -Name $Script:SMAModuleCfgName -Vault $Script:vaultName -ErrorAction Stop).Metadata;        
        $Cfg=(loadMetadata -MetaData (Get-SecretInfo -Name $Script:SMAModuleCfgName -Vault $Script:vaultName -ErrorAction Stop).Metadata);        
        <#$newHashTable=@{};
        foreach ($entry in $cfg.Keys)
        {
            if ($cfg.$entry.gettype().Name.startswith('Int'))
            {
                $newHashTable.Add($entry,([int]$cfg.$entry));
            } # end if
            else {
               $newHashTable.Add($entry,$cfg.$entry); 
            }; # end else
        }; # end forea
        writeLogOutput 'Writing module configuration';
        $newHashTable.DefaultCfgName=$ConfigurationName;
        #>
        $cfg.DefaultCfgName=$ConfigurationName;
        $msg='Failed to save the module configuration';
        #Set-SecretInfo -Name $Script:SMAModuleCfgName -Vault $Script:vaultName -Metadata $newHashTable -ErrorAction Stop;
        Set-SecretInfo -Name $Script:SMAModuleCfgName -Vault $Script:vaultName -Metadata $cfg -ErrorAction Stop;
    } # end try
    catch {
        writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
    }; # end catch    
}; # end funciton setDefaultCfg


function setConfigAsActive
{
[CmdLetBinding()]            
param([Parameter(Mandatory = $true, Position = 0)][string]$ConfigurationName
     )

    $cfgName=($script:cfgNamePrefix + $ConfigurationName);
    try {
        $msg=('Failed to load the SMA secret configuration ' + $ConfigurationName);
        $secretCfg=Get-Secret -Name $cfgName -Vault $script:vaultName -ErrorAction Stop;
        $cfg=(Get-SecretInfo -Name $cfgName -Vault $script:vaultName -ErrorAction Stop).Metadata;
        $msg=('Failed to set the configuration ' + $ConfigurationName + ' active')
        $script:activeCfg.SMACred=$secretCfg;
        $script:activeCfg.SMACfgName=$ConfigurationName;
        $script:activeCfg.SMAPort=[int]$cfg.SMAPort
        $script:activeCfg.SMASkipCertCheck=[bool]$cfg.SMASkipCertCheck;
        $script:activeCfg.SMAHost=$cfg.SMAHost;
        $script:activeCfg.SMAPIVersion=$cfg.SMAPIVersion;
    } # end try
    catch {
        writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
    }; # end catch

}; # end function setConfigAsActive

function getCfgMetadataHash
{
[CmdLetBinding()]            
param([Parameter(Mandatory = $true, Position = 0)][string]$ConfigurationName,
      [Parameter(Mandatory = $true, Position = 1)][string]$CfgRawName
     )
    
    $newHashTable=@{};    
    try {
        $Cfg=(loadMetadata -MetaData (Get-SecretInfo -Name $CfgRawName -Vault $Script:vaultName -ErrorAction Stop).Metadata);        
        
        foreach ($entry in $cfg.Keys)
        {
            if ($cfg.$entry.gettype().Name.startswith('Int'))
            {
                $newHashTable.Add($entry,([int]$cfg.$entry));
            } # end if
            else {
            $newHashTable.Add($entry,$cfg.$entry); 
            }; # end else
        }; # end foreach
        if ($newHashTable.Count -eq 0)
        {
            $newHashTable=@{
                SMAPort=$script:SMADefaultPort; # assign default port
                SMASkipCertCheck=0; # set skip cert check to FALSE
                SMAHost='';
                SMAPIVersion=$script:DefaultAPIVer; # assign default api version
            }; # end hashtable
        };
    } # end try
    catch {
        $msg=('Failed to read the configuraton for ' + $ConfigurationName);
        writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
    }; # end catch
    
    return ,$newHashTable;
}; # end function getCfgMetadataHash
function setConfigAttributes
{
[CmdLetBinding()]            
param([Parameter(Mandatory = $true, Position = 0)][string]$ConfigurationName,
      [Parameter(Mandatory = $true, Position = 1)][hashtable]$CfgItems,
      [Parameter(Mandatory = $true, Position = 2)][System.Collections.ArrayList]$KeyList
     )

    
    try {
        $msg=('Failed to read the configuration for ' + $ConfigurationName);
        $tmpCfg=(getCfgMetadataHash -ConfigurationName $ConfigurationName -CfgRawName ($script:cfgNamePrefix + $ConfigurationName)); 
        if ($tmpCfg.count -eq 0)
        {
            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
            return;
        };    
    } # end try
    catch {
        writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
            return;
    }; # end catch
    if ($CfgItems.ContainsKey('SMACredential'))
    {
        try {
            writeLogOutput -LogString ('Saving credentials to configuration ' + $ConfigurationName);
            Set-Secret -Name ($script:cfgNamePrefix + $ConfigurationName) -Vault $Script:vaultName -Secret $CfgItems.SMACredential -Metadata $tmpCfg -ErrorAction Stop;
        } # end try
        catch {
            $msg=('Failed to save the new credentials for configuration ' + $ConfigurationName);
            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
        }; # end catch
        $keyList.Remove('SMACredential');
    }; # end if

    try {
        $msg=('Failed to read the config for configuration ' + $ConfigurationName);
        
        #$tmpCfg=(getCfgMetadataHash -ConfigurationName $ConfigurationName -CfgRawName ($script:cfgNamePrefix + $ConfigurationName));        
        if ($keyList.count -gt 0)
        {            
            foreach($item in $keyList)
            {                
                $tmpCfg.$item=$CfgItems.$item;
            }; # end foreach
            $msg=('Failed to save the settings for configuration ' + $ConfigurationName);
            Set-SecretInfo -Name ($script:cfgNamePrefix + $ConfigurationName) -Vault $Script:vaultName -Metadata $tmpCfg -ErrorAction Stop;
            
        }; # end if
    } # end try
    catch {
        writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
    }; # end catch
    
    try {                
        if ($script:activeCfg.SMACfgName -eq $ConfigurationName)
        {
            writeLogOutput ('The updated config ' + $ConfigurationName + ' is the active config. Please execute the following command to reflect the change(s) to the current config.') -LogType Warning;
            writeLogOutput -LogString ('Set-SMAConfiguration -ConfigurationName ' + $ConfigurationName + ' -SetActive') -ShowInfo;
        }; # end if
    } # end try
    catch {
        $msg='Failed to read the name of the active configuration';
        writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
    }; # end catch
}; # end function



class getModuleData
{        
    getModuleData () {
             
    } # end getModuleData


    [array]GetConfigList ()
    {        
        $tmpList=@(Get-SecretInfo -Name ($script:cfgNamePrefix+'*') -Vault $script:vaultName);     
        if ($tmpList.Count -eq 0)
        {
            $cfgList=@('no config available');
        } # end if
        else {            
            $cfgList=[System.Collections.ArrayList]::new();
            foreach ($entry in $tmpList.Name)
            {
                [void]$cfgList.Add($entry.Replace($script:cfgNamePrefix,''));
            }; # end if
        }; # end else  
                  
        return $cfgList;        
    } # end method getModuleList

}; # end class getModuleData


function loadMetadata
{
[cmdletbinding()]
param([Parameter(Mandatory = $true, Position = 0)]$MetaData
     )
     $tmpData=@{};
     foreach ($key in $MetaData.keys)
     {
        if (($MetaData.$key.Gettype()).Name -ne 'Int64') # make sure it's not Int64 (seams to occur only in PS Core)
        {
            $tmpData.Add($key,$MetaData.$key -as $MetaData.$key.Gettype());
        } # end if
        else {            
            if ($Script:ShowIntConversionWarning)
            {
                writeLogOutput -LogString 'Datatype Int64 dedected, converting to Int32' -LogType Warning;
            }; # end if
            try {
                $tmpData.Add($key,[int32]$MetaData.$key);
            } # end try
            catch {
                $errMsg='Failed to convert data to Int32';
                writeLogError -ErrorMessage $errMsg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
            }; # end catch             
        }; # end else
     }; # end foreach
     return $tmpData;
}; # end function loadMetadata

function verifyVars
{
[cmdletbinding()]
param([Parameter(Mandatory = $true, Position = 0)][array]$VarList
     )    

    $checkVal=0;
    $controlVal=0;
    $tmpVal=1;
    for ($i=0;$i -lt $VarList.Count;$i++)
    {        
        if (Test-Path -Path variable:$($VarList[$i]))
        {
            switch ((Get-Variable -Name $varlist[$i] -ValueOnly).GetType().Name)
            {
                'String'        {
                    if ([System.String]::IsNullOrEmpty((Get-Variable -name $VarList[$i] -ValueOnly)))
                    {
                        Write-Warning ('The variable ' + $VarList[$i] + ' is not assigned');
                    } # end if
                    else {
                        $checkVal = ($checkVal -bor ($tmpVal));
                    }; # end else
                    break;
                }; # end string
                'Int32'         {
                    if ((Get-Variable -name $VarList[$i] -ValueOnly) -gt 0)
                    {
                        $checkVal = ($checkVal -bor ($tmpVal));
                    } # end if
                    else {
                        Write-Warning ('The variable ' + $VarList[$i] + ' is not assigned');
                    }; # end if
                    break;
                }; # end int32
                {$_ -in @('Boolean','SwitchParameter')}  {
                    $checkVal = ($checkVal -bor ($tmpVal));                    
                    break;
                }; # end int32
                'PSCredential'  {
                    if ([System.Management.Automation.PSCredential]::empty -ne (Get-Variable -name $VarList[$i] -ValueOnly))
                    {
                        $checkVal = ($checkVal -bor ($tmpVal));
                    } # end if
                    else {
                        Write-Warning ('The variable ' + $VarList[$i] + ' is not assigned');
                    }; # end else
                    break;
                }; # end PSCredential
            }; # end switch
                        
        } # end if
        else {
            Write-Warning ('The variable ' + $VarList[$i] + ' is not assigned');
        }; # end if
        
        $controlVal=($controlVal -bor ($tmpVal));
        $tmpVal = ($tmpVal -shl 1);  
    }; # end for
    return ($checkVal -eq $controlVal);
}; # end function 

function initEnumerator
{

try {
Add-Type -TypeDefinition @'

public enum SMAPIVer {
    v1
}
'@
}
catch {
    # type exist
}; # end catch

}; # end initEnumerator

# SIG # Begin signature block
# MIIVzAYJKoZIhvcNAQcCoIIVvTCCFbkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCRWF2mAailMX6k
# x+KjIAqJeSH9exeJ3tnXXZHdvoBp+aCCEggwggVvMIIEV6ADAgECAhBI/JO0YFWU
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
# BgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCCg51fH4VmaQqOEuoz/OuPEXoc3
# 1lwAEBdVpwKAX22xhjANBgkqhkiG9w0BAQEFAASCAgAz6ikcnNxqpl127AzMPXLI
# B0hOeSIe85Nx+VTK+pxpap0CfPNWRoLPnuQrhfr4anu3tnkAFipcpxKtGOlzt7v8
# h7LYAn39N7LZYO/PekhTY4rhACHn0MCmtb6Nt57Tw213KmhpVmPAeR1pO2At6cOG
# RSkXz3xz7FBUIUgs/8G7x3z7Wy/SP9KvD98Yx0YvrxaKD335DmqCtamR+kLmWjIy
# yPzUsIh1PYQrP79VKVXwopxyfkjOfIaevRQoSWiZLVjJRBdjyzkXuHDIC6xilWv+
# 0L+vY0sCet+cBlngoIveergglPArWg3emQy+ropiwHFVVLfWdJXt4iwGgTNCiO+L
# sYUfIkPCpW5fIP6S/oTBJAHSd9a+Fxd25RlyfIlRThG0n56CPbEMN77phvCziwsn
# O9soirWhBL80zMXPK2A9BsvH3ORoWqoNo30lfYX4DAaQ1//yohK3lxO16da9smJL
# JcO4HqvhBROC5o4UeP0K5PH7MKjxXc4O7O3fXIjVtzqlgeQvhpXLBQ+4UpZR2FtP
# n3ji3kM7SPziQktrXNTKzFqpJ52DbhGNanCQzOe5DGok1AtRthsBhL2JauVF2m44
# DhC9uoywHddf9LEojzv7jIeJwnIAkKlxxt8qynYEjBn2moZfrY4NJP402rMdPP0t
# EQHWSuURRw6K1OsH1zIbbA==
# SIG # End signature block
