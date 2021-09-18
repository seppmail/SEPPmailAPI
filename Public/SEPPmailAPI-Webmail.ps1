<#
.SYNOPSIS
    Retrieve information about webmail users
.DESCRIPTION
    This CmdLet lets you recieve detailed properties of existing GINA (webmail) users. You can filter the query based on GINA-user properties, see the examples for more)
.EXAMPLE
    PS C:\> Get-SMAGinaUser 
#>
function Get-SMAGinaUser {

}

Write-Verbose 'Create CmdLet Alias for GINA users' 
$custVerbs = ('Add','Remove','Get','Find','Set')

Foreach ($custverb in $custVerbs) {
    $aliasname1 = $custverb + '-SMAGU'
    $cmdName = $custverb + '-SMAGinaUser'
    New-Alias -Name $aliasName1 -Value $cmdName
}


