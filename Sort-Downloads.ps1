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
    $defaultsource = "H:\Downloads"
    $tvdestination = "E:\TV"
    $moviedestination = "H:\Movies"
    $sampledestination = "H:\Downloads\Samples"
    $i = 0

    if(!($Source)) { $Source = $defaultsource }
    if(!($Since)) { $Since = 6 }

    $files = get-childitem -path $Source -Include *.avi, *.mp4, *.mkv, *.mpg, *.divx -Recurse

    ## Checking for logfile existence #Remove-item -path $loglocation
    $testpath = test-path "$loglocation"

    if($testpath -eq $false) {
        New-Item "$loglocation" -type file
        Add-Content $loglocation "$date > Created Logfile"
    }

    ## Strict Matches - Tv, Movie, Movie, Completed Movie, Completed Tv
    $regex1 = '(?<name>.*|\[720pMkv Com\]_)(?<season>S[0-9]?[0-9].E[0-9]?[0-9]|[0-9]x?[0-9]x[0-9]?[0-9]|Season [0-9] Episode [0-9]?[0-9])(?<crap>.*)(?<ext>\.mp4|\.mkv|\.avi)'
    $regex2 = '(?<name>^.*)(?<year>[1-2][089][0-9][0-9])(?<maybejunk>.*)(?<quality>(DVD(RIP|SCR)|WEBRIP|WEB|BRRip|HDRIP|BDRIP|HD.?TS|TELE|TELESYNC|BLURAY|CAM|TVRIP))(?<crap>.*)(?<ext>\.mp4|\.mkv|\.avi|\.mpg|\.divx)'
    #$regex3 = '(?<name>^.*)(?<maybejunk>.*)(?<quality>(DVD(RIP|SCR)|WEBRIP|WEB|BRRIP|HDRIP|BDRIP|HD.?TS|TELE|TELESYNC|BLURAY|CAM|TVRIP))(?<crap>.*)(?<year>[1-2][089][0-9][0-9])(?<ext>\.mp4|\.mkv|\.avi|\.mpg|\.divx)'
    $regex4 = '(?<name>^.*)(?<year>[1-2][089][0-9][0-9]).?(?<quality> \[(DVD(RIP|SCR)|WEBRIP|WEB|BRRIP|HDRIP|BDRIP|HD.?TS|TELE|TELESYNC|BLURAY|CAM|TVRIP|.?720P|.?1080P).*\])(?<ext>\.mp4|\.mkv|\.avi|\.mpg|\.divx)'
    $regex5 = '.*S[0-9][0-9]E[0-9][0-9](| - ?.*)(\.mp4|\.mkv|\.avi)'

    foreach($file in $files) {
        if($Match -ne $null -and $file.name -notmatch $Match) { Continue }
        Write-Host $file.name

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

            ## Getting rid of multipart movies
            if($filename -match "cd[0-9]" -or $filename -match "dis(c|k).?[0-9]" -or $filename -match "part.?[0-9]") {
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
                $tmdbname = $showname -replace "[1-2][0-9][0-9][0-9]",""

                ## Hopefully saves an API call
                if($tmdbname -ne $previousname) {
                    $tmdbid = Get-TvShowID -Name $tmdbname #$showsearch
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