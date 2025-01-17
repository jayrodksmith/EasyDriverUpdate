function Get-DriverLatestVersionAmd {
    param (
        [string]$amddriverdetails = "https://gpuopen.com/version-table/", # URL to check for driver details
        [string]$amddriverdetails2 = "https://gpuopen.com/version-table/", # URL to check for driver details
        [string]$amddriverdetails3 = "https://gpuopen.com/version-table/" # URL to check for driver details
    )
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    $response = Invoke-WebRequest -Method Get -Uri $amddriverdetails -UseBasicParsing
    RMM-Msg "Checking $amddriverdetails for driver details" 
    $responselinks = $response.links
    # Use Select-String to find the line containing the URL
    $line = $responselinks | Select-String -Pattern "https://www.amd.com/en/resources/support-articles/release-notes" | Select-Object -First 1
    $latestversion = $line.ToString() -replace ".*data-content='([^']*)'.*", '$1'
    $useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    $referrer = "https://www.amd.com/en/support/graphics/amd-radeon-rx-7000-series/amd-radeon-rx-7900-series/amd-radeon-rx-7900xtx"
    # Extract the data-content value
    if ($line) {
        $latestversion = $line.ToString() -replace ".*data-content='([^']*)'.*", '$1'
        $releasenotes = $line.ToString() -replace ".*href='([^']*)'.*", '$1'
        $maxAttempts = 3
        $attempt = 1
        $retryDelay = 5  # Delay in seconds between retries
        do {
            try {
                $releasenotes = Invoke-WebRequest -Uri $releasenotes -TimeoutSec 10 -UserAgent $useragent -Headers @{'Refferer' = $referrer}
                break  # Exit the loop if successful
            } catch {
                Write-Verbose "Attempt $attempt failed to get driver download link: $_"
                Start-Sleep -Seconds $retryDelay
                $attempt++
            }
        } while ($attempt -le $maxAttempts)
    }
    
    # Check if matches were found
    if ($latestversion) {
        # Extract the desired values from the matches
        $latest_version_amd = $latestversion
        RMM-Msg "Latest AMD driver : $latest_version_amd" 
    } else {
        RMM-Error "No Version found." -messagetype Verbose
    }                      
    if ($driverlink) {
        $driverLink_amd = $driverlink
        RMM-Msg "Link AMD driver : $driverLink_amd"
    } else {
        RMM-Error "Download URL not found." -messagetype Verbose
    }
    return $latest_version_amd, $driverLink_amd
}
