function Get-Torrent() {
    param(
        [Parameter(Mandatory=$false)][string]$Name,
        [Parameter(Mandatory=$false)][switch]$Download,
        [Parameter(Mandatory=$false)][string]$Tracker
    )

    if(!($Name)) { 
        $Tracker = "https://eztv.ag"
        $Name = $null
        $Search = $null 
    }

    if($Tracker -match "ez.?tv") { $Tracker = "https://eztv.ag/search/" }
    if($Tracker -match "(the |^)pirate.?bay") { $Tracker = "http://thepiratebay.se.com/search/" }
    if($Tracker -match "nyaa($|\.?se)") { $Tracker = "https://www.nyaa.se/?page=search&cats=0_0&filter=0&term=" }
    if($Tracker -match "extra($|torrent)") { $Tracker = "https://extratorrent.cc/search/?search=" }

    $array = @()
    
    ## EZTV
    if($Tracker -eq "https://eztv.ag/search/") { 
        $Search = $Name -replace " ", "-" 
        $Data = (Invoke-WebRequest $Tracker$Search).links | Where class -eq "magnet" | Select title,href
        
    }

    ## extratorrent
    if($Tracker -eq "https://extratorrent.cc/search/?search=") { 
        $Name = $Name -replace " ", "+" 
        $Data = (Invoke-WebRequest $Tracker$Name).links | Where title -eq "Magnet link"# | Select title,href
        
        $spilts = $Data.href -split " "

        $splits[0]
        foreach($split in $i) {
            Write-Host "Fuck" $split
        }

        Break


      

    #foreach($hash in $array) {
    #    ([PSCustomObject]$hash)
    #    Break
        
    } 

    ## Pirate Bay
    if($Tracker -eq "http://thepiratebay.se.com/search/") { $Name = $Name -replace " ", "%20" }

    ## Nyaa.se for Animoo
    if($Tracker -eq "https://www.nyaa.se/?page=search&cats=0_0&filter=0&term=") { 
        $Name = $Name -replace " ", "+" 
        $Data = (Invoke-WebRequest $Tracker$Name).links | Where title -eq $null | Select innerText,href

        foreach($Line in $Data) {
            $Name = $Line.innerText
            $Download = $Line.href -replace "//www\.nyaa\.se/\?page=view&amp;tid=", "www.nyaa.se/?page=download&tid="

            if(($Line.innerText.Length) -lt 3) { Continue }

            Write-Host "$Name $Download"
        }
    }
    
    if(!($Download)) { Return $Data }  

    if($Download) {
        foreach($Line in $Data) {
            if(($Line.title) -notmatch $Name) { Continue }
            start $Line.href
            Write-Host "Found "$Line.Title.Replace("Torrent: Magnet Link", "")" Starting download now"
        }
    }
}


$apikey = "0cfdef6c6f1639a3e095e60119603558"

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
        ([PSCustomObject]$hash)
    }

    Return $array | Format-Table -AutoSize
}

function Get-TvShowID() {
    param( [Parameter(Mandatory=$true)][string]$Name )

    $results = Invoke-RestMethod -uri "https://api.themoviedb.org/3/search/tv?api_key=$apikey&language=en-US&query=$Name" -ContentType "application/json"
    Return $results.results.id[0]
}

function Get-TvShowSeasons() {
    param(
        [Parameter(Mandatory=$true)][string]$ID,
        [Parameter(Mandatory=$true)][string]$Season
    )

    $link = "https://api.themoviedb.org/3/tv/$ID/season/fuckyouquestionmark?api_key=$apikey&language=en-US" -replace "fuckyouquestionmark","$Season"
    $results = Invoke-RestMethod -uri $link -ContentType "application/json"
    
    $data = $results.episodes | select name,episode_number
    
    Return $data
}

function Get-TvShowEpisode() {
    param(
        [Parameter(Mandatory=$true)][string]$ID,
        [Parameter(Mandatory=$true)][string]$Season,
        [Parameter(Mandatory=$true)][string]$Episode
    )

    $link = "https://api.themoviedb.org/3/tv/$ID/season/$Season/episode/fuckyouquestionmark?api_key=0cfdef6c6f1639a3e095e60119603558&language=en-US" -replace "fuckyouquestionmark","$Episode"
    $results = Invoke-RestMethod -uri "$link" -ContentType "application/json"
    
    $data = $results.name #| select name,episode_number
    
    Return $data
}

#$Show = Get-TvShowID -Name Arrow
#$Season = Get-TvShowSeasons -ID (Get-TvShowID -Name Arrow) -Season 01
#$Episode = Get-TvShowEpisode -ID (Get-TvShowID -Name Arrow) -Season 01 -Episode 04
