function Get-DriverLatestVersionAmd {
    param (
        [string]$amddriverdetails = "https://www.amd.com/en/support/graphics/amd-radeon-rx-7000-series/amd-radeon-rx-7900-series/amd-radeon-rx-7900xtx" # URL to check for driver details
    )
    $response = Invoke-WebRequest -Method Get -Uri $amddriverdetails -UseBasicParsing
    RMM-Msg "Checking $amddriverdetails for driver details" 
    $responselinks = $response.links
    # Define your regex pattern to match the first part of the link
    $regexPattern = '(?s)href="(https://drivers\.amd\.com/drivers/whql-amd-software-[^"]*)'

    # Use [regex]::Match to find the first match
    $match = [regex]::Match($responselinks, $regexPattern)

    # Output the matched first part of the link if a match is found
    if ($match.Success) {
        $driverlink = $matches.Groups[1].Value
        $regexPattern = '\d+\.\d+\.\d+'
        $matchversion = [regex]::Match($driverlink, $regexPattern)
        $latestversion = $matchversion.Value
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