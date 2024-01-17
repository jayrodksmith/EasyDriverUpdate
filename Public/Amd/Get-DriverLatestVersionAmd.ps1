function Get-DriverLatestVersionAmd {
    param (
        [string]$amddriverdetails = "https://videocardz.com/sections/drivers" # URL to check for driver details
    )
    $response = Invoke-WebRequest -Uri $amddriverdetails -UseBasicParsing
    RMM-Msg "Checking $amddriverdetails for driver details" 
    $matches = [regex]::Matches($response, 'href="([^"]*https://videocardz.com/driver/amd-radeon-software-adrenalin[^"]*)"')
    $link = $matches.Groups[1].Value
    RMM-Msg "Checking $link for latest driver details" 
    $response = Invoke-WebRequest -Uri $link -UseBasicParsing
    $latestversion = [regex]::Match($response, "Download AMD Radeon Software Adrenalin (\d+\.\d+\.\d+)").Groups[1].Value
    $matches = [regex]::Matches($response, 'href="([^"]*https://www.amd.com/en/support/kb/release-notes[^"]*)"')
    $link = $matches.Groups[1].Value
    RMM-Msg "Checking $link for latest driver download url"
    Start-Sleep -Seconds 10
    $response = Invoke-RestMethod -Uri $link
    $matches = [regex]::Matches($response, 'href="([^"]*https://drivers.amd.com/drivers/whql-amd-software-[^"]*)"')
    $driverlink = $matches.Groups[1].Value
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