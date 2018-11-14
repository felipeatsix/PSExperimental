function Set-LoginShell {

<#
    .SYNOPSIS
       Quickly set loginshell attribute for an AD user.
    
    .DESCRIPTION
       This function helps to solve some issues that may be caused by a wrong AD user configuration. 
    
    .PARAMETER UserName
        Set the AD user target.
    
    .PARAMETER Shell
        Set the LoginShell attribute.
    
    .Example
        Set-LoginShell -UserName fdesouzasantos -Shell /bin/bash
        This will set fdesouzasantos loginshell attribute value to /bin/bash             
#>

    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    
    param(
    
        [Parameter(Mandatory)]
        $UserName,
        [Parameter(Mandatory)]
        [ValidateSet("/bin/bash","/bin/zsh")]
        $Shell
    )

    $VerbosePreference = 'Continue'
    
    Try {
    
        $UserData = Get-ADUser -Filter "SamAccountName -eq '$UserName'" -Properties loginshell
    } 
    
    catch {
    
        throw "Could not find username $UserName"
        break;
    
    }

        if($UserData.LoginShell -notmatch $Shell) {
    
                if($PSCmdlet.ShouldProcess($UserData.DistinguishedName)) {                     
    
                    Set-Aduser -Identity $UserData -Replace @{loginshell=$Shell}     
                    Write-Verbose "LoginShell attribute for $UserName has been set to: $Shell"
            
                }

                else { Write-Verbose "Operation cancelled." }
        }

        else { Write-Warning "The LoginShell attribute for $($UserData.Name) is already set to $Shell" }
}  
