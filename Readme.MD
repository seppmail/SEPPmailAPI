# SEPPmail API Powershell Module

Receive data and manage your SEPPmail Appliance via REST!

Beginning with SEPPmail Version 12.1.0, the Appliance offers a REST-API to manage SEPPmail remotely.
This PowerShell module is a wrapper around this API to allow more convenient operation and interaction from the command line.

## Prerequisites

The module requires minimum SEPPmail version 12.1.0 and minimum Powershell 5.1 on Windows. 
We recommend using PowerShell Core on Windows

PowerShell 7 on Linux or macOS may work as well, we are currently focussing on the windows platform, but support is in planning.

* On the SEPPmail Appliance, you need to have REST-API Access configured.
* Go to System ==> Advanced view ==> REST-API.
* Select a Port (Default 8445) and create a RESTAPI key, secret and select proper access.
* For high security, use the "Generate" Button in the appliance

## Installation and Setup from the PowerShellGallery

Follow the youtube video here: [Link](https://www.youtube.com/watch?v=RHaZW7txxBg).

Example file showed in youtube can be found here:
* Installation and Setup [Github](https://github.com/seppmail/SEPPmailAPI/blob/main/examples/Installation%20and%20Setup.ps1)
* First Steps [Github](https://github.com/seppmail/SEPPmailAPI/blob/main/examples/First%20Steps.ps1)

### Installation from Github

If you have no access to the PowerShell Gallery but git installed, clone the module into a folder which is listed in the $env:PSmodulePath, preferably your home-PSmodule folder ~\Documents\PowerShell\Modules.

Set your location to this folder and enter:
```powershell
git clone https://github.com/SEPPmail/SeppmailAPI
```

If you do not have git installed, download the files from the repository, unblock the zip file (PS CmdLet `Unblock-File`) and place it in the modules folder.

IMPORTANT: Its *imperative that the Module is installed in a folder which is included in the $env:PSModulePath*, otherwise the module will not work.

### Configuration creation

This can be found in the youtube video
## Finding Help

Use the PowerShell help system to get examples and parameter help for each CmdLet as the example below.

```powershell
Get-Help Find-SMAUser
Get-Help Get-SMAUser
```

--- This is the end of the file ---