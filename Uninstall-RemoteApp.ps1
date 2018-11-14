Function Uninstall-RemoteApp {    
# Requires -Function Find-Software

<#
    .SYNOPSIS
        Uninstalls a software in a remote destination.
    
    .DESCRIPTION
        Use this Powershell function to remote uninstall software.
    
    .PARAMETER ComputerName
        Set the computer target name.
    
    .PARAMETER Software.
        Set the name of the software to be uninstalled in the target.
    
    .Example
        Uninstall-RemoteApp -ComputerName Host01 -Software '*Adwords*'
        This command will uninstall any software that contains the word 'Adwords' on it. 
#>    
    
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact ='High')]
    param(
        [Parameter(Mandatory)]
        $ComputerName,
        [Parameter(Mandatory)]
        $Software
    )
    
    $VerbosePreference = 'Continue'    
    $Software = Find-Software -DisplayName $Software -ComputerName $ComputerName 
    [array]$ID = $Software.RegistryKey | Split-Path -Leaf                    
    $ErrorActionPreference = 'SilentlyContinue'   
    $Array = 0                                     
        
        foreach($Item in $Software){                      
            
            #Build classkey
            $IdentifyingNumber = "IdentifyingNumber=`"$($ID[$Array])`","
            $Name = "Name=`"$($item.DisplayName)`","
            $Version = "Version=`"$($item.DisplayVersion)`""
            $classKey = "$IdentifyingNumber$Name$Version"                                                      
    
            #Try to query the software making use of the type accelerator [wmi]
            $WMI = ([wmi]"\\$ComputerName\root\cimv2:Win32_Product.$classKey")                                                                            
                
            if($WMI) {                               
                $WMI
            
                if($PSCmdlet.ShouldProcess($ComputerName)) {
                   
                    Write-Verbose "Uninstalling $($Item.DisplayName) in $ComputerName..." 
                    $Uninstall = ([wmi]"\\$ComputerName\root\cimv2:Win32_Product.$classKey").Uninstall()
                                    
                    if($Uninstall.ReturnValue -eq 0) {
                        $SuccessLog = Write-Output "$($Item.DisplayName) has been uninstalled in $ComputerName"
                        $SuccessLog >> c:\logs\Log.txt
                    }
                                    
                    else{
                        Write-Verbose "Uninstallation has returned the code: $($Uninstall.ReturnValue)" 
                    }
                }
                
                else {
                    Write-Verbose "Operation has been cancelled"                                            
                }
            }                                        
                $Array++
        }
    }
