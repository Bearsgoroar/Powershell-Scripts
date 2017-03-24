function GitScript() {
    param( 
        [Parameter(Mandatory=$true)][string]$Action,
        [Parameter(Mandatory=$false)][string]$Secondary
    )

    switch($Action) {
        {$_ -match "doshit"} { 
            git add . 2>&1 | Write-host
            git commit -am "$Secondary" 2>&1 | Write-host
            git push 2>&1 | Write-host
        }
        {$_ -match "startup"} { 
            git add . 2>&1 | Write-host
            git commit -am "Automatic update" 2>&1 | Write-host
            git push 2>&1 | Write-host
            git pull 2>&1 | Write-host
        }
        default { git $Command 2>&1 | Write-host }
    }
}