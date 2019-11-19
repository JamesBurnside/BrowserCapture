#Requires -Modules Selenium

$Driver

function startBrowser {
    Param([string] $startUrl)
    $script:Driver = Start-SeChrome -StartUrl $startUrl -Arguments @('Incognito','start-maximized')
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

function listenForElementByName {
    Param([Parameter(mandatory=$true)][string] $elementName)
    Find-SeElement -Driver $Driver -Wait -Timeout 10 -Name $elementName
}

function listenForElementById {
    Param([Parameter(mandatory=$true)][string] $elementId)
    Find-SeElement -Driver $Driver -Wait -Timeout 10 -Id $elementId
}

function listenForElementByClass {
    Param([Parameter(mandatory=$true)][string] $elementClass)
    Find-SeElement -Driver $Driver -Wait -Timeout 10 -Class $elementClass
}
