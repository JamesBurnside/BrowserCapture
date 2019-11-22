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

### Parameters
* Can choose which of the following to capture (captures all by default, must choose two or four):
  * -csr (client side rendering)
  * -ssr (server side rendered, precached)
  * -dssrcold (delayed server side rendered with a cold cache)
  * -dssrwarm (delayed server side rendered with a warm cache)

* Can choose to enable/disable perf markers with -perfmarkers (currently disabled by default)
  * tti is still in TODO

## Immediate Todos
* Fix perf markers
  * ttfb seems wrong for SSR
  * tti is not implemented

## Possible Future Todos
* Perform n runs and choose median to minimize external factors
* Allow enabling/disabling individual perf markers

## Known Issues
* Currently getting recording area (i.e. primary monitor size) does not work over remote desktop