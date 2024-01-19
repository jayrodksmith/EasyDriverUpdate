function Get-DownloadUrls {
    param (
        [string[]]$urllist,
        [string]$downloadLocation,
        [switch]$continueOnError
    )
    $totalUrls = $urllist.Length
    # Loop through each URL in the array and download the files using BitsTransfer
    for ($i = 0; $i -lt $totalUrls; $i++) {
        $url = $urllist[$i]

        # Write the progress message with the part number
        RMM-Msg "Downloading Part $($i + 1) of $totalUrls" -messagetype Verbose
        try {
            # Download the file using Start-BitsTransfer directly to the destination folder
            Start-BitsTransfer -Source $url -Destination $downloadLocation -Priority High -ErrorAction Stop
        } catch {
            # If an error occurs and the continueOnError switch is set, move on to the next URL
            if ($continueOnError) {
                RMM-Error "Error occurred while downloading: $($_.Exception.Message)" -messagetype Verbose
                
                $global:downloadError = $true
                continue
            } else {
                # If the continueOnError switch is not set, terminate the loop and function
                Start-sleep -Seconds 5
                RMM-Error "Error occurred while downloading: $($_.Exception.Message)" -messagetype Verbose
                RMM-Error "$url" -messagetype Verbose
                Set-Toast -Toasttitle "Download Error" -Toasttext "Error occurred : $($_.Exception.Message)" -UniqueIdentifier "default" -Toastenable $notifications
                $global:downloadError = $true
                RMM-Exit "1"
            }
        }
    }
    RMM-Msg "All files downloaded to $downloadlocation" -messagetype Verbose
    Start-sleep -Seconds 5
}