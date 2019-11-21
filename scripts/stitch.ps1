## Stitch videos together with ffmpeg

function printFileNameToConsole {
    Param ([string]$positionName, [string]$fileName)
    Write-Host $positionName -NoNewline
    Write-Host $fileName -ForegroundColor Yellow
}

function stitch2x2 {
    Param(
        # left file in 4x4
        [Parameter(Mandatory=$true)]
        [Alias("l")]
        $left,
        # top right file in 4x4
        [Parameter(Mandatory=$true)]
        [Alias("r")]
        $right,
        # output file
        [Parameter(Mandatory=$true)]
        [Alias("o")]
        $output
    )

    Write-Host "`n===Stitching files==="
    printFileNameToConsole -positionName "left video file: " -fileName $left
    printFileNameToConsole -positionName "right video file: " -fileName $right
    printFileNameToConsole -positionName "output file video name: " -fileName $output

    Write-Host "Stitching..."
    ffmpeg -loglevel error -i $left -i $right -filter_complex hstack -shortest $output
    Write-Host -ForegroundColor Green "Stitch complete"
}

function stitch4x4 {
    Param(
        # top left file in 4x4
        [Parameter(Mandatory=$true)]
        [Alias("tl")]
        $topleft,
        # top right file in 4x4
        [Parameter(Mandatory=$true)]
        [Alias("tr")]
        $topright,
        # bottom left file in 4x4
        [Parameter(Mandatory=$true)]
        [Alias("bl")]
        $bottomleft,
        # bottom right file in 4x4
        [Parameter(Mandatory=$true)]
        [Alias("br")]
        $bottomright,
        # output file
        [Parameter(Mandatory=$true)]
        [Alias("o")]
        $output
    )
    Write-Host "`n===Stitching files==="
    printFileNameToConsole -positionName "top-left video file: " -fileName $topleft
    printFileNameToConsole -positionName "top-right video file: " -fileName $topright
    printFileNameToConsole -positionName "bottom-left video file: " -fileName $bottomleft
    printFileNameToConsole -positionName "bottom-right video file: " -fileName $bottomright
    printFileNameToConsole -positionName "output file video name: " -fileName $output

    Write-Host "Stitching... (ffmpeg doing the work)"
    ffmpeg -loglevel error -i $topleft -i $topright -i $bottomleft -i $bottomright -filter_complex "[0:v][1:v]hstack[t];[2:v][3:v]hstack[b];[t][b]vstack[v]" -map "[v]" -shortest $output
    Write-Host -ForegroundColor Green "Stitch complete"
}