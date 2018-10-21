function Get-CiscoIPDeviceName {
    # Requires -Module PSRemoteRegistry

<#
    .SYNOPSIS
        Get device name data information for Cisco IP Communicator from a remote computer.    
    
    .DESCRIPTION
        This command get the logged username in the targeted machine, then translates it to it's SIP key
        After getting the SIP key, it searches in users registry for the required data.
    
    .PARAMETER ComputerName
        Specifies the target computer name.
    
    .EXAMPLE
        Get-CiscoIPDeviceName -ComputerName Host01
        This command will return the DeviceName data information inside Cisco IP Communicator software
        from targeted machine.                                       
    
    .NOTES
        This function requires the PSRemoteRegistry module, which is available in PSGallery repository.
        To install PSRemoteRegistry use:
         
        Install-Module PSRemoteRegistry (don't forget to import it after using Import-Module PSRemoteRegistry).

#>
    [Cmdletbinding()]
    param(
        [Parameter(Mandatory)]        
        $ComputerName
    )        
    
    Try{        
    
        if(Test-Connection -ComputerName $ComputerName -Quiet -Count 1) {           
    
            $name = gwmi -class Win32_ComputerSystem -ComputerName $ComputerName | select username
            $namesplit = $name.username.split('\')
            $domainname = $namesplit[0]
            $Username = $namesplit[1]
            $objUser = New-Object System.Security.Principal.NTAccount("$domainname","$username")
            $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
            $SID = $strSID.Value
            $Key = "$SID\Software\Cisco Systems, Inc.\Communicator"
            $reg = $ComputerName | Get-RegString -Hive Users -Key $Key -Value HostName
            $reg | 
            select @{
                name="DeviceName" ; expression = {$_.Data}
            }
    
        }    
     
        else{
            Write-Host "`nHost $ComputerName is not reachable!" -ForegroundColor Yellow 
        }
    }    
    
    catch {
        Write-Error "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
    }
}