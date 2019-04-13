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
        [ValidateScript({Test-Connection $_ -Quiet -Count 1})]                
        [string]$ComputerName = 'localhost',
        [Parameter(Mandatory, HelpMessage="Specify RAM check interval in seconds)]
        [int]$Interval,
        [Parameter(Mandatory)]
        [int]$Count
    )
    
    try{
    
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {                        
            
            for ($loop = 1 ; $loop -le $Using:Count ; $loop++) {
                
                $date = get-date -Format "dd/MM/yyyy - HH:mm:ss" 
                Write-Output "`nCheck: $loop - Time: $date"

                # Calculate the free RAM percentage
                # Then set the variables Status and Color depending in it's result.
                
                $Ram = Get-WmiObject -class Win32_OperatingSystem
                $RamFreePercentage = [math]::Round(($ram.FreePhysicalMemory / $ram.TotalVisibleMemorySize) * 100)            
                                                     
                if ($RamFreePercentage -gt 45) {
                                                $Status = "OK"
                                                $Color = 'Green' 
                } 
                
                elseif ($RamFreePercentage -ge 25) {
                                                    $Status = "Warning"
                                                    $Color = 'Yellow'
                }
                
                elseif ($RamFreePercentage -lt 25) {
                                                    $Status = "Critical"
                                                    $Color ='Red'
                }
                
                # Get the Total RAM and total free ram
                # Then calculate it to be displayed in giga bytes.
                
                [int]$TotalRamGB = $Ram.TotalVisibleMemorySize / 1mb
                [float]$FreeRamGB = [math]::Round($ram.FreePhysicalMemory / 1mb,2)                            

                # Output custom object
                
                $Ram | Select-Object `
                @{ Name = 'Computer' ; Expression = {(hostname)}},
                @{ Name = 'Total Ram(GB)' ; Expression = {$TotalRamGB}},
                @{ Name = 'Free Ram(GB)' ; Expression = {$FreeRamGB}},
                @{ Name = 'Free Ram (%)' ; Expression = {"$($RamFreePercentage)%"}},
                @{ Name = 'Status' ; Expression = {$Status}} |                                
                Format-Table -AutoSize -Wrap | Out-String | Write-Host -ForegroundColor $Color
               
                Start-Sleep $Using:Interval
            }
        }                
    } 
        catch { Write-Error "$($_.Exception.Message) -Line Number $($_.InvocationInfo.ScriptLineNumber)" }    
}
