function Clear-OldCacheData {

<#
    .SYNOPSIS
        Wipe old and unnecessary data files remotely.

    .DESCRIPTION
        Use this Powershell function to do an unattended data cleaning in a remote computer and get the cleaning result.
        This can possibly help issues with slow startups or system usage. 
    
    .PARAMETER ComputerName
        Set the target computer name.
    
    .PARAMETER DaysToDelete
        Set the cached file data age to be deleted.
    
    .EXAMPLE
        Clear-Disk -ComputerName LT9437 -DaysToDelete 10
        This command will wipe all cached data within 10 days old in the targeted computer LT9437.
#>    

    param(
        [Parameter(Mandatory)]
        $ComputerName,
        [Parameter(Mandatory)]
        [int]$DaysToDelete
    )
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock {        
               
        $VerbosePreference = "Continue"        
        $LogDate = get-date -format "dd-MM-yyyy-HH-mm"
        $objShell = New-Object -ComObject Shell.Application 
        $objFolder = $objShell.Namespace(0xA)
        $ErrorActionPreference = "SilentlyContinue"                   
        cls
       
        $Before = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object `
        @{ Name = "Computer Name" ; Expression = {(hostname)}},
        @{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } },
        @{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}},
        @{ Name = "Free Space (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } },
        @{ Name = "Free Space Percentage" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } } |
   
        Format-Table -AutoSize | Out-String                                                     

        Get-Service -Name wuauserv | Stop-Service -Force -Verbose -ErrorAction SilentlyContinue       

        Get-ChildItem "C:\Windows\SoftwareDistribution\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue |
        Where-Object {($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete))} |
        remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue       

        Get-ChildItem "C:\Windows\Temp\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue |
        Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete)) } |
        remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
                 

        Get-ChildItem "C:\users\*\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { ($_.CreationTime -lt $(Get-Date).AddDays(-$DaysToDelete))} |
        remove-item -force -Verbose -recurse -ErrorAction SilentlyContinue
                                

        Get-ChildItem "C:\users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -Recurse -Force -Verbose -ErrorAction SilentlyContinue |
        Where-Object {($_.CreationTime -le $(Get-Date).AddDays(-$DaysToDelete))} |
        remove-item -force -recurse -ErrorAction SilentlyContinue                            

        Get-ChildItem "C:\inetpub\logs\LogFiles\*" -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { ($_.CreationTime -le $(Get-Date).AddDays(-60)) } |
        Remove-Item -Force -Verbose -Recurse -ErrorAction SilentlyContinue
                      
        $objFolder.items() | ForEach-Object { Remove-Item $_.path -ErrorAction Ignore -Force -Verbose -Recurse }        

        Get-Service -Name wuauserv | Start-Service -Verbose

        $After =  Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" } | Select-Object `
        @{ Name = "Computer Name" ; Expression = {(hostname)}},
        @{ Name = "Drive" ; Expression = { ( $_.DeviceID ) } },
        @{ Name = "Size (GB)" ; Expression = {"{0:N1}" -f( $_.Size / 1gb)}},
        @{ Name = "Free Space (GB)" ; Expression = {"{0:N1}" -f( $_.Freespace / 1gb ) } },
        @{ Name = "Free Space Percentage" ; Expression = {"{0:P1}" -f( $_.FreeSpace / $_.Size ) } } |
       
        Format-Table -AutoSize | Out-String        

        Write-Verbose "Before: `n$Before"
        Write-Verbose "After: `n$After" 
        Write-Verbose "$data"
    }
}
