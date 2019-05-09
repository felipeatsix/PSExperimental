#Requires -Module EnhancedHTML2

# Make sure to setup your execution policy and to install the required module. 
# Set-ExecutionPolicy RemoteSigned
# Install-Module EnhancedHTML2 -Verbose

Function Get-HTMLComputerData {
    
    Begin{      
                
        $RootPath = $PSScriptRoot                  
        $OSData = Get-CimInstance -ClassName Win32_OperatingSystem                
        $Css = Get-Item "$RootPath\*.css"
        $RamSection = "$(hostname): RAM Usage"
        $OSinfoSection = "$(hostname): OS Info"     

        # Fragments Properties                
        
        $RamProperties = @(                                            
            
            'TotalRam',
            'FreeRam',
            @{
                Name = 'FreeRam(%)'; Expression = {$_.FreePercentageRam}
                Css = {                 
                    If ($_.FreePercentageRam -gt 50) {'Green'}
                    ElseIF ($_.FreePercentageRam -gt 25) {'Yellow'}
                    Else{'Red'}
                }
            }
        )
        
        $OSInfoProperties = @(            
            
            'Computer'
            'Last Bootup Time'
            'Install Date'
        )
        
    }   
    
        Process {        
            
            # Ram custom vars
            
            [int]$TotalRam = ($OSData.TotalVisibleMemorySize / 1mb)
            $RamFree = [math]::Round($OSData.FreePhysicalMemory / 1mb,1)
            $RamFP = "{0:P0}" -f ($OSData.FreePhysicalMemory / $OSData.TotalVisibleMemorySize)
            
            # Tables
            
            $RAMTable = [PSCustomObject]@{        
                
                TotalRam = "$TotalRam GB"                
                FreeRam = "$RamFree GB"
                FreePercentageRam = $RAMFP
            }                    

            $OSInfoTable = [PSCustomObject]@{        

                'Computer' = "$(hostname)"                 
                'Last Bootup Time' = $OSData.lastbootuptime
                'Install Date' = $OSData.InstallDate            
            }
            

        # HTML Fragments
        
        $RAMparams = @{
            
            As = 'List'
            PreContent = "<h2>$RamSection</h2>"
            MakeHiddenSection = $true
            TableCssClass = 'List'
            Properties = $RamProperties
        }

        $OSInfoparams = @{
            
            As = 'List'
            PreContent = "<h2>$OSInfoSection</h2>"
            MakeHiddenSection = $true
            TableCssClass = 'List'
            Properties = $OSINfoProperties
        }
        
        $ProcessParams = @{
            
            As = 'Table'
            PreContent = "<h2>Processes</h2>"
            MakeHiddenSection = $true
            TableCssClass = 'Grid'
            Properties = 'Name'            
        }
        
            $RAMFrag = $RAMTable | ConvertTo-EnhancedHTMLFragment @RAMparams   
            $OSFrag = $OSInfotable | ConvertTo-EnhancedHTMLFragment @OSInfoparams
            $ProcessFrag  = Get-Process | ConvertTo-EnhancedHTMLFragment @ProcessParams

        # HTML Build
        
        $HTMLParams = @{
            
            Title = 'PC DATA'
            HTMLFragments = $OSFrag,$RAMFrag,$ProcessFrag
            CssUri = $Css.FullName
        } 
    }

    End {
    
        $HTML = ConvertTo-EnhancedHTML @HTMLParams
        $HTML | Out-File $RootPath\PCDATA.html -Force
        Invoke-Item $RootPath\PCDATA.html
    }
}