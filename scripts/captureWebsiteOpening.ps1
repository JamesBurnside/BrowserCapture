## Stitch videos together with ffmpeg
Param(
    [Parameter(Position=0, mandatory=$true)]
    [string] $w, # website to capture
    $o, # output file
    $t,  # length of screen capture in seconds (max 59)
    $overlayText # text to write over the video
)

function recordPrimaryMonitor {
    Param ([string]$output, $captureLength, $overlayText)
    $monitorInfo = Get-WmiObject -Class Win32_DesktopMonitor | Select-Object ScreenWidth,ScreenHeight
    $captureSize = -join($monitorInfo.ScreenWidth,"x",$monitorInfo.ScreenHeight)
    $captureLength = -join("00:00:",$captureLength)
    $output1 = IF ($overlayText) {$output+".no_text.mp4"} Else {$output}
    ffmpeg -y -rtbufsize 100M -f gdigrab -t $captureLength -framerate 30 -s $captureSize -probesize 10M -draw_mouse 1 -i desktop -c:v libx264 -r 30 -preset ultrafast -tune zerolatency -crf 25 -pix_fmt yuv420p $output1

    if ($overlayText) {
        $fontFile = $PSScriptRoot+"\Gidole-Regular.ttf"
        ffmpeg -i $output1 -vf drawtext="fontfile='font.ttf': text='$overlayText': fontcolor=white: fontsize=110: box=1: boxcolor=black@0.7: boxborderw=5: x=(w-tw)/2: y=(h-th)*0.9" $output
    }
}

function printFileNameToConsole {
    Param ([string]$positionName, [string]$fileName)
    Write-Host $positionName -NoNewline
    Write-Host $fileName -ForegroundColor Yellow
}

function capture {
    Write-Host "Capturer Running..."`n
    $videosFolderPath = [Environment]::GetFolderPath("MyVideos");
    $outputFileName = IF ($o) {$o} Else {$videosFolderPath+"\recording_"+[DateTime]::Now.ToString("yyyy_MM_dd__HH_mm_ss")+".mp4"}
    $lengthOfCapture = IF ($t) {$t} Else {"5"}
    printFileNameToConsole -positionName "output file name: " -fileName $outputFileName

    $ScriptBlock = {
        Start-Sleep 1
        start "microsoft-edge:$args"
    }

    start "microsoft-edge:"
    Start-Sleep 1

    Start-Job -Name openWebsiteJob $ScriptBlock -ArgumentList $w
    recordPrimaryMonitor -output $outputFileName -captureLength $lengthOfCapture -overlayText $overlayText

    Wait-Job -Name openWebsiteJob
    Remove-Job *
}