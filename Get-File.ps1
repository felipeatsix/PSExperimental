function Get-File {
<#
    .SYNOPSIS
        Search for files in local or remote computer.
    
    .DESCRIPTION
        This Powershell function will find files using specifc criteria. 
    
    .PARAMETER ComputerName
        Set the target computer name.
    
    .PARAMETER Criteria
        Set the criteria to be used for searching the file.
    
    .PARAMETER Value
        Set the name of the search value.
    
    .EXAMPLE
        Get-File -ComputerName Host01 -Criteria Extension -Value exe
        This command will get every file with .exe extension.

    .EXAMPLE
        Get-File -ComputerName Host02 -Criteria Age -Value 10
        This commando will get every file within 10 days old.
        
    .EXAMPLE
        Get-File -ComputerName Host03 -Criteria Name -Value MyFile
        This command will get a file named MyFile.        
#>    
    param(
        [string[]]$ComputerName = 'LocalHost',
        [ValidateSet('Extension','Age','Name')]
        [string]$Criteria,                
        [string]$Value                
      )
                
    foreach($Computer in $ComputerName) {
        $CimInstParams = @{'ClassName' = 'Win32_Share'}
        if($Computer -ne 'LocalHost') {
            $CimInstParams.ComputerName = $Computer
        }
        $DriveShares = (Get-CimInstance @CimInstParams | ? {$_.Name -match '^[A-Z]\$$'}).Name
        foreach($Drive in $DriveShares) {
            switch ($Criteria) {
                'Extension' {                    
                    Get-ChildItem -path "\\$Computer\$Drive" -Filter "*.$($Value)" -Recurse
                }
                'Age' {                    
                    $Today = Get-Date
                    $DaysOld = $Value
                    Get-ChildItem -Path "\\$Computer\$Drive" -Recurse | ? {$_.LastWriteTime -le $Today.AddDays(-$DaysOld)}
                }
                'Name' {                    
                    $Name = $Value
                    Get-ChildItem -Path "\\$Computer\$Drive" -Filter "*$Name*" -Recurse
                }                            
            }
        }
    }
}
