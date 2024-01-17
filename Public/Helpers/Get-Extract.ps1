function Get-extract{
    $extractinfo = [System.Collections.Generic.List[object]]::New()
    $extractObject = [PSCustomObject]@{
        '7zipinstalled' = $null
        archiverProgram = $null
    }

    # Checking if 7zip or WinRAR are installed
    # Check 7zip install path on registry
    $7zipinstalled = $false 
    if ((Test-path HKLM:\SOFTWARE\7-Zip\) -and ([bool]((Get-itemproperty -Path "HKLM:\SOFTWARE\7-Zip").Path)) -eq $true) {
        RMM-Msg "7zip is Installed"
        $7zpath = Get-ItemProperty -path  HKLM:\SOFTWARE\7-Zip\ -Name Path
        $7zpath = $7zpath.Path
        $7zpathexe = $7zpath + "7z.exe"
        if ((Test-Path $7zpathexe) -eq $true) {
            $extractObject.archiverProgram = $7zpathexe
            $extractObject.'7zipinstalled' = $true 
        }    
    }
    else {
        RMM-Msg "Sorry, but it looks like you don't have a supported archiver." -messagetype Verbose
        Write-Host ""
        # Download and silently install 7-zip if the user presses y
        $7zip = "https://www.7-zip.org/a/7z2301-x64.exe"
        $output = "$folder\7Zip.exe"
        (New-Object System.Net.WebClient).DownloadFile($7zip, $output)
        Start-Process "$folder\7Zip.exe" -Wait -ArgumentList "/S"
        # Delete the installer once it completes
        Remove-Item "$folder\7Zip.exe"
        RMM-Msg "7zip Installed"  -messagetype Verbose
        $7zpath = Get-ItemProperty -path  HKLM:\SOFTWARE\7-Zip\ -Name Path
        $7zpath = $7zpath.Path
        $7zpathexe = $7zpath + "7z.exe"
        if ((Test-Path $7zpathexe) -eq $true) {
            $extractObject.archiverProgram = $7zpathexe
            $extractObject.'7zipinstalled' = $true 
        }    
    }
    $extractinfo.Add($extractObject)
    return $extractinfo 
}