# EasyDriverUpdate

## Synopsis

## Description
This module is a way to Update/Check/Log drivers for Nvidia Intel and AMD.
## Getting Started

```Powershell
Start-EasyDriverUpdate

```

### Prerequisites

### Installation of Module

```powershell
$githubrepo  = "jayrodksmith/EasyDriverUpdate"
$EasyDriverUpdaterepo = "https://github.com/$githubrepo"
$releases = "https://api.github.com/repos/$githubrepo/releases"
$EasyDriverUpdatelatestversion = (Invoke-WebRequest $releases | ConvertFrom-Json)[0].tag_name
$EasyDriverUpdateExtractionPath = (Join-Path -Path "C:\Program Files\WindowsPowerShell\Modules\EasyDriverUpdate" -ChildPath $EasyDriverUpdatelatestversion)
$EasyDriverUpdateDownloadZip = ('{0}/archive/main.zip' -f $EasyDriverUpdaterepo)
$EasyDriverUpdateDownloadFile = ('{0}\EasyDriverUpdate.zip' -f $ENV:Temp)
# Create the niaupdater folder if it doesn't exist 
    if (-not (Test-Path -Path $EasyDriverUpdateExtractionPath)) {
        $null = New-Item -Path $EasyDriverUpdateExtractionPath -ItemType Directory -Force
    } else {
        $null = Remove-Item -Recurse -Force -Path $EasyDriverUpdateExtractionPath
        $null = New-Item -Path $EasyDriverUpdateExtractionPath -ItemType Directory -Force
    }
Invoke-WebRequest -Uri $EasyDriverUpdateDownloadZip -OutFile $EasyDriverUpdateDownloadFile
Expand-Archive -Path $EasyDriverUpdateDownloadFile -DestinationPath $EasyDriverUpdateExtractionPath -Force
$extractedFolderPath = Join-Path -Path $EasyDriverUpdateExtractionPath -ChildPath "EasyDriverUpdate-Main"
# Move all files from the extracted folder to the root
Get-ChildItem -Path $extractedFolderPath | Move-Item -Destination $EasyDriverUpdateExtractionPath
# Optional: Remove the empty extracted folder
Remove-Item -Path $extractedFolderPath -Force
Remove-Item -Path $EasyDriverUpdateDownloadFile -Force
```

### Quick start with Module
```powershell
Import-Module EasyDriverUpdate

Get-Warranty
```
## Author
Jared Smith