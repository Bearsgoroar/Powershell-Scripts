<#888888 888888 888888 888888 888888 888888 888888 888888 888888 888888 888888 888888 888888 888888 888888 888888 888888 888888

.*88888b.                      d8b                   888                 d8888         d8b  .d888                   888    
888   Y88b                     Y8P                   888                d88888         Y8P d88P'                    888    
888    888                                           888               d88P888             888                      888    
888   d88P 888d888  .d88b.    8888  .d88b.   .d8888b 888888           d88P 888 888d888 888 888888  8888b.   .d8888b 888888 
8888888P'  888P'   d88''88b   '888 d8P  Y8b d88P'    888             d88P  888 888P'   888 888        '88b d88P'    888    
888        888     888  888    888 88888888 888      888            d88P   888 888     888 888    .d888888 888      888    
888        888     Y88..88P    888 Y8b.     Y88b.    Y88b.         d8888888888 888     888 888    888  888 Y88b.    Y88b.  
888        888      'Y88P'     888  'Y8888   'Y8888P  'Y888       d88P     888 888     888 888    'Y888888  'Y8888P  'Y888 
                               888                                                                                         
                              d88P                                                                                         
                            888P'                                                                                        

888888 888888 888888 888888 888888 888888 888888 888888 8888888 8888888 888888 888888 888888 888888 888888 888888 888888 888888

Parts:
    API Calls
        Get-TvShowID2
        Get-TvShowGeneralInfo
        Get-TvShowSeasonInfo
        Get-TvShowEpisodeInfo
        Find-TvShowMissings
        #Get-TvAiringToday
    Searching
        Add-WatchedTorrent
        Update-WatchedTorrents
        Update-WatchedTorrentsPriority
    Downloading
        Get-TorrentBETA
        #Download-Torrent
    Sorting
        Sort-Downloads


#>

       <#888 8888888b.  8888888        .d8888b.           888 888          
      d88888 888   Y88b   888         d88P  Y88b          888 888          
     d88P888 888    888   888         888    888          888 888          
    d88P 888 888   d88P   888         888         8888b.  888 888 .d8888b  
   d88P  888 8888888P'    888         888            '88b 888 888 88K      
  d88P   888 888          888         888    888 .d888888 888 888 'Y8888b. 
 d8888888888 888          888         Y88b  d88P 888  888 888 888      X88 
d88P     888 888        8888888        'Y8888P'  'Y888888 888 888  88888#> 

## Converts a TV Show into the corrosponding ID on themoviedb.org
function Get-TvShowID2() {
    param( [Parameter(Mandatory=$true)][string]$Name )
    
    $Apikey = Get-SecretInfo -Name "APIKEY_moviedb"

    if($Name -match "(1|2)[0-9][0-9][0-9]") { 
        $Year = $Matches[0] 
        $Name = $Name -replace $Matches[0]
    }
    if($Name -match "( UK| US| AU)") { 
        $Country = $Matches[0] -replace " ", "" -replace "UK", "GB"
        $Name = $Name -replace $Matches[0]
    }

    $Results = ((Invoke-RestMethod -uri "https://api.themoviedb.org/3/search/tv?api_key=$Apikey&language=en-US&region=AU&query=$Name").results)
    if($Results.count -ge "1") {
        $i = 0
        if($Year -ne $Null) {
            foreach($AirDate in ($Results.first_air_date)) {
                if($Year -match ($AirDate -replace "-.*", "")) { Return $Results.id[$i] }
                $i++
            }
        }

        if($Country -ne $Null) {
            foreach($OriginCountry in ($Results.origin_country)) {
                if($Country -match $OriginCountry) { Return $Results.id[$i] }
                $i++
            }
        }

        else {
            ## Use this area to query different API in the future.
            try { Return $Results.id[0] }
            catch { 
                $ErrorMessage = $_.Exception.Message
                Display-LargeText "Incorrect Name?" -Font "Shadow"
                Write-Host "Error: $ErrorMessage"
                Continue
            } 
        }
    }

    else {
        ## Use this area to query different API in the future.
        try { Return $Results.id[0] }
        catch { 
            $ErrorMessage = $_.Exception.Message
            Display-LargeText "Incorrect Name?" -Font "Shadow"
            Write-Host "Error: $ErrorMessage"
            Continue
        } 
    }
}

## Gets a count of total seasons and total episodes
function Get-TvShowGeneralInfo() {
    param(
        [Parameter(Mandatory=$False)][string]$ID,
        [Parameter(Mandatory=$False)][string]$Name
    )

    $Apikey = Get-SecretInfo -Name "APIKEY_moviedb"

    if(!($Name) -and !($ID)) { Write-Host "You must either include a -name or an -id" }
    if(!($ID)) { $ID = Get-TvShowID2 -Name $Name }

    Return (Invoke-RestMethod -uri ($("https://api.themoviedb.org/3/tv/placeholdertext?api_key=$Apikey&language=en-US&region=AU") -replace "placeholdertext","$ID")) 
}

## Gets a count of total seasons and total episodes
function Get-TvShowSeasonInfo() {
    param(
        [Parameter(Mandatory=$False)][string]$ID,
        [Parameter(Mandatory=$False)][string]$Name
    )

    $Apikey = Get-SecretInfo -Name "APIKEY_moviedb"

    if(!($Name) -and !($ID)) { Write-Host "You must either include a -name or an -id" }
    if(!($ID)) { $ID = Get-TvShowID2 -Name $Name }

    Return (Invoke-RestMethod -uri ($("https://api.themoviedb.org/3/tv/placeholdertext?api_key=$Apikey&language=en-US") -replace "placeholdertext","$ID")).seasons | Select season_number,episode_count
}

## Gets more detailed information about a specific episode
function Get-TvShowEpisodeInfo() {
    param(
        [Parameter(Mandatory=$False)][string]$ID,
        [Parameter(Mandatory=$False)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Season,
        [Parameter(Mandatory=$true)][string]$Episode
    )

    $Apikey = Get-SecretInfo -Name "APIKEY_moviedb"
    
    if(!($Name) -and !($ID)) { Write-Host "You must either include a -name or an -id" }
    if(!($ID)) { $ID = Get-TvShowID2 -Name $Name }

    Return (Invoke-RestMethod -uri ($("https://api.themoviedb.org/3/tv/$ID/season/$Season/episode/placeholdertext?api_key=$Apikey&language=en-US&region=AU") -replace "placeholdertext","$Episode"))
}

## Compares Moviedbs seasons/episodes against a local folders then tells you what episodes are missing
function Find-TvShowMissings() {
    param(
        [Parameter(Mandatory=$False)][string]$Name,
        [Parameter(Mandatory=$False)][string]$ID,
        [Parameter(Mandatory=$False)][string]$Directory = "E:\TV\" 
    )

    ## Dealing with local directory
    $LocalList = (Get-ChildItem -Path "$Directory$Name").Name -replace '(\.mp4|\.mkv|\.avi|\.mpg|\.divx|\.wmv|\.3gp)', '' -replace ' - .*', ''# -replace " (1|2)[0-9][0-9][0-9]", ""
    $LocalArray = {$LocalList}.Invoke()

    ## Going through the $LocalArray trying to find dud episodes and removing or combined episodes and expanding them
    foreach($Line in $LocalArray) {
        if($Line -notmatch ".*S[0-9][0-9]E[0-9][0-9].*") { 
            $LocalArray = $LocalArray -ne $Line
        }
        if($Line -match ".*S[0-9][0-9]E00.*") { 
            $LocalArray = $LocalArray -ne $Line 
        }
      
        if(($Line -match "(?<start>.*S[0-9][0-9])(?<ep1>E[0-9][0-9])(?<ep2>E[0-9][0-9])(?<therest>.*)") -eq $True) { 
            $Start = $matches['start']
            $Ep1 = $matches['ep1']
            $Ep2 = $matches['ep2']

            $LocalArray += "$Start$Ep1"
            $LocalArray += "$Start$Ep2"
            $LocalArray = $LocalArray -ne "$Start$Ep1$Ep2"
        }
    }

    ## Dealing with the API
    if(!($ID)) { $Seasons = Get-TvShowSeasonInfo -Name $Name }
    if($ID) { $Seasons = Get-TvShowSeasonInfo -ID $ID }

    $i = 1
    $MovieDBList = @()

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

     Return (Compare-Object $LocalArray $MovieDBList -IncludeEqual | Where SideIndicator -ne "==").InputObject
}

<# Gets a list of Tv Shows airing for todays date
function Get-TvAiringToday() {
    $Apikey = Get-SecretInfo -Name "APIKEY_moviedb"
    $Results = Invoke-RestMethod -uri "https://api.themoviedb.org/3/tv/airing_today?api_key=$Apikey&language=en-US" -ContentType "application/json" 
    $Result = $Results.results | Select id,name,popularity
    $Pages = $Results.total_pages
    $Array = @()
    $Array += $Result
    $i = 1

    while($i -ne $Pages) {
        $i++
        $Result = (Invoke-RestMethod -uri "https://api.themoviedb.org/3/tv/airing_today?api_key=$Apikey&language=en-US&page=$i" -ContentType "application/json").results | Select id,name,popularity
        $Array += $Result
    }

    foreach($Hash in $Array) {
        $Return = ([PSCustomObject]$Hash)
    }

    Return $Return | Format-Table -AutoSize
}
#>

<#d8888b.                                     888      d8b                   
d88P  Y88b                                    888      Y8P                   
Y88b.                                         888                            
 'Y888b.    .d88b.   8888b.  888d888  .d8888b 88888b.  888 88888b.   .d88b.  
    'Y88b. d8P  Y8b     '88b 888P'   d88P'    888 '88b 888 888 '88b d88P'88b 
      '888 88888888 .d888888 888     888      888  888 888 888  888 888  888 
Y88b  d88P Y8b.     888  888 888     Y88b.    888  888 888 888  888 Y88b 888 
 'Y8888P'   'Y8888  'Y888888 888      'Y8888P 888  888 888 888  888  'Y88888 
                                                                         888 
                                                                    Y8b d88P 
                                                                     'Y88P'#>


## Updates priority based on if the show is over
#$Priority = @{}
function Update-WatchedTorrents() {
    foreach($Name in (Get-ChildItem -Path "E:\Tv").name) {
        ## Doing some heavy lifting for shows that are finished and I have all the content
        if(((Get-TvShowGeneralInfo -Name $Name).status) -match ("Canceled|Ended")) {
            if((Find-TvShowMissings -Name $Name).Length -eq 0) { 
                Update-WatchedTorrentsPriority -Name $Name -NewPriority "Complete"
            }
        }

        ## Manually assigning priority to things I like
        else {
            $GetPriority = Read-Host "Priority for: $Name"
            switch($GetPriority) {
                1 { $GetPriority = "High" }
                2 { $GetPriority = "Medium" }
                3 { $GetPriority = "Low" }
            }

            Update-WatchedTorrentsPriority -Name $Name -NewPriority $GetPriority
        }
    }
}


function Update-WatchedTorrentsPriority() {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string][ValidateSet("High", "Medium", "Low", "Complete")]$NewPriority
    )

    $PriorityOldPrevious = $Priority.$Name.Previous
    $PriorityNewPrevious = $Priority.$Name.Current
    if($PriorityOldPrevious -eq $Null) { $PriorityOldPrevious = "Null" }

    if(($Priority).name -contains $Name) {
        $Priority.$Name.set_item("Previous", $PriorityNewPrevious)
        $Priority.$Name.set_item("Current", $NewPriority)
    }

    else {
        $Inner = @{"Current" = $NewPriority; "Previous" = $PriorityNewPrevious}
        $Priority.add("$Name", "$Inner")
    }
    
    Write-Host "Updated: $Name with $NewPriority. Previous: $PriorityOldPrevious"
}

function Get-TorrentBETA() {
    param(
        [Parameter(Mandatory=$false)][string]$Name,
        [Parameter(Mandatory=$false)][string]$Quality = "Skip",
        [Parameter(Mandatory=$false)][string]$Page
    )

## ConvertFrom-String is neat as hell but fiddlier than a horny necrophiliac in a morgue
$TemplateContent = @"
{[String]Episode_Name*:Jimmy Kimmel 2017 03 15 Matthew Perry 720p HDTV x264-CROOKS [eztv]} {Size:1.29 GB}{Released:10h 11m}{[Int]Seeds:44}
{[String]Episode_Name*:Are You The One S05E10 Reunion WEB x264-HEAT [eztv]} {Size:525.43 MB}{Released:29m}{[Int]Seeds:1000}
"@

    Switch($Page) {
        {$_ -ge 1} { $RequestLink = "https://eztv.ag/page_$Page" }
        default { $RequestLink = "https://eztv.ag/search/$Name"}
    }

    $TrackerLink = Invoke-WebRequest -Uri $RequestLink
    $FormatedResults = ($TrackerLink.AllElements | Where {$_.class -match "forum_header_border"}).innerTEXT | ConvertFrom-String -TemplateContent $TemplateContent
    $MagnetLinks = $TrackerLink.links | Where class -eq "magnet" | Select title,href

    $TvArray = @()
    foreach($Item in $FormatedResults) {
        $ItemTitle = $Item.Episode_Name -replace " \[eztv\].*$"
        
        
        foreach($MagnetLink in $MagnetLinks) {
            $MagnetTitle = $MagnetLink.title -replace " \[eztv\].*$"
            $MagnetMagnet = $MagnetLink.href
            if($ItemTitle -match $MagnetTitle) {
                $ResultQuality = $MagnetLink -match "720P|1080P|HDTV|WEB" 
                $ResultQuality = $Matches[0]

                if($ResultQuality -ne "$Quality" -and $Quality -ne "Skip") { Continue }

                $rc = New-Object PSObject
                $rc | Add-Member -type NoteProperty -name Seeds -Value $Item.Seeds
                $rc | Add-Member -type NoteProperty -name Episode_Name -Value $Item.Episode_Name
                $rc | Add-Member -type NoteProperty -name Quality -Value $ResultQuality
                $rc | Add-Member -type NoteProperty -name Size -Value $Item.Size
                $rc | Add-Member -type NoteProperty -name Release -Value $Item.Released
                $rc | Add-Member -type NoteProperty -name Magnet_Link -Value $MagnetMagnet

                $TvArray += $rc
                remove-variable rc
            }
        }
    }

    $TvArray# | Format-Table -AutoSize
}

<#88888b.                                  888                        888 d8b                   
888  'Y88b                                 888                        888 Y8P                   
888    888                                 888                        888                       
888    888  .d88b.  888  888  888 88888b.  888  .d88b.   8888b.   .d88888 888 88888b.   .d88b.  
888    888 d88''88b 888  888  888 888 '88b 888 d88''88b     '88b d88' 888 888 888 '88b d88P'88b 
888    888 888  888 888  888  888 888  888 888 888  888 .d888888 888  888 888 888  888 888  888 
888  .d88P Y88..88P Y88b 888 d88P 888  888 888 Y88..88P 888  888 Y88b 888 888 888  888 Y88b 888 
8888888P'   'Y88P'   'Y8888888P'  888  888 888  'Y88P'  'Y888888  'Y88888 888 888  888  'Y88888 
                                                                                            888 
                                                                                       Y8b d88P 
                                                                                        'Y88#>  
function Download-Torrent() {
    param(
        [Parameter(Mandatory=$true)][string]$MagnetLink
    )

    if($MagnetLink -notmatch "^magnet:.*") { Write-Host "Error: This doesn't appear to be a correctly formated Magnet Link" -ForegroundColor DarkYellow }
    Start $MagnetLink
}


 <#8888b.                   888    d8b                   
d88P  Y88b                  888    Y8P                   
Y88b.                       888                          
 'Y888b.    .d88b.  888d888 888888 888 88888b.   .d88b.  
    'Y88b. d88''88b 888P'   888    888 888 '88b d88P'88b 
      '888 888  888 888     888    888 888  888 888  888 
Y88b  d88P Y88..88P 888     Y88b.  888 888  888 Y88b 888 
 'Y8888P'   'Y88P'  888      'Y888 888 888  888  'Y88888 
                                                     888 
                                                Y8b d88P 
                                                 'Y88#>
## Functions
function Sort-Downloads() {
    param(
        [Parameter(Mandatory=$false)][string]$Match,
        [Parameter(Mandatory=$false)][string]$Source,
        [Parameter(Mandatory=$false)][string]$Since
    )

    ## Import Get-Torrent.ps1
    Import-Module "C:\PSScripts\Autoload\Get-Torrent.ps1" -Force

    $date = Get-Date -format yyyy-MM-dd
    $apikey = "0cfdef6c6f1639a3e095e60119603558"
    $loglocation = "E:\log.txt"
    $defaultsource = "E:\Torrents"
    $tvdestination = "E:\Tv"
    $moviedestination = "H:\Movies"
    $sampledestination = "H:\Downloads\Samples"
    $i = 0

    if(!($Source)) { $Source = $defaultsource }
    if(!($Since)) { $Since = 6 }

    $files = get-childitem -path $Source -Include *.avi, *.mp4, *.mkv, *.mpg, *.divx, *.wmv, *.3gp, *.rmvb -Recurse

    ## Checking for logfile existence #Remove-item -path $loglocation
    $testpath = test-path "$loglocation"

    if($testpath -eq $false) {
        New-Item "$loglocation" -type file
        Add-Content $loglocation "$date > Created Logfile"
    }

    ## Strict Matches - Tv, Movie, Movie, Completed Movie, Completed Tv
    # (.*)(((S|Season.?)[0-9]?[0-9].?(E|Episode.?)[0-9][0-9]|([0-9][0-9]|[0-9])x?[0-9][0-9]))(.*)  |[0-9]x?[0-9]x[0-9]?[0-9]
    $regex1 = '(?<name>^.*)(?<season>S[0-9]?[0-9].E[0-9]?[0-9]|Season [0-9] Episode [0-9]?[0-9])(?<crap>.*)(?<ext>\.mp4|\.mkv|\.avi|\.mpg|\.divx|\.wmv|\.3gp|\.rmvb)'
    $regex2 = '(?<name>^.*)(?<year>[1-2][089][0-9][0-9])(?<maybejunk>.*)(?<quality>(DVD(RIP|SCR)|WEBRIP|WEB|BRRip|HDRIP|BDRIP|HD.?TS|TELE|TELESYNC|BLURAY|CAM|TVRIP|1080p))(?<crap>.*)(?<ext>\.mp4|\.mkv|\.avi|\.mpg|\.divx|\.wmv|\.3gp|\.rmvb)'
    #$regex3 = '(?<name>^.*)(?<maybejunk>.*)(?<quality>(DVD(RIP|SCR)|WEBRIP|WEB|BRRIP|HDRIP|BDRIP|HD.?TS|TELE|TELESYNC|BLURAY|CAM|TVRIP))(?<crap>.*)(?<year>[1-2][089][0-9][0-9])(?<ext>\.mp4|\.mkv|\.avi|\.mpg|\.divx)'
    $regex4 = '(?<name>^.*)(?<year>[1-2][089][0-9][0-9]).?(?<quality> \[(DVD(RIP|SCR)|WEBRIP|WEB|BRRIP|HDRIP|BDRIP|HD.?TS|TELE|TELESYNC|BLURAY|CAM|TVRIP|.?720P|.?1080P).*\])(?<ext>\.mp4|\.mkv|\.avi|\.mpg|\.divx|\.wmv|\.3gp|\.rmvb)'
    $regex5 = '.*S[0-9][0-9]E[0-9][0-9](| - ?.*)(\.mp4|\.mkv|\.avi)'

    foreach($file in $files) {
        if($Match -ne $null -and $file.name -notmatch $Match) { Continue }
        #Write-Host $file.name

        if(((get-date) - $file.LastWriteTime) -gt (new-timespan -days $Since)) {
            $filename = $file.name
            $oldname = $file.fullname
            $extension = $file.Extension

            ## Getting rid of samples
            if($filename -match "sample") {
                Move-Item -literalpath $file.fullname -destination "$sampledestination\$i$filename"
                $i++
                Continue
            }

            ## Getting rid of multipart movies # -or $filename -match "part.?[0-9]"
            if($filename -match "cd[0-9]" -or $filename -match "dis(c|k).?[0-9]") { 
                Move-Item -literalpath $file.fullname -destination "H:\NewMovies\Combine\aaa\$filename"
                Continue
            }

            ## Searches and moves files already named correctly
            #if(($filename -match $regex4) -eq $true) { 
            #    Move-Item -literalpath $file.fullname -destination "$moviedestination\$filename"
            #    Continue
            #}
            #if(($filename -match $regex5) -eq $true) {
            #    Move-Item -literalpath $file.fullname -destination "$tvdestination\$file.basename\$filename"
            #    Continue
            #}

            ## Strict Matches - Tv, Movie
            $match1 = $filename -match $regex1
            $match2 = $filename -match $regex2

            ## Tv Matches
            if($match1 -eq $true) {
                $episode = $null
                $episodename = $null
                $showname = $matches['name'] -replace "\."," " -replace "_"," "

                ## Dealing with different show seasons formats S00E00, Season 00 Episode 00, 0x00 etc
                $showseason = $matches['season'] -replace "[a-z]","" -replace "\.","" -replace " ","" -replace "-",""
                $oldshowseason = $matches['season']
                
                if($showseason.length -le "3") { $showseason = "0$showseason" }

                $newseason = $showseason.Insert(2,'E').Insert(0,'S')

                ## Breaking season/show information into a readable format for the api
                $tmdbseason = $newseason -replace "[sS]","" -replace "[eE][0-9][0-9]",""
                $tmdbepisode = $newseason -replace "[eE]","" -replace "[sS][0-9][0-9]",""
                $tmdbname = $showname# -replace "[1-2][0-9][0-9][0-9]",""

                ## Hopefully saves an API call
                if($tmdbname -ne $previousname) {
                    $tmdbid = Get-TvShowID2 -Name $tmdbname #$showsearch
                    $newshowname = (Get-Culture).TextInfo.ToTitleCase($showname.trim())
                }
    
                $episodename = Get-TvShowEpisode -ID $tmdbid -Season $tmdbseason -Episode $tmdbepisode #$episode.name
                
                $previousname = $tmdbname
                $newname = "$newshowname $newseason"

                ## Checks for episode name and if not null appends the episode name to the end of the filename
                if($episodename -ne $null) {
                    $newname = "$newshowname $newseason - $episodename" -replace "\."," "
                }

                ## Filtering out characters that Windows hates
                $newname = $newname -replace "&","and" -replace ":"," -" -replace "<","(" -replace ">",")" -replace "\?","" -replace "\*","" -replace "  "," "

                ## Fix for shitty shownames like Agents of Shield
                if($newname -match "Agents of S H I E L D") {
                    $newname = $newname -replace "(Marvels |^)Agents of S H I E L D", "Marvels Agents of S.H.I.E.L.D"
                    #This is for new directories
                    $newshowname = $newshowname -replace "(Marvels |^)Agents of S H I E L D", "Marvels Agents of S.H.I.E.L.D" 
                }

                ## Moves file to correct folder in $destination
                if((test-path "$tvdestination\$newshowname") -eq $false) {
                    New-Item "$tvdestination\$newshowname" -type directory
                    Add-Content $loglocation "$date + Created directory $newshowname"
                }
        
                Add-Content $loglocation "$date > Oldname is: $oldname"
                Add-Content $loglocation "           > Newname is: $newname"

                Write-Host "$oldname >> $tvdestination\$newshowname\$newname$extension"
                Send-TelegramMessage -ToChatID "189580711" -Message "Sorted: $newname"

                Move-Item -literalpath $file.fullname -destination "$tvdestination\$newshowname\$newname$extension"

                ## Sleeps for x seconds as the api is rate limited to 40 requests every 10 seconds
                Start-Sleep 2
                Continue
            }

            if($match2 -eq $true) { 
                $name = $matches['name'].trim() -replace "\."," " -replace "_"," " -replace "\[","" -replace "\]","" -replace "\(","" -replace "\)","" -replace "{","" -replace "}",""
                $year = $matches['year'].trim()
                $quality = $matches['quality'].ToUpper() -replace "^","[" -replace "$", "]"
                $crap = $matches['crap'].trim().ToUpper()
                $maybejunk = $matches['maybejunk'].trim().ToUpper() -replace "\."," " -replace "_"," " -replace "\[","" -replace "\]","" -replace "\(","" -replace "\)",""
                $edition = ''

                if($maybejunk -match "720p") { $quality = "$quality $maybejunk" }
                if($year -match "1080") { 
                    $quality = "$quality $year" -replace "^[0-9][0-9][0-9][0-9] ","" 
                    $year = ''
                }
                if($maybejunk -match "director") { $edition = "[Directors Cut]" }
                if($maybejunk -match "edition") { $edition = "[$maybejunk]" }
                if($quality -eq "[]") { $quality = $null }

                $newishname = "$name $year $quality$edition" -replace "  "," " -replace "720P ", "720P" -replace "1080", "1080P"
                $newname = (Get-Culture).TextInfo.ToTitleCase($newishname.trim())
        
                Add-Content $loglocation "$date > Oldname is: $oldname"
                Add-Content $loglocation "           > Newname is: $newname$extension"
                Add-Content $loglocation "           > Maybe junk: $maybejunk"

                Move-Item -literalpath $file.fullname -destination "$moviedestination\$newname$extension"
            }
        }
    }
}

<#88888888                                              888 
888                                                     888 
888                                                     888 
8888888    88888b.   .d88b.   8888b.   .d88b.   .d88b.  888 
888        888 '88b d88P'88b     '88b d88P'88b d8P  Y8b 888 
888        888  888 888  888 .d888888 888  888 88888888 Y8P 
888        888  888 Y88b 888 888  888 Y88b 888 Y8b.      '  
8888888888 888  888  'Y88888 'Y888888  'Y88888  'Y8888  888 
                         888               888              
                    Y8b d88P          Y8b d88P              
                     'Y88P'            'Y88#>

function Start-ProjectArtifact() {
    $Watchlist = "Marvels Iron Fist"#Get-TorrentWatchlist
    foreach($TvShow in $Watchlist) {
        #$TvShow = "Marvels Iron Fist"
        $Torrents = Get-TorrentBETA -Name $TvShow
        $Missing = Find-TvShowMissings -Name "$TvShow"

        foreach($Torrent in $Torrents) {
            $Regex = $Torrent.Episode_Name -match "(?<NameAndSeason>^.*S[0-9]?[0-9].E[0-9]?[0-9]|Season [0-9] Episode [0-9]?[0-9]).*"
            $MatchedName = $Matches['NameAndSeason']
            if($Missing -contains $MatchedName) {
                Download-Torrent -MagnetLink $Torrent.Magnet_link
                $Torrent.Magnet_link
                Start-Sleep -Seconds 5
            }
        }
    }
}

#Start-ProjectArtifact
