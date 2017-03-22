## ██╗   ██╗████████╗██╗██╗     ██╗████████╗██╗███████╗███████╗
## ██║   ██║╚══██╔══╝██║██║     ██║╚══██╔══╝██║██╔════╝██╔════╝
## ██║   ██║   ██║   ██║██║     ██║   ██║   ██║█████╗  ███████╗
## ██║   ██║   ██║   ██║██║     ██║   ██║   ██║██╔══╝  ╚════██║
## ╚██████╔╝   ██║   ██║███████╗██║   ██║   ██║███████╗███████║
##  ╚═════╝    ╚═╝   ╚═╝╚══════╝╚═╝   ╚═╝   ╚═╝╚══════╝╚══════╝

##
## Scripts section
##

## Used for getting api keys / passwords / anything sensitive without exposing the info via uploaded scripts
function Get-SecretInfo() {
    param(
        [Parameter(Mandatory=$True)][string]$Name
    )

    $Data = Get-Content -Path "C:\PSScripts\Kingdom.txt"

    foreach($Line in $Data) {
        if($Line -match $Name) {
            $SecureKey = $Line -replace "$Name=", "" | ConvertTo-SecureString
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureKey)
            $Return = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }
    }
    Return $Return
}


## For adding new keys / passwords / anything sensitive to the kingdom.txt file.
function Set-SecretInfo() {
    param(
        [Parameter(Mandatory=$True)][string]$Name,
        [Parameter(Mandatory=$True)][string]$Key
    )

    $Data = Get-ChildItem -Path "C:\PSScripts\Kingdom.txt"

    $SecureKey = ConvertTo-SecureString $Key -AsPlainText -Force | ConvertFrom-SecureString
    Add-Content -Path $Data "$Name=$SecureKey"
    Write-Host "Added $Name=$Key"
}



##
## QoL Scripts
##

## Camel Case
function ConvertTo-CamelCase() {
    param(
        [Parameter(Mandatory=$True)][string]$Text
    )

    Return (Get-Culture).TextInfo.ToTitleCase($Text)
}

## Upper Case
function ConvertTo-UpperCase() {
    param(
        [Parameter(Mandatory=$True)][string]$Text
    )

    Return $Text.ToUpper()
}

## Lower Case
function ConvertTo-LowerCase() {
    param(
        [Parameter(Mandatory=$True)][string]$Text
    )

    Return $Text.ToLower()
}

## Cause I'm Lazy
function Write-Message() {
    param(
        [Parameter(Mandatory=$True)][string][ValidateSet("Error", "Bot", "Load", "Blank")]$Type,
        [Parameter(Mandatory=$True)][string]$Text,
        [Parameter(Mandatory=$False)][string]$Username,
        [Parameter(Mandatory=$False)][string]$Prefix,
        [Parameter(Mandatory=$False)][string][ValidateScript({ $_ -in [Enum]::GetValues([System.ConsoleColor])})]$PrefixColour = "White",
        [Parameter(Mandatory=$False)][string][ValidateScript({ $_ -in [Enum]::GetValues([System.ConsoleColor])})]$PrefixBackgroundColour = "Magenta",
        [Parameter(Mandatory=$False)][string][ValidateScript({ $_ -in [Enum]::GetValues([System.ConsoleColor])})]$UsernameColour

    )

    if($Type -eq "Error") { Write-Host "  Error!  " -ForegroundColor Red -BackgroundColor Yellow -NoNewline; Write-Host " $Text " -ForegroundColor White -BackgroundColor Black -NoNewline; Write-Host " " -BackgroundColor Yellow  }
    if($Type -eq "Bot") { $Date = Get-Date -Format "yyyy-MM-dd hh:mm:ss"; Write-Host "$Date | " -NoNewline; Write-Host "$Username" -NoNewline -ForegroundColor $UsernameColour  ; Write-Host ": $Text" }
    if($Type -eq "Load") { Write-Host "  Loaded  " -ForegroundColor White -BackgroundColor Green -NoNewline; Write-Host " $Text " -ForegroundColor White -BackgroundColor Black }
    if($Type -eq "Blank") { Write-Host "  $Prefix  " -ForegroundColor $PrefixColour -BackgroundColor $PrefixBackgroundColour -NoNewline; Write-Host " $Text " -ForegroundColor White -BackgroundColor Black }
}


##
## TV Scripts
##

## Gets a list of Tv Shows airing for todays date
function Get-TvAiringToday() {
    $results = Invoke-RestMethod -uri "https://api.themoviedb.org/3/tv/airing_today?api_key=$apikey&language=en-US" -ContentType "application/json" 
    $result = $results.results | Select id,name,popularity
    $pages = $results.total_pages
    $array = @()
    $array += $result
    $i = 1

    while($i -ne $pages) {
        $i++
        $result = (Invoke-RestMethod -uri "https://api.themoviedb.org/3/tv/airing_today?api_key=$apikey&language=en-US&page=$i" -ContentType "application/json").results | Select id,name,popularity
        $array += $result
    }

    foreach($hash in $array) {
        $Return = ([PSCustomObject]$hash)
    }

    Return $Return #| Format-Table -AutoSize
}

## Converts a TV Show into the corrosponding ID on themoviedb.org
function Get-TvShowID() {
    param( [Parameter(Mandatory=$true)][string]$Name )
    
    $apikey = Get-SecretInfo -Name "APIKEY_moviedb"
    $results = Invoke-RestMethod -uri "https://api.themoviedb.org/3/search/tv?api_key=$apikey&language=en-US&query=$Name" -ContentType "application/json"
    Return $results.results.id[0]
}

## Gets all the episodes for the specified ID in the specificed season of a show.
function Get-TvShowSeasons() {
    param(
        [Parameter(Mandatory=$true)][string]$ID,
        [Parameter(Mandatory=$true)][string]$Season
    )

    $ID = "68597"
    $Season = "1"
    $apikey = Get-SecretInfo -Name "APIKEY_moviedb"
    $link = "https://api.themoviedb.org/3/tv/$ID/season/fuckyouquestionmark?api_key=$apikey&language=en-US" -replace "fuckyouquestionmark","$Season"
    $results = Invoke-RestMethod -uri $link -ContentType "application/json"
    
    $data = $results.episodes | select name,episode_number
    
    Return $data
}

## Gets a count of total seasons and total episodes
function Get-TvShowTotalEpisodesAndSeason() {
    param(
        [Parameter(Mandatory=$False)][string]$ID,
        [Parameter(Mandatory=$False)][string]$Name
    )

    $Apikey = Get-SecretInfo -Name "APIKEY_moviedb"

    if(!($Name) -and !($ID)) { 
        Write-Host "You must either include a -name or an -id"
        Break
    }

    if(!($ID)) { $ID = Get-TvShowID -Name $Name }

    Return (Invoke-RestMethod -uri ($("https://api.themoviedb.org/3/tv/fuckyouquestionmark?api_key=$Apikey&language=en-US") -replace "fuckyouquestionmark","$ID")).seasons | Select season_number,episode_count
}

## Gets more detailed information about a specific episode
function Get-TvShowEpisode() {
    param(
        [Parameter(Mandatory=$true)][string]$ID,
        [Parameter(Mandatory=$true)][string]$Season,
        [Parameter(Mandatory=$true)][string]$Episode
    )

    $apikey = Get-SecretInfo -Name "APIKEY_moviedb"
    $link = "https://api.themoviedb.org/3/tv/$ID/season/$Season/episode/fuckyouquestionmark?api_key=0cfdef6c6f1639a3e095e60119603558&language=en-US" -replace "fuckyouquestionmark","$Episode"
    $results = Invoke-RestMethod -uri "$link" -ContentType "application/json"
    
    $data = $results.name #| select name,episode_number
    
    Return $data
}

## Compares Moviedbs seasons/episodes against a local folders then tells you what episodes are missing
function Find-TvShowMissing() {
    param(
        [Parameter(Mandatory=$True)][string]$Name,
        [Parameter(Mandatory=$False)][string]$ID,
        [Parameter(Mandatory=$False)][string]$Directory
    )

    if(!($Directory)) { $Directory = "E:\TV\" }
    if(!($Name)) { $Name = "Breaking Bad" }

    $i = 1
    $MovieDBList = @()

    $LocalList = (Get-ChildItem -Path "$Directory$Name").Name -replace '(\.mp4|\.mkv|\.avi|\.mpg|\.divx|\.wmv|\.3gp)', '' -replace ' - .*', '' -replace " (1|2)[0-9][0-9][0-9]", ""
    $LocalArray = {$LocalList}.Invoke()

    if($Name -match ".*(1|2)[0-9][0-9][0-9].*") { $Name = $Name -replace " (1|2)[0-9][0-9][0-9]", "" }
    if(!($ID)) { $Seasons = Get-TvShowTotalEpisodesAndSeason -Name $Name }
    if($ID) { $Seasons = Get-TvShowTotalEpisodesAndSeason -ID $ID }

    foreach($Line in $LocalArray) {
        if($Line -notmatch ".*S[0-9][0-9]E[0-9][0-9].*") { $LocalArray = $LocalArray -ne $Line }
        if($Line -match ".*S[0-9][0-9]E00.*") { $LocalArray = $LocalArray -ne $Line }
      
        if(($Line -match "(?<start>.*S[0-9][0-9])(?<ep1>E[0-9][0-9])(?<ep2>E[0-9][0-9])(?<therest>.*)") -eq $True) { 
            $Start = $matches['start']
            $Ep1 = $matches['ep1']
            $Ep2 = $matches['ep2']

            $LocalArray += "$Start$Ep1"
            $LocalArray += "$Start$Ep2"
            $LocalArray = $LocalArray -ne "$Start$Ep1$Ep2"
        }
    }

    foreach($Season in $Seasons) {
        $SeasonNumber = $Season.season_number
        $EpisodeNumber = $Season.episode_count
        
        if($SeasonNumber -lt "1") { Continue }
        if($SeasonNumber -match "^[0-9]$") { $SeasonNumber = "0$SeasonNumber" }

        while($i -le $Season.episode_count) {
            if($i -match "^[0-9]$") { $EpisodeNumber = "0$i" }
            if($i -notmatch "^[0-9]$") { $EpisodeNumber = $i }
            
            $CompiledName = "$Name S"+$SeasonNumber+"E$EpisodeNumber"
            $MovieDBList += $CompiledName
            
            $i++
        }

        $i = 1
        Start-Sleep 0.25
     }

     $Compared = Compare-Object $LocalArray $MovieDBList -IncludeEqual | Where SideIndicator -ne "=="
     Return $Compared.InputObject
}