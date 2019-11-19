# Param(
#     # output file
#     [Alias("o")]
#     [string] $output,
#     # first website
#     [Alias("u1")]
#     [string] $url1,
#     # second website
#     [Alias("u2")]
#     [string] $url2,
#     # third website
#     [Alias("u3")]
#     [string] $url3,
#     # fourth website
#     [Alias("u4")]
#     [string] $url4
# )

# Load scripts
$ScriptDirectory = (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent) + "\scripts"
try {
    . ("$ScriptDirectory\browser-utils.ps1");
    . ("$ScriptDirectory\ffmpeg-utils.ps1");
    . ("$ScriptDirectory\stitch4x4.ps1");
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

    # set filenames for interim and final output files
    $fileName1 = $interimFileDir+"\top_left"
    $fileName2 = $interimFileDir+"\top_right"
    $fileName3 = $interimFileDir+"\bottom_left"
    $fileName4 = $interimFileDir+"\bottom_right"

    # capture website runs
    captureUrl "https://int.msn.com/ssr/?item=spalink:20191118.147&csr=true" $fileName1 "CSR"
    captureUrl "https://int.msn.com/ssr/?item=spalink:20191118.147&prerender=true" $fileName2 "SSR Prerender"
    captureUrl "https://int.msn.com/ssr/?item=spalink:20191118.147&delayed=true" $fileName3 "DSSR Cold Cache"
    captureUrl "https://int.msn.com/ssr/?item=spalink:20191118.147&delayed=true&cache=warm" $fileName4 "DSSR Warm Cache"

    # stitch runs togather
    $filenameStitched = $outputDir+"\comparison.mp4"
    stitch -tl "$fileName1.mp4" -tr "$fileName2.mp4" -bl "$fileName3.mp4" -br "$fileName4.mp4" -o $filenameStitched

    Write-Host -ForegroundColor Green "`nProcess Complete. " -NoNewline
    Write-Host "Video file here: " -NoNewline
    Write-Host $filenameStitched -ForegroundColor Yellow

    # open folder and highlight file
    explorer /select,$filenameStitched
}

main;