
function Set-LoginShell {
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

            else {
                Write-Verbose "Operation cancelled."
            }
        }

        else {
            Write-Warning "The LoginShell attribute for $($UserData.Name) is already set to $Shell" 
        }
}  