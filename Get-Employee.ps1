
function Get-Employee {

    <#
        .SYNOPSIS
            Get a customizable Active Directory user data searching by name or username.
        
        .DESCRIPTION
            Find user data filtering it with useful information.
        
        .PARAMETER UserName
            Search for the user by user name.

        .PARAMETER Name
            Search for the user by name.
        
        .EXAMPLE
            Get-Employee -UserName 'fdesouza'            
            This will find the user 'fdesouzasantos' because the script uses wildcard automatically. 
        
        .EXAMPLE
            Get-Employee -Name 'Felipe de Souza'
            This will find the user 'Felipe de Souza Santos' because the script uses wildcard automatically.                                                                                       
        
        .NOTES
            You can use the alias 'Find' to use this command.
    #>  
     
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'ByUserName')]
        [string]$UserName,
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$Name        
    )        
    
    Switch($PSCmdlet.ParameterSetName) {
    
        'ByUserName' {
        
            $filter ='SamAccountName'
            $Param = $UserName
        }
    
        'ByName' {
            $filter = 'Name'
            $Param = $Name
        }        
    }
    
    $Properties = @{            
        Filter = "$filter -like '$Param*'"            
        Properties = "loginshell","title","StreetAddress","Company"
    }
                                                  
    if(!($Obj = Get-ADUser @Properties)) {                    
        Write-Warning "$Param cannot be found!"           
    }

    else {
        
        $Select = @(
                    "Enabled",
                    "Company",
                    "Name",
                    "SamAccountName",
                    "Title",
                    "UserPrincipalName",
                    "loginshell",
                    "DistinguishedName",
                    "StreetAddress" )             
        
        Write-Output $Obj | select $Select
    }
}
