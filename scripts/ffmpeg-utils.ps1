
function startInNewProc {
    Param ([Parameter(mandatory=$true)][string]$cmd)
    return Start-Process powershell -NoNewWindow -PassThru $cmd
}

function recordPrimaryMonitor {
    Param (
        [Parameter(mandatory=$true)][string]$output,
        [Parameter(mandatory=$true)][string]$captureLength
    )
    $monitorInfo = Get-WmiObject -Class Win32_DesktopMonitor | Select-Object ScreenWidth,ScreenHeight
    $captureSize = -join($monitorInfo.ScreenWidth,"x",$monitorInfo.ScreenHeight)
    $captureLength = -join("00:00:",$captureLength)
    return startInNewProc -cmd "ffmpeg -y -loglevel error -rtbufsize 100M -f gdigrab -t $captureLength -framerate 30 -s $captureSize -probesize 10M -draw_mouse 1 -i desktop -c:v libx264 -r 30 -preset ultrafast -tune zerolatency -crf 25 -pix_fmt yuv420p \`"$output\`""
}

function applyOverlaysOnTopOfVideo {
    Param(
        [Parameter(mandatory=$true)][string] $in,
        [Parameter(mandatory=$true)][string] $out,
        [string] $text
    )

    $assetsFolder = $PSScriptRoot+"\..\assets";

    if($text) {
        $fontDir = $assetsFolder+"\fonts"
        $fontFile = $fontDir+"\Gidole-Regular.ttf";
        $fontFile = $fontFile -replace '[\\:]','\$&' # do some escaping
        startInNewProc "ffmpeg -loglevel error -i '$in' -vf drawtext=\`"fontfile='$fontFile': text='$text': fontcolor=white: fontsize=110: box=1: boxcolor=black@0.7: boxborderw=5: x=(w-tw)/2: y=(h-th)*0.9\`" '$out'"
    }
}