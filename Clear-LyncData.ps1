function Clear-LyncData {    
<#
    .SYNOPSIS
        Wipe Skype For Business (Lync) cached data for a specific user in a remote computer.
    
    .DESCRIPTION
        This script will clean all user cached data related to Skype For Business in c:\users\user\AppData path. 

    .PARAMETER ComputerName
        Set the computer name target to run it remotely.
        
    .PARAMETER  UserName        
        Set the user name folder to have the Skype For Business data wiped. 

    .EXAMPLE
        Clear-LyncData -ComputerName 9437 -UserName fdesouzasantos
        This command will clean all Skype For Business data for the user fdesouzasantos in LT9437 computer.        
#>
    [Cmdletbinding()]
    param(
        $ComputerName = 'localhost',        
        [Parameter(Mandatory)]        
        $UserName
    )

    $SipPath = "C:\Users\$username\AppData\Local\Microsoft\Office\16.0\Lync"    
    $TracingPath = "C:\Users\$username\AppData\Local\Microsoft\Office\16.0\Lync\Tracing"        
                        
        if(Get-Process -Name lync -ErrorAction SilentlyContinue){
            Stop-Process -Name lync -Force
            write-Verbose -Message "Wiping Skype for Business cache files"
            Start-Sleep 1
        }                   
    
        if (test-path $SipPath) {
            
            $SipFolder = Get-ChildItem $SipPath -Filter "*sip_*"
            remove-item -Path $($SipFolder.FullName) -Recurse -Force 
        }

        if (test-path $TracingPath) {
            
            $TracingFiles = Get-ChildItem $TracingPath -File
            Remove-Item $($TracingFiles.FullName) -Force -ErrorAction SilentlyContinue
        }   
                  
        Write-Verbose -Message "Skype for business cache files have been wiped" 
}
