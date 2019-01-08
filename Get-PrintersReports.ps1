Function Get-PrinterReports {
 
    Begin {       
        $snmp = New-Object -ComObject olePrn.OleSNMP
        $ping = New-Object System.Net.NetworkInformation.Ping
        $data = Import-CSV [csv filepath]        
        $File = [html out file path] 
        $VerbosePreference = "Continue"
        $Css = [css content file path]

        if (!(Test-Path $File)) {
            New-Item -Path $File -Name Printer_Reports.html -ItemType File -Force
        }
        
        else { Clear-Content $File }
    }
    
    Process { 
    
        foreach ($printer in $data) {                                            

            try { $result = $ping.Send($printer.ip) } 
            catch { $result = $null }

            if ($result.Status -eq 'Success') {
                
                Write-Verbose "Querying snmp information on printer $($printer.PrinterName):"                                    
                                                                            
                $snmp.open($printer.IP, $printer.Community, 2, 3000)

#region GET DATA
            
            # FIND MODEL                                
            try { $model = $snmp.Get('.1.3.6.1.2.1.25.3.2.1.3.1') } Catch { $model = "not found" }
                                       
            Switch -Regex ($model) {
                    
                '^HP' {
                    $name = $snmp.Get('.1.3.6.1.4.1.11.2.4.3.5.46.0').toupper()
                }                                                   
            }             
            
            # STATUS
                $StatusTree = $snmp.gettree("43.18.1.1.8") | where {$_ -notlike "print*"}
            
            # COLOR                    
                try { if ($snmp.Get('.1.3.6.1.2.1.43.11.1.1.6.1.2') -match 'Toner|Cartridge') { $color = 'Yes' } else { $color = 'No' } } Catch { $color = 'No' }
                                                    
            # TRAYS
                try { $trays = $($snmp.GetTree('.1.3.6.1.2.1.43.8.2.1.13') | ? {$_ -notlike 'print*'}) } Catch { $trays = "not found" }

            # BLACK TONER                                
                Try { $BlackCapacity = $snmp.get("43.11.1.1.8.1.1") } Catch { $BlackCapacity = $null }    
                Try { $BlackVolume = $snmp.get("43.11.1.1.9.1.1") } Catch { $BlackVolume = $null }
                
                if ($BlackCapacity -ne $null -and $BlackVolume -ne $null) {
                    [int]$BlackToner = ($BlackVolume / $BlackCapacity * 100)
                }              

            # COLORED TONERS

            if ($Color -eq 'Yes') {
                
                    Try { $CyanCapacity = $snmp.get("43.11.1.1.8.1.2") } Catch { $CyanCapacity = $null }    
                    Try { $CyanVolume = $snmp.get("43.11.1.1.9.1.2") } Catch { $CyanVolume = $null }
                
                    if ($CyanCapacity -ne $null -and $CyanVolume -ne $null) {
                        [int]$CyanToner = ($CyanVolume / $CyanCapacity * 100)
                    }

                    Try { $MagentaCapacity = $snmp.get("43.11.1.1.8.1.3") } Catch { $MagentaCapacity = $null }    
                    Try { $MagentaVolume = $snmp.get("43.11.1.1.9.1.3") } Catch { $MagentaVolume = $null }
                
                    if ($MagentaCapacity -ne $null -and $MagentaVolume -ne $null) {
                        [int]$MagentaToner = ($MagentaVolume / $MagentaCapacity * 100)
                    }

                    Try { $YellowCapacity = $snmp.get("43.11.1.1.8.1.4") } Catch { $YellowCapacity = $null }    
                    Try { $YellowVolume = $snmp.get("43.11.1.1.9.1.4") } Catch { $YellowVolume = $null }
                
                    if ($YellowCapacity -ne $null -and $YellowVolume -ne $null) {
                        [int]$YellowToner = ($YellowVolume / $YellowCapacity * 100)
                    }
                }                

#endregion GET DATA  

#region Build OBJECT / HTML CONTENT

            # OBJECT                                                                
                $Object = [PSCustomObject]@{                                   
                    IP = $result.Address
                    Model = $model
                    Color = $Color
                    Trays = $trays.count                    
                    Black = "$($BlackToner)%"
                    Cyan = "$($CyanToner)%"
                    Magenta = "$($MagentaToner)%"
                    Yellow = "$($YellowToner)%"
                    Status = $StatusTree
                }                

            # HTML
                $params = @{
                    As = 'List'
                    PreContent = "<h2>+ $($Printer.PrinterName)</h2>"
                    MakeTableDynamic = $true
                    MakeHiddenSection = $true
                    TableCssClass = 'List'
                    Properties = 'Model','Color','Trays','Black','Cyan','Magenta','Yellow','Status'
                }                
                            
                $Frag = $Object | ConvertTo-EnhancedHTMLFragment @params

#endregion Build OBJECT / HTML CONTENT                

                
                $HTMLParams = @{
                    Title = 'Printer Reports'
                    HTMLFragments = $Frag
                    CssUri = $Css
                } 

                $HTML = ConvertTo-EnhancedHTML @HTMLParams                                
                $HTML >> $File                                
            }
            else { Write-Warning "$($Printer.PrinterName) is not reachable!" }
        }
            Write-Output "The Printer Reports has been created: $File"
    }
}
