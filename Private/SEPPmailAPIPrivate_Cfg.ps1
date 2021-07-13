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
            Register-SecretVault -ModuleName $script:SecureVaultModuleName -Name $Script:vaultName -Description 'Cereated by SMA PS module';
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
            $tmp=Test-NetConnection -ComputerName $ComputerName -Port $Port;
            return ($tmp.TcpTestSucceeded);
        }
        catch {
            writeLogError -ErrorMessage $msg -PSErrMessage ($_.Exception.Message) -PSErrStack $_;
            return $false;
        }; # end catch
        <#$TcpClient = New-Object System.Net.Sockets.TcpClient
        $Connect = $TcpClient.BeginConnect($ComputerName, $Port, $null, $null)
        $Wait = $Connect.AsyncWaitHandle.WaitOne($TcpTimeout, $false)
        if (!$Wait) 
        {
	        writeLogOutput -LogString ('Server ' + $computerName + ' failed to answer on port ' + $Port.ToString()) -LogType Warning;
            return $false;
        } # end if
        else 
        {	        
	        return $true;
        }; # end else    
        #>    
    } # end process

    end {        
        #$TcpClient.Close();
        #$TcpClient.Dispose();
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
function testSMALocalAdmin
{
[CmdLetBinding()]            
param([Parameter(Mandatory = $true, Position = 0)][string]$SMAHost,
      [Parameter(Mandatory = $true, Position = 1)][int]$SMAPort, 
      [Parameter(Mandatory = $false, Position = 2)][bool]$SMASkipCertCheck,
      [Parameter(Mandatory = $true, Position = 3)][string]$SMAPIVersion,
      [Parameter(Mandatory = $true, Position = 4)][PSCredential]$SMACred
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
            $tmpRv=Get-SMAUser -email 'admin@local' -cred $SMACred -host $SMAHost -port $SMAPort -version $SMAPIVersion -SkipCertCheck:$SMASkipCertCheck;
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
        writeLogOutput 'Writing module configuration';
        $newHashTable.DefaultCfgName=$ConfigurationName;
        $msg='Failed to save the module configuration';
        Set-SecretInfo -Name $Script:SMAModuleCfgName -Vault $Script:vaultName -Metadata $newHashTable -ErrorAction Stop;
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
