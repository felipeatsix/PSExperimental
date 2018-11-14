function Get-Logs {
<#
    .SYNOPSIS
        This Powershell function gets every log file in a local or a remote computer
    
    .DESCRIPTION
        This tool uses two different approaches to get logs in the machine.
        First it'll query the internal system event log, then it searches for .log files in the fylesystem. 
    
    .PARAMETER ComputerName
        Set the target computer name to run it remotely. 
    
    .PARAMETER StartDate
        Set the initial time stamp
    
    .PARAMETER EndDate
        Set the final time stamp
    
    .PARAMETER ProviderName
        Filter the query by provider using a provider name
    
    .PARAMETER LogFileExtension
        Set the extension of the log files to look for (it doesn't need to specify '.' uses just the name of the extension)        
    
    .EXAMPLE
       Get-Logs -ComputerName LT9437 -StartDate 11/05/2018 10:00 -EndDate 11/05/2018 15:00 -ProviderName Microsoft
       This command will get log files in LT9437 within a time stamp from 11/05/2018 10:00AM to 11/05/2018 3:00PM.
       And the files will be filtered by provider which here is set to look for just for Microsoft's provider. 
#>    
    [cmdletbinding()]
    param(        
        [ValidateScript({Test-Connection -ComputerName $_ -Quiet -Count 1})]        
        [string]$ComputerName = 'localhost',
        [Parameter(Mandatory)]
        [datetime]$StartDate,
        [Parameter(Mandatory)]
        [datetime]$EndDate,
        [string]$ProviderName = '*',                  
        [string]$LogFileExtension = 'log'
    )            
    
    # Event Log Query 

    Write-Verbose "$($ComputerName.ToUpper()): Querying EVENT LOG..." 
                
    $Logs = (Get-WinEvent -ListLog * -ComputerName $ComputerName | where {$_.RecordCount}).LogName
    
    $FilterTable = @{
        'StartTime' = $StartDate
        'EndTime' = $EndDate
        'LogName' = $Logs
        'ProviderName' = $ProviderName        
    }
    
    Get-WinEvent -ComputerName $ComputerName -FilterHashtable $FilterTable -ErrorAction SilentlyContinue

    # File System Query 

    Write-Verbose "$($ComputerName.ToUpper()): Querying FILESYSTEM..." 
    Start-Sleep 3
    
        if ($ComputerName -eq 'localhost') {
            $Locations = (Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3").DeviceID
        }

        else {
            $Shares = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Share | where { $_.Path -match '^\w{1}:\\$' }
            [System.Collections.ArrayList]::$Locations = @()
            
            foreach($Share in $Shares) {
                $Share = "\\$ComputerName\$($Share.Name)"
                
                    if (!(Test-Path $Shares)) {
                        Write-Warning "Unable to access the '$Shares' share on '$ComputerName'"
                    }
            
                    else {
                        $Locations.Add($Share) | Out-Null
                    }
            }
        }
    
    $GciParams = @{
        Path = $locations               
        Filter = "*.$LogsFileExtension"
        Recurse = $true
        Force = $True
        ErrorAction = 'Ignore'
        File = $True
    }
        $WhereFilter = {($_.LastWriteTime -ge $StartDate) -and ($_.LastWriteTime -le $EndDate) -and ($_.Length -ne 0)}        
        Get-ChildItem @GciParams | Where-Object $WhereFilter | ft                              
}