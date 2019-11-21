
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
        [string] $title,
        [string] $ttfb_text,
        [string] $ttfb_time,
        [string] $ttvr_text,
        [string] $ttvr_time,
        [string] $tti_text,
        [string] $tti_time
    )

    $assetsFolder = $PSScriptRoot+"\..\assets";

    $ffmpegCmd = "ffmpeg -loglevel error -i '$in' -vf \`""

    $fontDir = $assetsFolder+"\fonts"
    $fontFile = $fontDir+"\Gidole-Regular.ttf";
    $fontFile = $fontFile -replace '[\\:]','\$&' # do some escaping

    # video title
    if ($title) {
        $ffmpegCmd = -join($ffmpegCmd,
            "drawtext=",
                "fontfile='$fontFile': ",
                "text='$title': ",
                "fontcolor=white: fontsize=110: ",
                "box=1: boxcolor=black@0.7: boxborderw=5: ",
                "x=(w-tw)/2: y=(h-th)*0.9")
    }

    # ttfb
    if ($ttfb_text -And $ttfb_time) {
        $ffmpegCmd = -join($ffmpegCmd,
            ", drawtext=",
                "fontfile='$fontFile': ",
                "text='$ttfb_text': ",
                "enable='gte(t\,$ttfb_time)': ",
                "fontcolor=red: fontsize=90: ",
                "box=1: boxcolor=black@0.7: boxborderw=5: ",
                "x=(w-tw)*0.95: y=(h-th)*0.25")
    }

    # ttvr
    if ($ttvr_text -And $ttvr_time) {
        $ffmpegCmd = -join($ffmpegCmd,
            ", drawtext=",
                "fontfile='$fontFile': ",
                "text='$ttvr_text': ",
                "enable='gte(t\,$ttvr_time)': ",
                "fontcolor=red: fontsize=90: ",
                "box=1: boxcolor=black@0.7: boxborderw=5: ",
                "x=(w-tw)*0.95: y=(h-th)*0.5")
    }

    # tti
    if ($tti_text -And $tti_time) {
        $ffmpegCmd = -join($ffmpegCmd,
            ", drawtext=",
                "fontfile='$fontFile': ",
                "text='$tti_text': ",
                "enable='gte(t\,$tti_time)': ",
                "fontcolor=red: fontsize=90: ",
                "box=1: boxcolor=black@0.7: boxborderw=5: ",
                "x=(w-tw)*0.95: y=(h-th)*0.75")
    }

    $ffmpegCmd = -join($ffmpegCmd," \`" '$out'")
    Write-Host $ffmpegCmd
    startInNewProc $ffmpegCmd
}