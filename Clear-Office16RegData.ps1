function Clear-Office16RegData {
<#
    .SYNOPSIS
        Wipe Office 16 registry data in a remote computer.
        The command always clean the data for the current logged user in the remote machine.
    
    .DESCRIPTION
        This script will wipe office 16 data located in Software\Microsoft\Office\16.0\Common User registry HIVE.
    
    .PARAMETER ComputerName
        Set the target computer name. 
    
    .EXAMPLE
        Clear-Office16RegData -ComputerName [hostname]
        This command will clean Office 16 registry data in [hostname] for current logged user. 
#>
    param(
        [Parameter(Mandatory)]
        $ComputerName
    )
    
    if (Test-Connection -ComputerName $ComputerName -Quiet -Count 1) {           
            
        $name = gwmi -class Win32_ComputerSystem -ComputerName $ComputerName | select username
        
        $namesplit = $name.username.split('\')
        $domainname = $namesplit[0]
        $Username = $namesplit[1]
        
        $objUser = New-Object System.Security.Principal.NTAccount("$domainname","$username")
        $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
        
        $SID = $strSID.Value        
        $Key = "$SID\Software\Microsoft\Office\16.0\Common"
        
        Remove-RegKey -Hive Users -Key $Key\Identity -Recurse -force -Verbose
        Set-RegDWord -Hive Users -Key $Key\Internet -Value UseOnlineContent -Data 1 -Force -Verbose
    }
}
