# BrowserCapture

## Description
Quick powershell scripts to capture different urls and stitch them side by side.  
This auto adds decals including overlay text and markers to indicate TTFB (time to first byte), TTVR (time to visually ready) and TTI (time to interactive).  
This uses ffmpeg for screen recording and video creating, and selenium web drivers for browser interaction.

## Prerequisits
* Ensure selenium package is installed:  
`> Install-Module Selenium`
* Ensure chrome is installed
* Ensure ffmpeg is installed (see below if not installed)
* Powershell version 5+

### Setting up ffmpeg
* Grab a latest build from: https://ffmpeg.zeranoe.com/builds/
* Save somewhere useful (don't leave it in the downloads folder)
* Add ffmpeg to your environment variables
  * Control Panel > System and Security > System > Advanced System Settings > Environment Variables > System Variables
  * Edit `Path` Variable > New
  * Enter the location of your ffmpeg binary e.g. C:\Program Files\ffmpeg\bin

## Run
* Clone repo
* run `./capture.ps1`

You may see the error:
``` shell
<PATH>\webdrivers\chromedriver.exe\chromedriver.exe does not exist. The driver can be downloaded at http://chromedriver.storage.googleapis.com/index.html"
```

Just make sure that the chromedriver.exe exists in the expected path.

### Change URLs and subtitle text to capture

Near the top of `capture.ps1` see:
``` ps
$availableCaptureOptions = (
    @([captureOption]::new("https://int.msn.com/render?entry=/bundles/v1/hub-ssr/20200211.76/node.index.js&mockpcs=true", "CSR")),
    @([captureOption]::new("https://int.msn.com/render?entry=/bundles/v1/hub-ssr/20200211.76/node.index.js&mockpcs=true&csrdelay=250", "SSR"))
    # Add these back in to do 4x4 capture
    # @([captureOption]::new("<site url>", "Capture 3")),
    # @([captureOption]::new("<site url>", "Capture 4"))
)
```

Change these urls and text strings to change the testing urls and subtitle text.

Include only 2 to do a 2x2 capture. Include 4 to do a 4x4 capture.

### Parameters

* Can choose to enable/disable perf markers with -perfmarkers (currently disabled by default)
  * tti is still in TODO

## Immediate Todos
* Fix perf markers
  * ttfb seems wrong for SSR
  * tti is not implemented
* Fix to work with Ege Chromium

## Possible Future Todos
* Perform n runs and choose median to minimize external factors
* Allow enabling/disabling individual perf markers

## Known Issues
* Currently getting recording area (i.e. primary monitor size) does not work over remote desktop
