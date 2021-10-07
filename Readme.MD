# SEPPmail API Powershell Module

Receive data and manage your SEPPmail Appliance via REST!

Beginning with SEPPmail Version 12.1.0, the Appliance offers a REST-API to manage SEPPmail remotely.
This PowerShell module is a wrapper around this API to allow more convenient operation and interaction from the command line.

## Prerequisites

The module requires minimum SEPPmail version 12.1.0 and minimum Powershell 5.1 on Windows

PowerShell 7 on Windows, Linux or macOS may work, are currently not supported, but support is in planning.

* On the SEPPmail Appliance, you need to have REST-API Access configured.
* Go to System ==> Advanced view ==> REST-API.
* Select a Port (Default 8445) and create a RESTAPI key.
* Preferrably we recommend to create a GUID (in Portshell "(New-Guid).Guid") or something even more complex and remember this key for authentication.

## Installation and Setup Info

### PowerShell Gallery (preferred option)

We have published the module on the <https://www.PowerShellGallery.com>. You can install the module by running:

```powershell
Install-module SEPPmailAPI
```

To install it in the all users scope (you must run PS with admin Rights)use:

```powershell
Install-module SEPPmailAPI -Scope AllUser
```

### Github

If you have no access to the PowerShell Gallery but git installed, clone the module into a folder which is listed in the $env:PSmodulePath, preferably your home-PSmodule folder ~\Documents\PowerShell\Modules.

Set your location to this folder and enter:
`git clone https://github.com/SEPPmail/SeppmailAPI`

If you do not have git installed, download the files from the repository, unblock the zip file (PS CmdLet `Unblock-File`) and place it in the modules folder.

IMPORTANT: Its imperative that the Module is installed in a folder which is included in the $env:PSModulePath, otherwise the module will not work.

## Loading the module and preparing for first use

Be sure the module is accessible with

```powershell
Get-Module SEPPmailAPI -Listavailable
```

and load it into memory with

```powershell
Import-Module SEPPmailAPI
```

Immediately after loading the module you will be ask for a configuration for your SEPPmail.


Usage examples can be found in the module example folder "\examples".

## Finding Help

Use the PowerShell help system to get examples and parameter help for each CmdLet as the example below.

```powershell
Get-Help Find-SMAUser
Get-Help Get-SMAUser
```

--- This is the end of the file ---