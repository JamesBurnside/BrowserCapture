#Requires -Modules Selenium

$Driver

function startBrowser {
    $script:Driver = Start-SeChrome -Arguments @('Incognito','start-maximized')
}

function closeBrowser {
    Stop-SeDriver -Driver $Driver
}

function closeTab {
    Write-Error "closeTab Currently doesn't work..."
    $bodyElement = Find-SeElement -Driver $Driver -TagName "body";
    $ctrlKey = [OpenQA.Selenium.Keys]::Control;
    Send-SeKeys -Element $bodyElement -Keys $ctrlKey+"w"
}

function loadUrl {
    Param([Parameter(mandatory=$true)][string] $url)
    Enter-SeUrl $url -Driver $Driver
}

function listenForElement {
    Param([Parameter(mandatory=$true)][string] $elementName)
    Find-SeElement -Driver $Driver -Wait -Timeout 10 -Name $elementName
}
