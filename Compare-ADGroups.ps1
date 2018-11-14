function Compare-ADGroups {
<#
    .SYNOPSIS
        Compares the assigned AD groups between two different users.
    
    .DESCRIPTION
        This function helps to quickly compare the access level between two different users. 
        This can help to solve issues related to access.

    .PARAMETER UserName1
        Set the first user name to be compared with the second one.
    
    .PARAMETER UserName2
        Set the second user name to be compared with the first one.        

    .EXAMPLE
        Compare-ADGroups -UserName1 fdesouzasantos -UserName2 a-fdesouzasantos
        This command will compare the assigned AD groups between fdesouzasantos and a-fdesouzasantos.
#>    
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        $UserName1,
        [Parameter(Mandatory)]
        $UserName2
    )

    $VerbosePreference = 'Continue'    
    
    $Access1 = Get-ADPrincipalGroupMembership -Identity $UserName1 
    $Access2 = Get-ADPrincipalGroupMembership -Identity $UserName2   
    
    $Reference = @()
    $Difference = @()

    $Compare = Compare-Object -ReferenceObject $Access1.SamAccountName -DifferenceObject $Access2.SamAccountName
        
        foreach ($Item in $Compare) {
        
            if ($Item.SideIndicator -eq "=>") {                                
                $Reference += $item.InputObject
            }

            if ($Item.SideIndicator -eq "<=") {
                $Difference += $Item.InputObject
            }
        }

        Write-Verbose "$UserName1 does not have access to:"
        ""
        $Reference        
        ""
        Write-Verbose "$UserName2 does not have access to:"        
        ""
        $Difference
}