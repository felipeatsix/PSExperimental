#requires -module PSEmoji
function Read-RamUsage { 
    <#
    .SYNOPSIS
        Monitor live RAM usage in local or remote computer through Powershell. 

    .DESCRIPTION
        Use this function to monitor RAM usage of a server or an endpoint.
        This can be used to evaluate when a user asks for upgrading RAM.
        Use Ctrl + C to stop it.

    .PARAMETER ComputerName
        Set the target computer name.

    .PARAMETER Interval
        Set RAM usage check interval.

    .PARAMETER Count
        Set the number of RAM checks to do.

    .Example
        Read-RamUsage -ComputerName Host01 -Interval 30 -Count 10
        This command will start monitoring Host01 RAM usage
        and will check it 10 times every 30 seconds
        Use Ctrl + C to stop it.
    #>            
    param(
        [Parameter(Mandatory = $false)]
        [ValidateScript( {Test-Connection $_ -Quiet -Count 1 })]
        [string]$ComputerName = 'localhost',

        [Parameter(Mandatory, HelpMessage = "Specify RAM check interval in seconds")]
        [int]$Interval,

        [Parameter(Mandatory = $true)]
        [int]$Count,

        [Parameter(Mandatory = $false)]
        [pscredential]$Credential
    )
    BEGIN {                       
        $invokeCommand = @{
            ComputerName = $ComputerName            
        }
        if ($Credential) {
            $invokeCommand.Credential = $Credential
        }        
    }    
    PROCESS {
        try {    
            Invoke-Command @invokeCommand -scriptblock {
                import-module PSEmoji
                $output = [pscustomobject]@{
                    'Computer'      = $ENV:COMPUTERNAME
                    'Total Ram(GB)' = $null
                    'Free Ram(GB)'  = $null
                    'Free Ram(%)'   = $null
                    'Status'        = $null
                }
                for ($loop = 1 ; $loop -le $Using:Count ; $loop++) {
                    $date = get-date -Format "dd/MM/yyyy - HH:mm:ss" 
                    Write-Output "Time: $date"
                    # Calculate the free RAM percentage
                    # Then set the variables Status and Color depending in it's result.                
                    $Ram = Get-WmiObject -class Win32_OperatingSystem
                    $RamFreePercentage = [math]::Round(($ram.FreePhysicalMemory / $ram.TotalVisibleMemorySize) * 100)                                                                
                    if ($RamFreePercentage -gt 45) {
                        $Status = $PSEMOJI.Emojis.tests.passed_boxed
                    }             
                    elseif ($RamFreePercentage -ge 25) {
                        $Status = $PSEMOJI.Emojis.face.freezing
                    }            
                    elseif ($RamFreePercentage -lt 25) {
                        $Status = $PSEMOJI.Emojis.tests.bomb
                    }            
                    # Get the Total RAM and total free ram
                    # Then calculate it to be displayed in giga bytes.                
                    [int]$TotalRamGB = $Ram.TotalVisibleMemorySize / 1mb
                    [float]$FreeRamGB = [math]::Round($ram.FreePhysicalMemory / 1mb, 2)                                           
                    $output.'Total Ram(GB)' = $TotalRamGB
                    $output.'Free Ram(GB)'  = $FreeRamGB
                    $output.'Free Ram(%)'   = $RamFreePercentage
                    $output.'Status'        = $Status
                    Start-Sleep $using:Interval
                    $output | Out-String
                }
            }
        } 
        catch { Write-Error "$($_.Exception.Message) -Line Number $($_.InvocationInfo.ScriptLineNumber)" }    
        }    
    END {}
}