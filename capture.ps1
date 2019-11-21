Param(
    # first website
    [Alias("u1")]
    [string] $url1,
    # first textforcapture
    [Alias("t1")]
    [string] $text1,

    # second website
    [Alias("u2")]
    [string] $url2,
    # second textforcapture
    [Alias("t2")]
    [string] $text2,

    # third website
    [Alias("u3")]
    [string] $url3,
    # third textforcapture
    [Alias("t3")]
    [string] $text3,

    # fourth website
    [Alias("u4")]
    [string] $url4,
    # fourth textforcapture
    [Alias("t4")]
    [string] $text4,

    # output file
    [Alias("o")]
    [string] $output
)

# Load scripts
$ScriptDirectory = (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) + "\scripts"
try {
    . ("$ScriptDirectory\browser-utils.ps1");
    . ("$ScriptDirectory\ffmpeg-utils.ps1");
    . ("$ScriptDirectory\stitch.ps1");
}
catch {
    Write-Error "Error while loading supporting PowerShell Scripts:`n$_.Exception.Message";
    exit;
}

function captureUrl {
    Param(
        [Parameter(mandatory=$true)][string] $url,
        [Parameter(mandatory=$true)][string] $output,
        [Parameter(mandatory=$true)][string] $overlayText
    )

    $StopWatch1 = New-Object -TypeName System.Diagnostics.Stopwatch

    # first open the browser and wait for selenium to have control
    startBrowser "https://www.microsoft.com/en-us/"

    $recordLength = 5
    $interimFileName_Raw = "$output.raw.mp4"
    
    Write-Host "Starting record. Saving output to: " -NoNewline
    Write-Host $interimFileName_Raw -ForegroundColor Yellow
    $StopWatch1.Start()
    $recordProcess = recordPrimaryMonitor -output $interimFileName_Raw -captureLength $recordLength

    Start-Sleep 2 # arbitrary delay for the screen recording to actually kick in

    Write-Host "Opening site: " -NoNewline
    Write-Host $url
    loadUrl -url $url

    # listenForElementById "exp1"
    # $ttfb = $StopWatch1.Elapsed.TotalSeconds;
    # Write-Host "ttfb: $ttfb"

    # listenForElementByClass "spotlight0"
    # $ttvr = $StopWatch1.Elapsed.TotalSeconds;
    # Write-Host "ttvr: $ttvr"

    # listenForElementByClass "spotlight5"
    # $tti = $StopWatch1.Elapsed.TotalSeconds;
    # Write-Host "tti: $tti"

    Write-Host "Waiting for recording to complete."
    Wait-Process -Id $recordProcess.Id
    # $totalElapsedTime = $StopWatch1.Elapsed.TotalSeconds;
    Write-Host "Recording complete." -ForegroundColor Green

    # Write-Host "Applying overlays"
    # $interimFileName_Overlays = $output + ".overlays.mp4"
    $recordProcess = applyOverlaysOnTopOfVideo -in $interimFileName_Raw -out "$output.mp4" -text $overlayText #update output once there are more steps
    Wait-Process -Id $recordProcess.Id
    Write-Host "Overlays complete." -ForegroundColor Green

    # clean up the browser
    closeBrowser

    # clean up timer
    $StopWatch1.Reset()
}

function capture2x2 {
    Param(
        [Parameter(mandatory=$true)][string] $interimFileDir,
        [Parameter(mandatory=$true)][string] $url1,
        [Parameter(mandatory=$true)][string] $text1,
        [Parameter(mandatory=$true)][string] $url2,
        [Parameter(mandatory=$true)][string] $text2,
        [Parameter(mandatory=$true)][string] $output
    )

    # set filenames for interim and final output files
    $fileName1 = $interimFileDir+"\left"
    $fileName2 = $interimFileDir+"\right"

    # capture website runs
    captureUrl $url1 $fileName1 $text1
    captureUrl $url2 $fileName2 $text2

    # stitch runs togather
    stitch2x2 -l "$fileName1.mp4" -r "$fileName2.mp4" -o $output
}

function capture4x4 {
    Param(
        [Parameter(mandatory=$true)][string] $interimFileDir,
        [Parameter(mandatory=$true)][string] $url1,
        [Parameter(mandatory=$true)][string] $text1,
        [Parameter(mandatory=$true)][string] $url2,
        [Parameter(mandatory=$true)][string] $text2,
        [Parameter(mandatory=$true)][string] $url3,
        [Parameter(mandatory=$true)][string] $text3,
        [Parameter(mandatory=$true)][string] $url4,
        [Parameter(mandatory=$true)][string] $text4,
        [Parameter(mandatory=$true)][string] $output
    )

    # set filenames for interim and final output files
    $fileName1 = $interimFileDir+"\top_left"
    $fileName2 = $interimFileDir+"\top_right"
    $fileName3 = $interimFileDir+"\bottom_left"
    $fileName4 = $interimFileDir+"\bottom_right"

    # capture website runs
    captureUrl $url1 $fileName1 $text1
    captureUrl $url2 $fileName2 $text2
    captureUrl $url3 $fileName3 $text3
    captureUrl $url4 $fileName4 $text4

    # stitch runs togather
    stitch4x4 -tl "$fileName1.mp4" -tr "$fileName2.mp4" -bl "$fileName3.mp4" -br "$fileName4.mp4" -o $output
}

function main {
    # Create output directory: C:\Users\<user>\Videos\SSRCaptures\<datetime>\
    $videosFolderPath = [Environment]::GetFolderPath("MyVideos");
    $SSRVideosCaptureFolder = $videosFolderPath+"\SSRCaptures";
    New-Item -ItemType Directory -Force -Path $SSRVideosCaptureFolder | out-null
    $outputDir = $SSRVideosCaptureFolder+"\"+[DateTime]::Now.ToString("yyyy_MM_dd HH_mm_ss");
    New-Item -ItemType Directory -Force -Path $outputDir | out-null
    Write-Host "Output Directory Created: $outputDir";

    $interimFileDir = $outputDir + "\interimFiles";
    New-Item -ItemType Directory -Force -Path $interimFileDir | out-null
    Write-Host "Interim Files Directory Created: $interimFileDir";

    # check if doing 2x2 or 4x4 or the default
    $captureOption = "4x4";
    If ($url1 -And $url2 -And $url3 -And $url4) {
        $captureOption = "4x4"
    } ElseIf ($url1 -And $url2) {
        $captureOption = "2x2";
    } Else {
        # doing the default 4x4, set the urls here:
        $url1 = "https://int.msn.com/ssr/?item=spalink:20191118.147&csr=true"
        $text1 = "CSR"

        $url2 = "https://int.msn.com/ssr/?item=spalink:20191118.147&prerender=true"
        $text2 = "SSR Prerender"

        $url3 = "https://int.msn.com/ssr/?item=spalink:20191118.147&delayed=true"
        $text3 = "DSSR Cold Cache"

        $url4 = "https://int.msn.com/ssr/?item=spalink:20191118.147&delayed=true&cache=warm"
        $text4 = "DSSR Warm Cache"
    }

    If (-Not $output) {
        $output = $outputDir+"\comparison.mp4"
    }

    If ($captureOption -eq "2x2") {
        capture2x2 $interimFileDir $url1 $text1 $url2 $text2 $output
    }
    ElseIf ($captureOption -eq "4x4") {
        capture4x4 $interimFileDir $url1 $text1 $url2 $text2 $url3 $text3 $url4 $text4 $output
    }

    Write-Host -ForegroundColor Green "`nProcess Complete. " -NoNewline
    Write-Host "Video file here: " -NoNewline
    Write-Host $output -ForegroundColor Yellow

    # open folder and highlight file
    explorer /select,$output
}

main;