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