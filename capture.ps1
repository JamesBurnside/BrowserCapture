Param(
    # options to capture
    [bool] $perfmarkers = 0
)

class captureOption {
    [string]$url
    [string]$text

    captureOption([string]$url, [string]$text) {
        $this.url = $url
        $this.text = $text
    }
}

$availableCaptureOptions = (
    @([captureOption]::new("https://int.msn.com/render?entry=/bundles/v1/hub-ssr/20200211.76/node.index.js&mockpcs=true", "CSR")),
    @([captureOption]::new("https://int.msn.com/render?entry=/bundles/v1/hub-ssr/20200211.76/node.index.js&mockpcs=true&csrdelay=250", "SSR"))
    # Add these back in to do 4x4 capture
    # @([captureOption]::new("<site url>", "Capture 3")),
    # @([captureOption]::new("<site url>", "Capture 4"))
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

    $recordLength = 4
    $interimFileName_Raw = "$output.raw.mp4"

    Write-Host "Starting record. Saving output to: " -NoNewline
    Write-Host $interimFileName_Raw -ForegroundColor Yellow

    $recordProcess = recordPrimaryMonitor -output $interimFileName_Raw -captureLength $recordLength

    Start-Sleep 3 # arbitrary delay for the screen recording to actually kick in

    $StopWatch1.Start()
    $curTime = Get-Date -Format mmssfff
    $minutes = [double]($curTime.SubString(0,2))
    $seconds = [double]($curTime.SubString(2,2))
    $milliseconds = [double](-join("0.", $curTime.SubString(4,3)))
    $openUrlCallTime = $minutes*60 + $seconds + $milliseconds
    Write-Host "Opening site: " -NoNewline
    Write-Host $url
    loadUrl -url $url

    if ($perfmarkers) {
        listenForElementById "exp1"
        $ttfb = $StopWatch1.Elapsed.TotalSeconds;
        Write-Host "ttfb: $ttfb"

        listenForElementByClass "spotlight0"
        $ttvr = $StopWatch1.Elapsed.TotalSeconds;
        Write-Host "ttvr: $ttvr"

        # listenForElementByClass "spotlight5"
        # $tti = $StopWatch1.Elapsed.TotalSeconds;
        # Write-Host "tti: $tti"
    }

    Write-Host "Waiting for recording to complete."
    Wait-Process -Id $recordProcess.Id
    Write-Host "Recording complete." -ForegroundColor Green

    # clean up the browser
    closeBrowser

    # clean up timer
    $StopWatch1.Reset()

    $interimFileName_Raw_Esc = $interimFileName_Raw -replace '[\\]','\$&' # do some escaping
    Write-Host $interimFileName_Raw_Esc

    # strip to just mmss.fff (TODO: should do hours as well really...)
    $recordingStartTime = wmic datafile where "name='$interimFileName_Raw_Esc'" get creationdate | findstr /brc:[0-9]
    $recordingStartTime = $recordingStartTime.Remove(0,10) # get just minutes onwards
    $recordingStartTime = $recordingStartTime.SubString(0,8) # remove trailing except 3 millisecond digits
    $minutes = [double]($recordingStartTime.SubString(0,2))
    $seconds = [double]($recordingStartTime.SubString(2,2))
    $milliseconds = [double]("0."+$recordingStartTime.SubString(5,3))

    $recordingStartTime = $minutes*60 + $seconds + $milliseconds
    Write-Host "Recording started at: $recordingStartTime"
    Write-Host "Url call was at: $openUrlCallTime"

    $visualPrependBuffer = 0.3 # use the fact we have to trim the video to create a visual buffer rather than the video immediately starting at url launch

    $ffmpegSetupTime = $openUrlCallTime - $recordingStartTime - $visualPrependBuffer
    Write-Host "ffmpeg setup time was therefore: $ffmpegSetupTime"

    Write-Host "`nTrimming $ffmpegSetupTime (s) from video to compensate for ffmpeg startup time"
    $interimFileName_Trimmed = "$output.trimmed.mp4"
    ffmpeg -i $interimFileName_Raw -loglevel error -ss "00:00:$ffmpegSetupTime" -async 1 $interimFileName_Trimmed
    Write-Host "Trimming complete." -ForegroundColor Green

    Write-Host "`nApplying video overlays"
    If ($perfmarkers) {
        $tti = 1.5
        $ttfb_with_buffer = $ttfb + $visualPrependBuffer
        $ttvr_with_buffer = $ttvr + $visualPrependBuffer
        $tti_with_buffer = $tti + $visualPrependBuffer
        $ttfb = -join($ttfb,"s")
        $ttvr = -join($ttvr,"s")
        $tti = -join($tti,"s")
        $recordProcess = applyOverlaysOnTopOfVideo $interimFileName_Trimmed "$output.mp4" $overlayText "ttfb $ttfb" $ttfb_with_buffer "ttvr $ttvr" $ttvr_with_buffer "tti $tti" $tti_with_buffer
    } Else {
        $recordProcess = applyOverlaysOnTopOfVideo $interimFileName_Trimmed "$output.mp4" $overlayText
    }

    Wait-Process -Id $recordProcess.Id
    Write-Host "Overlays complete." -ForegroundColor Green
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

    # stitch runs together
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

    $output = $outputDir+"\comparison.mp4"

    # check if doing 2x2 or 4x4 or the default
    If ($availableCaptureOptions.Count -eq 2) {
        capture2x2 $interimFileDir $availableCaptureOptions[0].url $availableCaptureOptions[0].text $availableCaptureOptions[1].url $availableCaptureOptions[1].text $output
    }
    ElseIf (($availableCaptureOptions.Count -eq 4)) {
        capture4x4 $interimFileDir $availableCaptureOptions[0].url $availableCaptureOptions[0].text $availableCaptureOptions[1].url $availableCaptureOptions[1].text $availableCaptureOptions[2].url $availableCaptureOptions[2].text $availableCaptureOptions[3].url $availableCaptureOptions[3].text $output
    }
    Else {
        Write-Error "Number of capture options must be 2 or 4"
        return
    }

    # create a slow output also
    $slowOutputFile = "$output.slowed.mp4"
    $slowAmount = 7
    Write-Host "`n===Creating slowed down version===";
    $slowDownString = 'setpts='+$slowAmount+'*PTS'
    ffmpeg -loglevel error -i $output -filter:v $slowDownString $slowOutputFile
    Write-Host "Slowed down version complete: $slowOutputFile";

    Write-Host -ForegroundColor Green "`nProcess Complete. " -NoNewline
    Write-Host "Video file here: " -NoNewline
    Write-Host $slowOutputFile -ForegroundColor Yellow

    # open folder and highlight file
    explorer /select,$slowOutputFile
}

main;