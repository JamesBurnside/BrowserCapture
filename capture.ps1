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

    # first open the browser and wait for selenium to have control
    startBrowser "https://www.microsoft.com/en-us/"

    $recordLength = 5
    $interimFileName_Raw = $output + ".raw.mp4"
    
    Write-Host "Starting record. Saving output to: " -NoNewline
    Write-Host $interimFileName_Raw -ForegroundColor Yellow
    $recordProcess = recordPrimaryMonitor -output $interimFileName_Raw -captureLength $recordLength

    Start-Sleep 2 # arbitrary delay for the screen recording to actually kick in
    Write-Host "Opening site: " -NoNewline
    Write-Host $url
    loadUrl -url $url

    Write-Host "Waiting for recording to complete."
    Wait-Process -Id $recordProcess.Id
    Write-Host "Recording complete." -ForegroundColor Green

    Write-Host "Applying overlays"
    $interimFileName_Overlays = $output + ".overlays.mp4"
    $recordProcess = applyOverlaysOnTopOfVideo -in $interimFileName_Raw -out $output -text $overlayText #update output once there are more steps
    Wait-Process -Id $recordProcess.Id
    Write-Host "Overlays complete." -ForegroundColor Green

    # clean up the browser
    closeBrowser
}

function main {
    # Create output directory: C:\Users\<user>\Videos\SSRCaptures\<datetime>\
    $videosFolderPath = [Environment]::GetFolderPath("MyVideos");
    $SSRVideosCaptureFolder = $videosFolderPath+"\SSRCaptures";
    New-Item -ItemType Directory -Force -Path $SSRVideosCaptureFolder | out-null
    $outputDir = $SSRVideosCaptureFolder+"\"+[DateTime]::Now.ToString("yyyy_MM_dd HH_mm_ss");
    New-Item -ItemType Directory -Force -Path $outputDir | out-null
    Write-Host "Output Directory Created: $outputDir";

    # set filenames for interim and final output files
    $fileName1 = $outputDir+"\top_left.mp4"
    $fileName2 = $outputDir+"\top_right.mp4"
    $fileName3 = $outputDir+"\bottom_left.mp4"
    $fileName4 = $outputDir+"\bottom_right.mp4"
    $filenameStitched = $outputDir+"\comparison.mp4"

    # capture website runs
    captureUrl "https://int.msn.com/ssr/?item=spalink:20191024.8&csr=true" $fileName1 "CSR"
    captureUrl "https://int.msn.com/ssr/?item=spalink:20191024.8&prerender=true" $fileName2 "SSR Prerender"
    captureUrl "https://int.msn.com/ssr/?item=spalink:20191024.8&delayed=true&prerender=true" $fileName3 "DSSR Prerender"
    captureUrl "https://int.msn.com/ssr/?item=spalink:20191024.8&delayed=true&cache=warm" $fileName4 "DSSR Warm Cache"

    # stitch runs togather
    stitch -tl $fileName1 -tr $fileName2 -bl $fileName3 -br $fileName4 -o $filenameStitched

    Write-Host -ForegroundColor Green "`nProcess Complete. " -NoNewline
    Write-Host "Video file here: " -NoNewline
    Write-Host $filenameStitched -ForegroundColor Yellow

    # open folder and highlight file
    explorer /select,$filenameStitched
}

main;