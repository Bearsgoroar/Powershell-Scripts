  <#___   _                           ___   _          _         _   
 / __| | |_    ___  __ __ __  ___  | __| (_)  __ _  | |  ___  | |_ 
 \__ \ | ' \  / _ \ \ V  V / |___| | _|  | | / _` | | | / -_) |  _|
 |___/ |_||_| \___/  \_/\_/        |_|   |_| \__, | |_| \___|  \__|
                                             |___/                 
.SYNOPSIS
Convert text into a larger ascii text expanding over multiple lines
.DESCRIPTION
Convert text into a larger ascii text expanding over multiple lines with support for most (all?) standard figlet fonts".
Supports all standard Powershell colours and includes the option of Rainbow, Random and Christmas colours.
.EXAMPLE
Show-Figlet -Text "Example Text" -Colour Green -Font Shadow
.EXAMPLE
Show-Figlet -Text "Example Text" -Colour Rainbow -Font Colossal
.Notes
Recommended you run QuickStart-Figlet -InstallPath $Path first.

Large parts of this script have been pieced together from the below link by /u/Bearsgoroar
https://www.reddit.com/r/PowerShell/comments/5mm8s9/trying_to_get_better_with_powershell_comments_and/?ref=share&ref_source=link

Special thanks to /u/aXenoWhat who (unknowingly) wrote all the heavy lifting in this script.

Figlet Conventions:
    flf2a$ 6 5 20 15 3 0 143 229
        flf2a: Version number
            $: The defined hardblank character, default $
            6: Character Height
            5: Height ignoring 'descenders' like j,g,p,q
            20: Max_Length + 2
            15: Old_Layout
            4: Comment line, lines for comments at the start of the document
            0: Print Direction, not needed
            143: Not needed
            229: Not needed
#>

function Show-Figlet {
    [CmdletBinding()]
    param(        
        [string]$Text = "Works as Intended!",
        [switch]$IgnoreUnsupported
    )
    DynamicParam {
        ## DynamicParam from https://stackoverflow.com/questions/30111408/powershell-multiple-parameters-for-a-tabexpansion-argumentcompleter

        ## Font Directory
        $FontDirectory = "C:\PSScripts\FigFonts"
        if(!(Test-Path $FontDirectory)) { Write-Error -Message "Font folder not found. Please edit the script to set a folder" }
        
        $ParamNames = @('Colour','Font')

        #Create Param Dictionary
        $ParamDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

        ForEach($Name in $ParamNames){
            #Create a container for the new parameter's various attributes, like Manditory, HelpMessage, etc that usually goes in the [Parameter()] part
            $ParamAttribCollecton = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]

            #Create each attribute
            $ParamAttrib = new-object System.Management.Automation.ParameterAttribute
            $ParamAttrib.Mandatory = $False

            #Create ValidationSet to make tab-complete work
            if($i -le 0) { $arrSet = [Enum]::GetValues([System.ConsoleColor]) + "Rainbow" + "Xmas" + "Random" }
            if($i -ge 1) { $arrSet = Get-ChildItem -Path $FontDirectory | Select-Object -ExpandProperty Basename }
            $ParamValSet = New-Object -type System.Management.Automation.ValidateSetAttribute($arrSet)

            #Add attributes and validationset to the container
            $ParamAttribCollecton.Add($ParamAttrib)
            $ParamAttribCollecton.Add($ParamValSet)

            #Create the actual parameter,  then add it to the Param Dictionary
            $MyParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter($Name, [String], $ParamAttribCollecton)
            $ParamDictionary.Add($Name, $MyParam)
            $i++
        }

        #Return the param dictionary so the function can add the parameters to itself
        return $ParamDictionary
    }

    begin {
        ## Setting font from dynparam if supplied otherwise to ANSI-Shadow
        if($PsBoundParameters["Font"]) { $Font = $PsBoundParameters["Font"] }
        if(!($PsBoundParameters["Font"])) { $Font = "ANSI Shadow" }

        if($PsBoundParameters["Colour"]) { $Colour = $PsBoundParameters["Colour"] }
        if(!($PsBoundParameters["Colour"])) { $Colour = "Green" }

        ## Custom Colour Arrays
        $RainbowArray = @("DarkRed","Red","Yellow","Green","Blue","Cyan","Magenta","DarkMagenta", "DarkRed", 
                          "Red","Yellow","Green","Blue","Cyan","Magenta")
        $XmasArray = @("DarkRed", "Green", "DarkRed", "Green", "DarkRed", "Green", "DarkRed", "Green", 
                       "DarkRed", "Green", "DarkRed", "Green", "DarkRed", "Green")
    }

    process {                            
        ## Counters for below foreach
        $CharacterCounter = 32
        $Skip = 1

        ## Setting up a case sensitive hashtable
        $StringCulture = [system.stringcomparer]::CurrentCulture
        $FigletArray = New-Object system.collections.hashtable $StringCulture

        ## Loading Font
        $SelectedFont = (Get-Content "$FontDirectory\$Font.txt")
        Write-Verbose -Message "Loaded font: $Font from $FontDirectory"

        ## Stuffing $SelectedFont into hashtable $FigletArray
        foreach($Line in $SelectedFont) {
            ## Skipping comment_line length
            if($Skip -le $SkipLines) { Write-Verbose -Message "Skipping line: $Skip of $SkipLines"; $Skip++; Continue }
            if($CharacterCounter -gt 255) { Write-Verbose -Message "Reached end of CharacterCounter but more text exists"; Continue }

            switch($Line) {
                ## Breaking out information from top of figlets file. See: Figlet Conventions, line 21
                {$_ -match "flf2."} {                 
                    $HardBlank = ($Line -split " ")[0] -replace "flf2.", ""
                    $FontHeight = ($Line -split " ")[1]
                    $SkipLines = ($Line -split " ")[5]
                    
                    Write-Verbose -Message "Compare lines:`n $Line `nBlank Character: $HardBlank, Font Height: $FontHeight, Comment Length: $SkipLines"
                }

                ## @@ is end of line, combining together default with last line and adding to hashtable
                {$_ -match "@@"} { 
                    $BuildFigletArray = $BuildFigletArray + ($Line.replace($HardBlank," ").replace("@@", "`n"))
                    $FigletArray.Add([string][char]$CharacterCounter, $BuildFigletArray)

                    Remove-Variable BuildFigletArray
                    $CharacterCounter++
                }

                ## Extended fonts above 160
                {$_ -match "^[0-9][0-9][0-9]  (NO-BREAK SPACE)" -or $ExtendedFonts -eq $True} { 
                    ## Some figletfonts have notes and things at the bottom instead of more fonts. 
                    ## Hopefully this avoids fonts -gt 160 triggering on those things.
                    if($Line -match "^[0-9][0-9][0-9]  (NO-BREAK SPACE)") { $ExtendedFonts = $True }
                    
                    $CharacterCounter = [int]($_ -replace "  .*", "").trim()
                    Write-Verbose "Found Extended Font: $Line new CharacterCounter number is $CharacterCounter" 
                }

                ## Adding lines to $BuildFigletArray until comes across @@ (End of line)
                default { $BuildFigletArray = $BuildFigletArray + ($Line.replace($HardBlank," ").replace("@", "`n")) }
            }
        }

        ## This is where /u/aXenoWhats comes in
        #This relies on the -notin operator helpfully casting char to string 
        $UnsupportedChars = ([char[]]$Text | Where-Object {$_ -notin $FigletArray.Keys}) -join ''
        if ((-not $IgnoreUnsupported) -and $UnsupportedChars) {
            throw "The following characters are not supported in the $Font set: $UnsupportedChars. To render, use the -IgnoreUnsupported switch"
        }

        #Output text, without linebreaks
        #Could use an array, but I think it would be nice to have enqueue and dequeue and a do-while loop
        $GiantText = New-Object System.Collections.Generic.Queue``1[string[]]
        [char[]]$Text | ForEach-Object {
            $GiantText.Enqueue(
                #Sadly we have to explicitly cast the char back to string to match the key
                #We also take this opportunity to split each giant letter into a string array
                $FigletArray[[string]$_] -split "`n"
            )
        }

        $GiantLines = New-Object System.Collections.Generic.List``1[System.Collections.Generic.List``1[string[]]]
        $GiantLines.Add((New-Object System.Collections.Generic.List``1[string[]]))

        $ConsoleWidth = $Host.UI.RawUI.BufferSize.Width
        $CursorPos = 0

        do {
            #Do we need to start a new line?
            $NextChar = $GiantText.Peek()
            $NextCharWidth = $NextChar[0].Length
            if (($CursorPos + $NextCharWidth) -gt $ConsoleWidth) {
                $GiantLines.Add((New-Object System.Collections.Generic.List``1[string[]]))
                $CursorPos = 0
            }

            $GiantLines[-1].Add($GiantText.Dequeue())
            $CursorPos += $NextCharWidth

        } while ($GiantText.Count -gt 0)

        
        if($Colour -match "(Rainbow|Random|Xmas)") { $ColourStyle = $Colour }

        # We should now have a list of lists - that is, lines of giant characters
        foreach ($Line in $GiantLines) {
            $LineHeight = $FontHeight #$Line[0].Count

            for ($i=0; $i -lt $LineHeight; $i++) {
                switch ($ColourStyle) {
                    "Random" { $Colour = Get-Random -Input ([Enum]::GetValues([System.ConsoleColor])) }
                    "Rainbow" { $Colour = $RainbowArray[$i] }
                    "Xmas" { $Colour = $XmasArray[$i] }
                }

                foreach ($Char in $Line) {
                    Write-Host -NoNewline $Char[$i] -ForegroundColor $Colour
                }

                ## Required *Ominious background noises*
                Write-Host 
            }
        }
    }
}


<# ___         _           ___   _          _         _        
  / __|  ___  | |_   ___  | __| (_)  __ _  | |  ___  | |_   ___
 | (_ | / -_) |  _| |___| | _|  | | / _` | | | / -_) |  _| (_-<
  \___| \___|  \__|       |_|   |_| \__, | |_| \___|  \__| /__/
                                    |___/                      
#>
    
function Get-Figlets {
<#
.Notes
This was a quick and dirty script. 

https://github.com/patorjk/figlet.js/tree/master/fonts is a good source and figlets.org
.SYNOPSIS
Creates a Powershell readable local copy of the figlet font format
.DESCRIPTION
Creates a local copy of a figlet font from http://www.figlet.org/
.EXAMPLE
Get-Figlets -InstallPath "C:\FigletFonts" -Quickstart
.EXAMPLE
Get-Figlets -Source https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/ANSI Shadow.flf -Name "ANSI Shadow" -InstallPath "C:\FigletFonts"
#>

    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Name,
        [string]$InstallPath = "C:\PSScripts\FigFonts",
        [switch]$QuickStart
    )

    if(Test-Path $InstallPath -eq $False) { Write-Output 'InstallPath doesnt exist. Please either change the path in the script or include -InstallPath $Path'  }

    if($Source) { 
        if($Source -match "https?://github.com/") { Write-Output "Please use Raw instead"; Break }
        (Invoke-WebRequest -Uri $Source ).content | Out-File "$InstallPath\$Name.txt"
        Write-Output "Added font: $Name to directory: $InstallPath"
    }

    if($QuickStart) {
        $Links = @("https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/ANSI Shadow.flf",
                   "https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/Colossal.flf"
                   "https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/Small.flf",
                   "https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/Tengwar.flf"
                  )

        foreach($Link in $Links) {
            $Name = $Link -replace "https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/", "" -replace "\.flf", ""
            (Invoke-WebRequest -Uri $Link ).content | Out-File "$InstallPath\$Name.txt" -Force

            Write-Output "Added font: $Name to directory: $InstallPath"
        }
    }
}
