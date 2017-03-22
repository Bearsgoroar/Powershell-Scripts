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
        [string][ValidateScript( { $_ -in [Enum]::GetValues([System.ConsoleColor]) -or $_ -match "(Rainbow|Random|Xmas)"} )]$Colour = "Red",
        [switch]$IgnoreUnsupported
    )
    DynamicParam {
        ## Font Directory
        $FontDirectory = "C:\PSScripts\FigFonts"
        
        # Set the dynamic parameters' name
        $ParameterName = 'Font'
        
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            
        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        #$ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 3

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet 
        $arrSet = Get-ChildItem -Path $FontDirectory | Select-Object -ExpandProperty Basename
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin {
        ## Setting font from dynparam if supplied otherwise to ANSI-Shadow
        if($PsBoundParameters["Font"]) { $Font = $PsBoundParameters["Font"] }
        if(!($PsBoundParameters["Font"])) { $Font = "ANSI Shadow" }

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
        Write-Verbose -Message "Loaded font: $Font"

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
                    #$FontWidth = ($Line -split " ")[3] - 2
                    $SkipLines = ($Line -split " ")[5]
                    
                    Write-Verbose -Message "Compare lines:`n $Line `nBlank Character: $HardBlank, Font Height: $FontHeight, Font Width: $FontWidth, Comment Length: $SkipLines"
                }

                ## @@ is end of line, combining together default with last line and adding to hashtable
                {$_ -match "@@"} { 
                    $BuildFigletArray = $BuildFigletArray + ($Line.replace($HardBlank," ").replace("@@", "`n"))
                    $FigletArray.Add([string][char]$CharacterCounter, $BuildFigletArray)

                    Remove-Variable BuildFigletArray
                    $CharacterCounter++
                }

                ## Extended fonts above 160
                {$_ -match "^[0-9][0-9][0-9]  (NO-BREAK SPACE)"} { 
                    $CharacterCounter = [int]($_ -replace "  .*", "").trim()
                    Write-Verbose "Found Extended Font: $Line new CharacterCounter number is $CharacterCounter" 
                }

                ## Adding lines to LetterArray until comes across @@ (End of line)
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


<#                        _                  __   _          _         _   
  __   _ _   ___   __ _  | |_   ___   ___   / _| (_)  __ _  | |  ___  | |_ 
 / _| | '_| / -_) / _` | |  _| / -_) |___| |  _| | | / _` | | | / -_) |  _|
 \__| |_|   \___| \__,_|  \__| \___|       |_|   |_| \__, | |_| \___|  \__|
                                                     |___/                 
#>
    
function Get-Figlet {
<#
.Notes
This was a quick and dirty script. 'Get-Figlet' to get a list of names and 'Get-Figlet -Download $Name' to download the font.

https://github.com/patorjk/figlet.js/tree/master/fonts is a good source apart from figlets.org
.SYNOPSIS
Creates a Powershell readable local copy of the figlet font format
.DESCRIPTION
Creates a local copy of a figlet font from http://www.figlet.org/
.EXAMPLE
Get-Figlet to create a list of fonts
.EXAMPLE
Get-Figlet -Download Colossal to download
#>

    param(
        [string]$Name,
        [string]$Source,
        [switch]$Download,
        [string]$InstallPath = "C:\PSScripts\FigFonts"
    )

    if($Source) { 
        if($Source -match "https?://github.com/") { $Source = $Source -replace "https?://github.com/", "https://raw.githubusercontent.com/" }
        if(!($Name)) { Write-Output "You need to supply a name"; Break }
        (Invoke-WebRequest -Uri $Source ).content | Out-File "$InstallPath\$Name.txt"
    }

    if(!($Download)) {
        if($Source) { Continue }
        if($Name) { 
            $Link = "http://www.figlet.org/fontdb_example.cgi?font=$Name.flf" 
            (Invoke-WebRequest -Uri $Link).Content -Replace "<.*>", ""
        }

        else {
            $Link = "http://www.figlet.org/fontdb.cgi" 
            (Invoke-WebRequest -Uri $Link).links | Where-Object href -Match "fontdb_example.cgi" | Select-Object innerText
        }
    }

    if($Download) {
        if(!($Name)) { Write-Output "You need to supply a name"; Break }
        $Link = "http://www.figlet.org/fonts/$Name.flf"
        (Invoke-WebRequest -Uri $Link).content | Out-File "$InstallPath\$Name.txt"
        Write-Output "Added font: $Name to directory: $InstallPath"
    }

    if($Source) { 
        if($Source -match "https?://github.com/") { Write-Output "Please use Raw instead" }
        if(!($Name)) { Write-Output "You need to supply a name"; Break }
        (Invoke-WebRequest -Uri $Source ).content | Out-File "$InstallPath\$Name.txt"
        Write-Output "Added font: $Name to directory: $InstallPath"
    }
}  


<# ___           _        _     ___   _                  _           ___   _          _         _   
  / _ \   _  _  (_)  __  | |__ / __| | |_   __ _   _ _  | |_   ___  | __| (_)  __ _  | |  ___  | |_ 
 | (_) | | || | | | / _| | / / \__ \ |  _| / _` | | '_| |  _| |___| | _|  | | / _` | | | / -_) |  _|
  \__\_\  \_,_| |_| \__| |_\_\ |___/  \__| \__,_| |_|    \__|       |_|   |_| \__, | |_| \___|  \__|
                                                                              |___/               #>
function QuickStart-Figlet {
<#
.Notes
This was a quick and dirty script to get you started with Show-Figlet quickly.

Fonts from patorjks github
.SYNOPSIS
Quick start for Show-Figlet
.DESCRIPTION
Creates a local copy of a figlet font from patorjks github to get you started quickly
.EXAMPLE
QuickStart-Figlet -$InstallPath "C:\FigletFonts"
#>

    param(
        [Parameter(Mandatory=$true)][string]$InstallPath
    )

    $Links = @("https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/ANSI Shadow.flf",
               "https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/Colossal.flf"
               "https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/Small.flf",
               "https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/Tengwar.flf"
              )

    foreach($Link in $Links) {
        $Name = $Link -replace "https://raw.githubusercontent.com/patorjk/figlet.js/master/fonts/", "" -replace "\.flf", ""
        (Invoke-WebRequest -Uri $Link ).content | Out-File "$InstallPath\$Name.txt" -Force

        Write-Output "Added font: $Name to directory: $InstallPath" -ForegroundColor Green -BackgroundColor Black
    }
}  
