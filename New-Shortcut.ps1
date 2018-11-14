function New-Shortcut {
<#
    .SYNOPSIS
        Create a new shortcut with a custom icon in a local or a remote computer
    
    .DESCRIPTION
        Use this script to create a new shortcut everywhere in your local or in a remote computer.
        The target path can be either a file or a web address. 
    
    .PARAMETER Source
        Set the source path which the shortcut will redirect to.
    
    .PARAMETER Destination
        Set the location where the shortcut will be saved.
    
    .PARAMETER Icon
        Set the Icon for the shortcut file. 
        This can be a path for an .ico or an .exe file

    .EXAMPLE
        New-Shortcut -Source Https://admin.wayfair.com -Destination \\LT9437\c$\users\fdesouzasantos\desktop -Icon '\\LT9437\c$\Program Files (x86)\Google\Chrome\Application.exe'
        This command will create a shortcut in LT9437 located in fdesouzasantos user's desktop with google chrome application icon. 

#>       
    [CmdletBinding()]
    param(                
        [parameter(Mandatory=$true)]   
        $Source,
        [parameter(Mandatory=$true)]
        $Destination,   
        [parameter(Mandatory=$true)]
        $Icon
    )   
  
  $WshShell = New-Object -ComObject WScript.shell   
  $shortcut = $WshShell.CreateShortcut($Destination)
  $shortcut.TargetPath = $Source   
  $shortcut.iconlocation = $Icon
  $Shortcut.Save() 

}