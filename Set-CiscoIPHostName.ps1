function Set-CiscoIPHostName {
    # Requires -Module PSRemoteRegistry

<#
    .SYNOPSIS
        Set the registry data needed to successfully register a Cisco IP Communicator software in a remote computer.    
    
    .DESCRIPTION
        Use this script before registering the client hostname in CUCM, this will create the necessary data into the computer to be successfully registered.
    
    .PARAMETER ComputerName
        Specifies the target computer name.
    
    .EXAMPLE
        Set-CiscoIPHostName -ComputerName Host01
        This command will create the necessary data into the targeted machine
        to accomplish it's registration in CUCM. 
    
    .NOTES
        This function requires the PSRemoteRegistry module, which is available in PSGallery repository.
        To install PSRemoteRegistry use:
         
        Install-Module PSRemoteRegistry
        Import-Module PSRemoteRegistry

#>
    [Cmdletbinding()]
    param(
        [Parameter(Mandatory)]        
        $ComputerName
    )        
    
    Try {        
    
        if (Test-Connection -ComputerName $ComputerName -Quiet -Count 1) {           
    
            # Get domain name and current logged user and stores it into two different variables.
            
            $name = gwmi -class Win32_ComputerSystem -ComputerName $ComputerName | select username
            $namesplit = $name.username.split('\')
            $domainname = $namesplit[0]
            $Username = $namesplit[1]
            
            # Create a NTAccount object to make use of it's translate method.
            # This will translate the username to it's SID. 
            # Then stores the SID in a new variable. 
            
            $objUser = New-Object System.Security.Principal.NTAccount("$domainname","$username")
            $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
            $SID = $strSID.Value
            
            # Declare the registry path to go inside the user's SID.
            # Test if the key already exists, create the Hostname string value for both true or false result.
                        
            $RootKey = "$SID\Software"
            $NewKey = "Cisco Systems, Inc.\Communicator"    
            
                if (!(Test-RegKey $RootKey\$NewKey)) {
                
                    $ComputerName | New-RegKey -Hive Users -Key $RootKey -Name $NewKey
                    $ComputerName | Set-RegString -Hive Users -Key "$RootKey\$NewKey" -Value Hostname -Data "$(hostname)" -Force
                }
    
                else {

                    $ComputerName | Set-RegString -Hive Users -Key "$RootKey\$NewKey" -Value Hostname -Data "$(hostname)" -Force
                }
        }
                 
        else{
            Write-Warning "Computer $ComputerName is not reachable!"
        }
    }    
    
    catch { Write-Error "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" }
}
