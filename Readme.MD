# SEPPmail API Powershell Module

*** BREAKING CHANGE Okt 25 ***

The module development will continue internally, so the code will no lomger show up in GutHub. 
We will furthermore mode the documentation to docs.seppmail.com soon.

There will be a new release of the module 2.0.0 covering API Version 1.0.8+ end of 2025.

*** ---------------------- ***

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

## Examples and Hints

This an be found in the module help and CmdLet help by using get-help

### Configuration creation

This can be found in the youtube video
## Finding Help

Use the PowerShell help system to get examples and parameter help for each CmdLet as the example below.

```powershell
Get-Help Find-SMAUser
Get-Help Get-SMAUser
```

--- This is the end of the file ---