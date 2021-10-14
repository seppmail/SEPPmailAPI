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
            writeLogOutput -LogString 'Setting authentication for secret store to NONE! - This is not the most secure setup, to change use Set-SecretStoreConfiguration' -LogType Warning;
            Set-SecretStoreConfiguration -Authentication None -Confirm:$false;
            Register-SecretVault -ModuleName $script:SecureVaultModuleName -Name $Script:vaultName -Description 'Created by SMA PS module';            
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
# MIIL1wYJKoZIhvcNAQcCoIILyDCCC8QCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbF9V8ZtNxuBzPbGu81qOOTyo
# MVyggglAMIIEmTCCA4GgAwIBAgIQcaC3NpXdsa/COyuaGO5UyzANBgkqhkiG9w0B
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
# MRYEFKWU8nYiQbPmGiGX3dx5Q8Zs3+GKMA0GCSqGSIb3DQEBAQUABIIBACH+50Wv
# Za4tlqD95i/jdK14Ksg6T3J5TeC24VoEwxYAjOXXDnPrNLY16YnLSIPzB5xxhNwa
# 7k9VGnUqkzEgsV3I1VUn/XX1b/WIg+d0Ee2LSsfeIIJyxXbtzBQDQn1xOxgUWZ3W
# 9IA538vS9ERc6zv3m+PKQE4+VsGs3igSdRrhonGpVL0YS6p6Kt+n9HWbXyC5Se86
# VhPgglX81f6wndw68Jjq2cNBEL17B/DSCytsbj2kazYO7ww4k7ThAN89numMP5Jl
# a2ChAzV6lYseA/VaGCnpBqxnwnyVpdVUZgfEuCNBGOCeIoioZuOP44egukACfNaM
# wo4IfDadnr5tNSA=
# SIG # End signature block
