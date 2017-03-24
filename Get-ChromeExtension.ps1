function Sort-PDFs {
    param(
        [Parameter(Mandatory=$False)][string]$Source = "C:\This\Is\Where\MyPdfs\Live",
        [Parameter(Mandatory=$False)][string]$Destination = "E:\This\Is\Their\NewHome",
        [Parameter(Mandatory=$False)][string]$Since = "10"
    )

    $Files = Get-ChildItem -path $Source -Include *.pdf -Recurse

    foreach($File in $Files) {
        if(((Get-Date) - $File.LastWriteTime) -gt (New-TimeSpan -Minutes $Since)) {
            Move-Item -LiteralPath $File.fullname -Destination (Join-Path $Destination $File.name)
        }
    }
}



Function Get-ChromeExtension {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    Get-ChildItem "\\$ComputerName\c$\users\*\appdata\local\Google\Chrome\User Data\Default\Extensions\*\*\manifest.json" -ErrorAction SilentlyContinue | % {
        $_.FullName -match 'users\\(.*?)\\appdata' | Out-Null
        Get-Content $_.FullName | ConvertFrom-Json | select @{n='ComputerName';e={$ComputerName}}, @{n='User';e={$Matches[1]}}, name, version
    }
}

# https://social.technet.microsoft.com/Forums/office/en-US/4f6815f1-2998-484c-a423-fe6507f1548c/powershell-script-to-fetch-logonlogoff-user-on-particular-server-getwinevent-geteventlog?forum=winserverpowershell

function Get-LogonHistory {
    param (
        [string]$Computer = $env:COMPUTERNAME,
        [int]$Days = 1
    )

    $filterXml = "
        <QueryList>
            <Query Id='0' Path='System'>
            <Select Path='System'>
                *[System[
			        Provider[@Name = 'Microsoft-Windows-Winlogon']
                    and
			        TimeCreated[@SystemTime >= '$(Get-Date (Get-Date).AddDays(-$Days) -UFormat '%Y-%m-%dT%H:%M:%S.000Z')']
                ]]
            </Select>
            </Query>
        </QueryList>
    "
    $ELogs = Get-WinEvent -FilterXml $filterXml -ComputerName $Computer
    
    # $ELogs = Get-EventLog System -Source Microsoft-Windows-WinLogon -After (Get-Date).AddDays(-$Days) -ComputerName $Computer

    if ($ELogs) {
        $(foreach ($Log in $ELogs) {
            switch ($Log.id) {
                7001 {$ET = 'Logon'}
                7002 {$ET = 'Logoff'}
                default {continue}
            }

            New-Object PSObject -Property @{
                Time = $Log.timecreated
                EventType = $ET
                User = (New-Object System.Security.Principal.SecurityIdentifier $Log.Properties.value.value).Translate([System.Security.Principal.NTAccount])
            }
        }) | sort time -Descending
    } else {
        Write-Host "Problem with $Computer."
        Write-Host "If you see a 'Network Path not found' error, try starting the Remote Registry service on that computer."
        Write-Host 'Or there are no logon/logoff events (XP requires auditing be turned on)'
    }
}
