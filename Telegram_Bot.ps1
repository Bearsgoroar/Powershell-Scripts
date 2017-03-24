function Start-TelegramBot() {
    ## Forked from https://github.com/JuanPotato/Powershell-Telegram-Bot/blob/master/bot.ps1
    
    param(
        [Parameter(Mandatory=$false)][string]$Avatar,
        [Parameter(Mandatory=$false)][string]$BotName = (Invoke-RestMethod -Uri $GetMeLink -Method Post -ContentType 'application/json').result.username,
        [Parameter(Mandatory=$false)][string]$BotID = (Invoke-RestMethod -Uri $GetMeLink -Method Post -ContentType 'application/json').result.id,
        [Parameter(Mandatory=$false)][switch]$SupressKeepAliveMessage
    )

    $Botkey = Get-SecretInfo -Name "bearsgobot_api"

    $GetMeLink = "https://api.telegram.org/bot$Botkey/getMe"
    $SendMessageLink = "https://api.telegram.org/bot$Botkey/sendMessage"
    $ForwardMessageLink = "https://api.telegram.org/bot$Botkey/forwardMessage"
    $SendPhotoLink = "https://api.telegram.org/bot$Botkey/sendPhoto"
    $SendAudioLink = "https://api.telegram.org/bot$Botkey/sendAudio"
    $SendDocumentLink = "https://api.telegram.org/bot$Botkey/sendDocument"
    $SendStickerLink = "https://api.telegram.org/bot$Botkey/sendSticker"
    $SendVideoLink = "https://api.telegram.org/bot$Botkey/sendVideo"
    $SendLocationLink = "https://api.telegram.org/bot$Botkey/sendLocation"
    $SendChatActionLink = "https://api.telegram.org/bot$Botkey/sendChatAction"
    $GetUserProfilePhotosLink = "https://api.telegram.org/bot$Botkey/getUserProfilePhotos"
    $GetUpdatesLink = "https://api.telegram.org/bot$Botkey/getUpdates"
    $SetWebhookLink = "https://api.telegram.org/bot$Botkey/setWebhook"

    $Offset = 0

    Write-Host "Starting $BotName[$BotID]"  -ForegroundColor Green -BackgroundColor Black

    while($True) {
        ## Date for Timestamps in console for received messages
        $Date = Get-Date -Format "yyyy-MM-dd hh:mm:ss"
    
        ## Like IRC
        if(!($SupressKeepAliveMessage)) { 
            if($PingPong -eq 1) { Write-Host "Pong" -ForegroundColor Red; $PingPong = 0 }
            else { Write-Host "Ping" -ForegroundColor Green; $PingPong = 1 }
        }
    
        ## Request to API
        $JSON = Invoke-RestMethod -Uri $GetUpdatesLink -Body (ConvertTo-Json @{offset=$Offset}) -Method Post -ContentType 'application/json'
        
        ## If Message length -gt 0 then there is a message to be read
	    $MessageLength = $JSON.result.length
	    $i = 0
        
        ## Reading Messages
	    while ($i -lt $MessageLength) {
            $Offset = $JSON.result[$i].update_id + 1
        
            ## Breaking out things to make it easier to read
            $ParseMessage = $JSON.result[$i].message
            $FromChatID = $ParseMessage.chat.id # In channels resolves to channel id, in private chat resolves to UserID
            $FromUserID = $ParseMessage.from.id
            $FromUserName = $ParseMessage.from.username
            $Text = $ParseMessage.text
            
            ## Custom Text colours for specific people
            $UserColourArray = @{
                "Bearsgoroar" = "Gray"
                "bearsgobot"  = "Cyan"
                "Static_void" = "Green"
                "ThePengwin"  = "Yellow"
                "Ullarah"     = "Magenta"
            }

            if(($UserColourArray).contains($FromUserName)) { $UserTextColour = $UserColourArray.$FromUserName}
            if(!($UserColourArray).contains($FromUserName)) { 
                $RandomColour = Get-Random -Input ([Enum]::GetValues([System.ConsoleColor]))
                $UserColourArray.add("$FromUserName", "$RandomColour")
                $UserTextColour = $UserColourArray.$FromUserName
            }

            ## Write received messages to console
            Write-Message -Type "Bot" -Text "$Text" -Username "$FromUserName[$FromUserID]" -UsernameColour $UserTextColour
        
            ## Check for keywords and respond
            ## Greeting
            if($Text -match "(Hello|Hi|Howdy|Greetings|Hey).*") { Send-TelegramMessage -ToChatID $FromChatID -ToChatUser $FromUserName -Message "Hey $FromUserName! How are you today?" }
            if($Text -match ".*(Repeat after me:).*") { Send-TelegramMessage -ToChatID $FromChatID -ToChatUser $FromUserName -Message ($Text -replace "Repeat after me:", "")  }

            ## TV List
            if($Text -match "List TV Shows") { 
                $TvShows = (Get-ChildItem E:\TV).Name
                Send-TelegramMessage -ToChatID $FromID -ToChatUser $FromUser -Message "$TvShows"
            }
        
		    $i++
	    }

	    Start-Sleep -s 2
    }
}

function Send-TelegramMessage(){
    param(
        [Parameter(Mandatory=$true)][string]$ToChatID = (Get-SecretInfo -Name "telegram_chat_id"),
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$false)][string]$ToChatUser = "Unknown",
        [Parameter(Mandatory=$false)][string]$Date = (Get-Date -Format "yyyy-MM-dd hh:mm:ss")
    )

    if(!($Botkey)) { $Botkey = Get-SecretInfo -Name "bearsgobot_api" }
    $GetMeLink = "https://api.telegram.org/bot$Botkey/getMe"
    $SendMessageLink = "https://api.telegram.org/bot$Botkey/sendMessage"

    if(!($BotName)) {
        $GetMeInfo = (Invoke-RestMethod -Uri $GetMeLink -Method Post -ContentType 'application/json').result
        $BotName = $GetMeInfo.username
        $BotID = $GetMeInfo.id
    }

    ## Lazy newline on double space
    $Message = $Message -replace "  ", "`n"

    $Body = @{
        chat_id = "$ToChatID"
        text = $Message
    } | ConvertTo-Json

    $Data = Invoke-RestMethod -Uri $SendMessageLink -Body $Body -Method Post -ContentType 'application/json'
    
    Write-Message -Type "Bot" -Text "$Message" -Username "$BotName[$BotID]" -UsernameColour Cyan
}
