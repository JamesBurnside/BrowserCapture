## Stitch videos together with ffmpeg

function printFileNameToConsole {
    Param ([string]$positionName, [string]$fileName)
    Write-Host $positionName -NoNewline
    Write-Host $fileName -ForegroundColor Yellow
}

function stitch {
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
        $output,

        $slowAsWell, # output a slowed version of the file as slowAsWell
        $slowAmount, # amount of times to slow the video down by, default is 5
        $slowOutputFile # o but for the slow
    )
    Write-Host "`n===Stitching files==="
    printFileNameToConsole -positionName "top-left video file: " -fileName $topleft
    printFileNameToConsole -positionName "top-right video file: " -fileName $topright
    printFileNameToConsole -positionName "bottom-left video file: " -fileName $bottomleft
    printFileNameToConsole -positionName "bottom-right video file: " -fileName $bottomright
    printFileNameToConsole -positionName "output file video name: " -fileName $output

    Write-Host "Stitching... (ffmpeg doing the work)"
    #ffmpeg -i $topleft -i $topright -i $bottomleft -i $bottomright -filter_complex "[0:v][1:v]hstack[t];[2:v][3:v]hstack[b];[t][b]vstack[v]" -map "[v]" -shortest $output
    Write-Host -ForegroundColor Green "Stitch complete"

    if ($slowAsWell -eq "true") {
        Write-Host "`n===Creating slowed down version===";
        $slowTimes = IF ($slowAmount) {$slowAmount} Else {"5"}
        $slowDownString = 'setpts='+$slowTimes+'*PTS'
        ffmpeg -i $output -filter:v $slowDownString $slowOutputFile
        Write-Host "Slowed down version complete: $slowOutputFile";
    }
}