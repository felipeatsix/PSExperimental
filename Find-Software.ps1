Function Find-Software {
    <#
        .SYNOPSIS
            Query and find specific software in local or remote computer.
        
        .DESCRIPTION
            This Powershell function uses registry path to query all software installed in a computer.
            This works much better and faster than using win32_product WMI class. 
        
        .PARAMETER DisplayName
            Set the name of the software to search for.
        
        .PARAMETER Publisher
            Filter the search by Publisher name.
            
        .PARAMETER ComputerName
            Set the computer name target to run it remotely.
        
        .EXAMPLE
            Find-Software -DisplayName '[software]' -ComputerName [hostname]
            This command will get all installed softwares in [hostname] that matches 'Adwords' keyword in it's name.
    
            * You can use the alias -Name instead -DisplayName
        
        .EXAMPLE
            Find-Software -Software 'Skype'
            This command will get the software called 'Skype' in the local computer.
            
        .EXAMPLE
            Find-Software -Publisher 'Microsoft' -ComputerName [hostname]
            This command will get every software in hostname that have Microsoft as it's publisher.         
    
            * You can use the alias -Vendor instead -Publisher
    #>    
   
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        [Alias('Name')]    
        [String]$DisplayName,
          
        [Parameter(ValueFromPipelineByPropertyName=$true,
                    Position=1)]
        [Alias('Vendor')]
        [String]$Publisher,
        $ComputerName = 'localhost'
    )
        
    Invoke-Command -ComputerName $ComputerName -ArgumentList $DisplayName,$Publisher,$ComputerName -ScriptBlock {
    param($DisplayName, $Publisher)
    
    #region Filter Prep
    
    $whereFilter = '![System.String]::IsNullOrEmpty($_.DisplayName)'
    Write-Verbose -Message "Base Where filter: $whereFilter"
        
        If ($DisplayName) {
           
            $whereFilter = '{0} -and ($_.DisplayName -like "{1}")' -f $whereFilter,$DisplayName
            Write-Verbose -Message "Adding display filter: $whereFilter"
        }
        
        If ($Publisher) {
       
            $whereFilter = '{0} -and ($_.Publisher -like "{1}")' -f $whereFilter,$Publisher
            Write-Verbose -Message "Adding publisher filter: $whereFilter"
        }
        
    $whereBlock = [scriptblock]::Create($whereFilter)
    
    #endregion Filter Prep
        
    #region Uninstall Registry Keys
    
    $UNINSTALL_ROOT = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $UNINSTALL_WOW = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $UNINSTALL_USER = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $UNINSTALL_WOWUSER = "HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

    #endregion Uninstall Registry Keys
                   
        $regPath = @{ Name='RegistryKey';Expression={$_.PSPath.Split('::')[-1]} }
    
        [System.String[]]$RegKeys = @(
            $UNINSTALL_ROOT, 
            $UNINSTALL_USER, 
            $UNINSTALL_WOW, 
            $UNINSTALL_WOWUSER
        )
    
        ForEach ($key in $RegKeys) {
      
            If (Test-Path -Path $key) {
            
                Write-Verbose -Message "Reading $key"
                $regKeyColumn = @{ Name='RegistyKey';Expression={$key} }
            
                Try {
                
                    Get-ItemProperty -Path $key  -Name *  -ErrorAction 'Stop' | 
                    Where-Object $whereBlock | 
                
                    Select-Object -Property `
                    DisplayName,
                    DisplayVersion,
                    Publisher,
                    UninstallString,
                    $regPath
                }
            
                Catch { Write-Warning -Message $_.Exception.Message }
            }
        }
    } 
}
