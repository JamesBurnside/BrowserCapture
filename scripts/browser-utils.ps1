#Requires -Modules Selenium

$Driver

function startBrowser {
    $script:Driver = Start-SeChrome -Arguments @('Incognito','start-maximized')
}

function loadUrl {
    Param([Parameter(mandatory=$true)][string] $url)
    Enter-SeUrl $url -Driver $Driver
}

function listenForElement {
    Param([Parameter(mandatory=$true)][string] $elementName)
    Find-SeElement -Driver $Driver -Wait -Timeout 10 -Name $elementName
}