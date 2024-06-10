

function Start-EasyDriverUpdate {
    <#
        .SYNOPSIS
        Function to Start Easy Driver Update
    
        .DESCRIPTION
        This function will get check installed drivers and if any updates available online
    
        .EXAMPLE
        Start-EasyDriverUpdate -UpdateNvidia
        Start-EasyDriverUpdate -UpdateAmd
        Start-EasyDriverUpdate -UpdateIntel
        Start-EasyDriverUpdate -UpdateNvidia -Restart   // Will restart after updating

        .PARAMETER UpdateNvidia
        Update Nvidia Drivers
    
        .PARAMETER UpdateIntel
        Update Intel Drivers

        .PARAMETER UpdateAmd
        Update Amd Drivers
        
        .PARAMETER Restart
        Restart machine after updating drivers
        
        .PARAMETER Silent
        No Notfications

        Disable logging to file

        .PARAMETER RMMPlatform
        StandAlone or NinjaRMM support

        .PARAMETER Notifications
        Notfications Enable

        .PARAMETER Geforcedriver
        Studio or Game version of drivers for Gaming cards

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Switch]$UpdateNvidia,
        [Switch]$UpdateAmd,
        [Switch]$UpdateIntel,
        [Switch]$Restart,
        [Switch]$Silent,
        [ValidateSet('NinjaOne', 'Standalone')]
        [string]$RMMPlatform = "NinjaOne",
        [bool]$notifications = $false,
        [bool]$autoupdate = $false,
        [bool]$logging = $true,
        [ValidateSet('Studio', 'Game')]
        [string]$geforcedriver = "Studio"
    )
    ###############################################################################
    # Pre Checks
    ###############################################################################
    function Test-Administrator {  
        $user = [Security.Principal.WindowsIdentity]::GetCurrent();
        (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
    }
    if(Test-Administrator -eq $true){
        Write-Debug "EasyDriverUpdate running as admin"
    } else{
        Write-Warning "EasyDriverUpdate not running as Admin, run this script elevated or as System Context"
        exit 0
    }

    # If ran outside of NinjaRMM automation, will set to check and print driver info by default.
    # With no logging to ninja and no updating

    # Check if ninjarmm exists if rmmplatform set
    $ninjarmmcli = "C:\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe"
    $ninjarmminstalled = (Test-Path -Path $ninjarmmcli)
    if($RMMPlatform -eq "NinjaOne" -and $ninjarmminstalled -eq $false){
        Write-Warning "NinjaOne not installed, defaulting to Standalone"
        $RMMPlatform = 'Standalone'
    }
    if(!$UpdateNvidia){$UpdateNvidia = $false}
    if(!$UpdateAmd) {$UpdateAmd = $false}
    if(!$UpdateIntel) {$UpdateIntel = $false}
    if(!$Restart) {$Restart = $false}
    if($Silent -eq 'true'){$notifications = $false}

    ## Check if module is installed and disable notifications if not exist
    $modulelocation1 = "C:\Program Files\WindowsPowerShellCustom\Modules\EasyDriverUpdate\0.5.0\Private\Logging\resources\logos"
    $modulelocation2 = "C:\Program Files\WindowsPowerShell\Modules\EasyDriverUpdate\0.5.0\Private\Logging\resources\logos"
    if ((Test-Path -Path $modulelocation1) -eq $false){
        $notifications = $false
    } 
    if ((Test-Path -Path $modulelocation2) -eq $false){
        $notifications = $false
    } 

    ###############################################################################
    # Global Variable Setting
    ###############################################################################

    Set-Variable EasyDriverUpdatePath -Value (Join-Path -Path $ENV:ProgramData -ChildPath "EasyDriverUpdate") -Scope Global -option ReadOnly -Force
    Set-Variable logfilelocation -Value "$EasyDriverUpdatePath\logs" -Scope Global -option ReadOnly -Force
    Set-Variable logfile -Value "$logfilelocation\EasyDriverUpdate.log" -Scope Global -option ReadOnly -Force
    Set-Variable logdescription -Value "EasyDriverUpdate" -Scope Global -option ReadOnly -Force
    Set-Variable geforcedriver -Value $geforcedriver -Scope Global -option ReadOnly -Force
    Set-Variable notifications -Value $notifications -Scope Global -option ReadOnly -Force
    Set-Variable logging -Value $logging -Scope Global -option ReadOnly -Force

    ###############################################################################
    # NIA Installer
    ###############################################################################
    # Create the EasyDriverUpdate folder if it doesn't exist 
    if (-not (Test-Path -Path $EasyDriverUpdatePath)) {
        $null = New-Item -Path $EasyDriverUpdatePath -ItemType Directory -Force
    }
    if (-not (Test-Path -Path $logfilelocation)) {
        $null = New-Item -Path $logfilelocation -ItemType Directory -Force
    }
    ###############################################################################
    # Function - Logging
    ###############################################################################
    # Check if the folder exists
    if (-not (Test-Path -Path $logfilelocation -PathType Container)) {
        # Create the folder and its parent folders if they don't exist
        New-Item -Path $logfilelocation -ItemType Directory -Force | Out-Null
    }
    $Global:nl = [System.Environment]::NewLine
    $Global:ErrorCount = 0
    $global:Output = '' 
    ###############################################################################
    # Function - Notifications
    ###############################################################################
    if ($notifications -ne $false){
        Register-BurntToast
        $AppID = "EasyDriverUpdate.Notification"
        $AppDisplayName = "EasyDriverUpdate"
        $RootPath = Split-Path $PSScriptRoot -Parent -ErrorAction SilentlyContinue | Out-Null
        $AppIconUri = "$RootPath\Private\Logging\resources\logos\logo_ninjarmm_square.png"
        Register-NotificationApp -AppID $AppID -AppDisplayName $AppDisplayName -AppIconUri $AppIconUri
    }
    ###############################################################################
    # Main Script Starts Here
    ###############################################################################
    # Get GPU Info and print to screen
    RMM-Initilize
    Set-Variable gpuInfo -Value (Get-GPUInfo) -Scope Global -option ReadOnly -Force

    # Send GPU Info to RMM
    if($RMMPlatform -eq "NinjaOne"){
        Set-GPUtoNinjaRMM
    }
    # Cycle through updating drivers if required
    if($UpdateAmd -eq $true){ 
        $driverupdatesamd = Set-DriverUpdatesamd
        if($driverupdatesamd -ne "Updated"){
            Set-Toast -Toasttitle "Driver Check" -Toasttext "No new AMD drivers found" -UniqueIdentifier "nonew" -Toastenable $notifications
        }
        if($driverupdatesamd -eq "Updated"){
            $installstatus = "Updated"
        }
    }
    if($UpdateNvidia -eq $true){
        $driverupdatesnvidia = Set-DriverUpdatesNvidia
        if($driverupdatesnvidia -ne "Updated"){
            Set-Toast -Toasttitle "Driver Check" -Toasttext "No new Nvidia drivers found" -UniqueIdentifier "nonew" -Toastenable $notifications
        }
        if($driverupdatesnvidia -eq "Updated"){
            $installstatus = "Updated"
        }
    }
    if($UpdateIntel -eq $true){
        $driverupdatesintel = Set-DriverUpdatesintel
        if($driverupdatesintel -ne "Updated"){
            Set-Toast -Toasttitle "Driver Check" -Toasttext "No new Intel drivers found" -UniqueIdentifier "nonew" -Toastenable $notifications
        }
        if($driverupdatesintel -eq "Updated"){
            $installstatus = "Updated"
        }
    }
    $gpuInfo
    # Restart machine if required
    if($Restart -eq $true -and $installstatus -eq "Updated"){
        shutdown /r /t 30 /c "In 30 seconds, the computer will be restarted to finish installing GPU Drivers"
        RMM-Exit 0
    }

    if($Restart -eq $false -and $installstatus -eq "Updated"){
        Set-Toast -Toasttitle "Updating Drivers" -Toasttext "Finished installing drivers please reboot" -UniqueIdentifier "default" -Toastreboot -Toastenable $notifications
        RMM-Exit 0
    }

    RMM-Exit 0

    ###############################################################################
    # Main Script Ends Here
    ###############################################################################

    <## Example
    $Toastenable = $true
    Set-Toast -Toasttitle "Driver Update" -Toasttext "Finished installing nvidia drivers please reboot" -UniqueIdentifier "default" -Toastreboot -Toastenable $notifications
    Set-Toast -Toasttitle "Driver Update" -Toasttext "Finished installing nvidia drivers please reboot" -UniqueIdentifier "default" -Toastenable $notifications
    ##>
    }

function Get-GPUInfo {
<#
        .SYNOPSIS
        Function to Get GPU Info
    
        .DESCRIPTION
        This function will get check installed drivers
    
        .EXAMPLE
        Get-GPUInfo

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
    )    
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    RMM-Msg "Script Mode: `tChecking GPU Information" -messagetype Verbose
    Set-Toast -Toasttitle "Driver Check" -Toasttext "Checking for GPU drivers" -UniqueIdentifier "default" -Toastenable $notifications
    $cim_os = Get-CimInstance -ClassName win32_operatingsystem | select Caption 
    $cim_cpu = Get-CimInstance -ClassName Win32_Processor
    $cim_gpu = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -match "NVIDIA|AMD|Intel" }
    $gpu_integrated = @(
        "AMD Radeon (\d+)M Graphics",
        "Radeon \(TM\) Graphics",
        "AMD Radeon\(TM\) Graphics",
        "AMD Radeon\(TM\) R2 Graphics",
        "AMD Radeon\(TM\) Vega (\d+) Graphics",
        "AMD Radeon\(TM\) RX Vega (\d+) Graphics",
        "Intel\(R\) UHD",
        "Intel\(R\) HD",
        "Intel\(R\) Iris\(R\)"
    )
    $gpuInfo = [System.Collections.Generic.List[object]]::New()
    # GPU Reporting
    foreach ($gpu in $cim_gpu) {
        $gpuObject = [PSCustomObject]@{
            Name = $gpu.Name
            DriverInstalled = if ($gpu.Name -match "NVIDIA"){($gpu.DriverVersion.Replace('.', '')[-5..-1] -join '').insert(3, '.')}elseif($gpu.Name -notmatch "AMD"){$gpu.DriverVersion}else{$gpu.DriverVersion}
            DriverLatest = $null
            DriverUptoDate = $null
            DriverLink = $null
            DriverLink2 = $null
            Brand = if ($gpu.Name -match "Nvidia"){"NVIDIA"}elseif($gpu.Name -match "AMD"){"AMD"}elseif($gpu.Name -match "INTEL"){"INTEL"}elseif($gpu.Name -match "DisplayLink"){"DisplayLink"}else{"Unknown"}
            IsDiscrete = $null
            IsIntegrated = $null
            Processor = $null
            Generation = $null
            Resolution = if ($gpu.CurrentHorizontalResolution -and $gpu.CurrentVerticalResolution) {"$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)"}
        }
        $matchedPattern = $null  # Store the matched pattern for debugging
        # Detect if the adapter type matches any of the custom regex patterns for integrated GPUs
        foreach ($regex in $gpu_integrated) {
            if ($gpu.Name -match $regex) {
                $gpuObject.IsIntegrated = $true
                $matchedPattern = $regex  # Store the matched pattern for debugging
                $gpuObject.IsDiscrete = $false
                $gpuObject.Processor = $cim_cpu.Name
                break  # Exit the loop after the first match
            }
        }
        # Output debugging information
        RMM-Msg "GPU: $($gpu.Name)"
        if($matchedPattern) {RMM-Msg "Matched Pattern: $($matchedPattern)" -messagetype Verbose}
        if ($gpuObject.IsIntegrated -eq $null) {
                $gpuObject.IsIntegrated = $false
                $gpuObject.IsDiscrete = $true
        }
        $gpuInfo.Add($gpuObject)
    }
    # NVIDIA SECTION ##
    # Retrieve latest nvidia version if card exists
    $exists_nvidia = $gpuInfo | Where-Object { $_.Name -match "nvidia" }
    if($exists_nvidia){
        $latest_version_nvidia, $url, $rp_url = Get-driverlatestversionnvidia
    }  
    # Update the DriverLink for the NVIDIA device
    $gpuInfo | ForEach-Object {
        if ($_.Name -match "NVIDIA") {
            $_.DriverLatest = "$latest_version_nvidia"
            $_.DriverUptoDate = if($latest_version_nvidia -eq $_.DriverInstalled){$True}else{$False}
            $_.DriverLink = $url
            $_.DriverLink2 = $rp_url
            RMM-Msg "Installed Nvidia driver : $($gpuInfo | Where-Object { $_.Name -match 'nvidia' } | Select-Object -ExpandProperty DriverInstalled)"
            RMM-Msg "Link Nvidia driver : $url"
        }
    }
    ## AMD SECTION ##      
    $exists_amd = $gpuInfo | Where-Object { $_.Name -match "amd" }
    if($exists_amd){
        $ins_version_amd = Get-DriverInstalledamd
        $latest_version_amd , $driverLink_amd = Get-driverlatestversionamd
            $gpuInfo | ForEach-Object {
                if ($_.Name -match "AMD") {
                    $_.DriverInstalled = $ins_version_amd
                    $_.DriverLatest = $latest_version_amd
                    $_.DriverUptoDate = if($latest_version_amd -eq $ins_version_amd){$True}else{$False}
                    $_.DriverLink = $driverLink_amd
                }
            }
    }
    ## INTEL SECTION ##
    $exists_intel = $gpuInfo | Where-Object { $_.Name -match "intel" }
    if($exists_intel){
        ## Retrieve Intel Generation
        $generationPattern = "-(\d+)\d{3}"
        $matches = [System.Text.RegularExpressions.Regex]::Match($gpuinfo.Processor, $generationPattern)
        if ($matches.Success) {
        $generation = [decimal]$matches.Groups[1].Value
        $intelGeneration = if ($generation -ge 2 -and $generation -le 14) {
        "$generation Gen"
            } else {
                "Unknown"
            }
            } else {
                $intelGeneration = "Unknown"
            }
            $gpuInfo | ForEach-Object {
                if ($_.Name -match "INTEL") {
                $_.Generation = $generation
                }
            }
        ## Retreve Driver link function
        function GetLatestDriverLink($url, $generation) {
            $content = Invoke-WebRequest $url -Headers @{'Referer' = 'https://www.intel.com/'} -UseBasicParsing | % Content
            $linkPattern = '<meta\ name="RecommendedDownloadUrl"\ content="([^"]+)'
            $versionPattern = '<meta\ name="DownloadVersion"\ content="([^"]+)'
            if ($content -match $linkPattern) {
                $driverLink_intel = $Matches[1].Replace(".exe", ".exe")
            }
            if ($content -match $versionPattern) {
                $driverVersion = $Matches[1]
                $latest_version_intel = $driverVersion
                RMM-Msg "`t`t`tLatest Intel driver : $latest_version_intel" -messagetype Verbose 
            }
                return $driverLink_intel, $latest_version_intel
        }
        if ($intelgeneration -gt 10) {
            $driverLink_intel, $latest_version_intel = GetLatestDriverLink 'https://www.intel.com/content/www/us/en/download/785597/intel-arc-iris-xe-graphics-windows.html' $generation          
        }elseif ($intelgeneration -gt 5) {
            $driverLink_intel, $latest_version_intel = GetLatestDriverLink 'https://www.intel.com/content/www/us/en/download/776137/intel-7th-10th-gen-processor-graphics-windows.html' $generation
        }else {
            $latest_version_intel = "Legacy"
        }
        $gpuInfo | ForEach-Object {
            if ($_.Name -match "INTEL") {
                $_.DriverLatest = $latest_version_intel
                $_.DriverUptoDate = if($latest_version_intel -eq $_.DriverInstalled){$True}else{$False}
                $_.DriverLink = $driverLink_intel
                RMM-Msg "Installed Intel driver : $($gpuInfo | Where-Object { $_.Name -match 'INTEL' } | Select-Object -ExpandProperty DriverInstalled)"
                RMM-Msg "Link Intel driver : $driverLink_intel"
            }
        }
    }
    foreach ($gpu in $gpuinfo) {
        if ($gpu.DriverUptoDate -eq $false) {
            Set-Toast -Toasttitle "$($gpu.brand) Drivers Found" -Toasttext "Latest : $($gpu.DriverLatest) Installed : $($gpu.DriverInstalled)" -UniqueIdentifier "default" -Toastenable $notifications
            $outOfDateFound = $true
        }
    }
    if (!$outOfDateFound) {
        Set-Toast -Toasttitle "Driver Check" -Toasttext "No new drivers found" -UniqueIdentifier "default" -Toastenable $notifications
    }
    
    
    return $gpuInfo
}

function Get-DriverInstalledAmd {
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    # Retrieve the subkeys from the specified registry path
    $subKeys = Get-Item -Path $registryPath | Get-ChildItem -ErrorAction SilentlyContinue
    # Loop through each subkey and retrieve the value of "RadeonSoftwareVersion" if it exists
    foreach ($subKey in $subKeys) {
        $value = Get-ItemProperty -Path $subKey.PSPath -Name "RadeonSoftwareVersion" -ErrorAction SilentlyContinue
        if ($value) {
            #Write-Output "Subkey: $($subKey.PSChildName) - RadeonSoftwareVersion: $($value.RadeonSoftwareVersion)"
            $ins_version_amd = $($value.RadeonSoftwareVersion)
            RMM-Msg "Installed AMD driver : $ins_version_amd"
        }
    }
    return $ins_version_amd
}

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
    $line = $responselinks | Select-String -Pattern "https://www.amd.com/en/support/kb/release-notes" | Select-Object -First 1
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

function Set-DriverUpdatesAmd {
    RMM-Msg "Script Mode: `tUpdating AMD drivers" -messagetype Verbose
    Set-Toast -Toasttitle "Updating Drivers" -Toasttext "Updating AMD Drivers" -UniqueIdentifier "default" -Toastenable $notifications
    $gpuInfoamd = $gpuInfo | Where-Object { $_.Name -match "amd" }
    $extractinfo = Get-extract
    if ($gpuInfoamd.DriverUptoDate -eq $True){
        RMM-Msg "AMD Drivers already upto date"
        return "UpToDate"
    }
    $amdversion = $gpuInfoamd.DriverLatest
    $amdurl = $gpuInfoamd.DriverLink
    Invoke-WebRequest -Uri $amdurl -Headers @{'Referer' = 'https://www.amd.com/en/support'} -Outfile C:\temp\ninjarmm\$amdversion.exe -usebasicparsing
    # Installing drivers
    RMM-Msg "Installing AMD drivers now..." -messagetype Verbose
    $install_args = "-install"
    Start-Process -FilePath "C:\temp\ninjarmm\$amdversion.exe" -ArgumentList $install_args -wait
    RMM-Msg "Driver installed. You may need to reboot to finish installation." -messagetype Verbose
    RMM-Msg "Driver installed. $amdversion" -messagetype Verbose
    Set-Toast -Toasttitle "Updating Drivers" -Toasttext "$amdversion AMD Drivers Installed" -UniqueIdentifier "default" -Toastenable $notifications
    return "Updated"
} 

function Get-DriverLatestVersionNvidia {
    ## Check OS Level
    if ($cim_os -match "Windows 11"){
        $os = "135"
    }
    elseif ($cim_os -match "Windows 10"){
        $os = "57"
    }else {
        # Default to windows 11 if no match
        $os = "135"
    }
    if ($exists_nvidia.name -match "Quadro|NVIDIA RTX|NVIDIA T600|NVIDIA T1000|NVIDIA T400") {
        $nsd = ""
        $windowsVersion = if (($cim_os -match "Windows 11")-or($cim_os -match "Windows 10")){"win10-win11"}elseif(($cim_os -match "Windows 7")-or($cim_os -match "Windows 8")){"win8-win7"}
        $windowsArchitecture = if ([Environment]::Is64BitOperatingSystem){"64bit"}else{"32bit"}
        $cardtype = "/Quadro_Certified/"
        $drivername1 = "quadro-rtx-desktop-notebook"
        $drivername2 = "dch"
        $psid = "122"
        $pfid = "967"
        $whql = "1"
    } elseif ($exists_nvidia.name -match "Geforce") {
        $nsd = "nsd-"
        $windowsVersion = if (($cim_os -match "Windows 11")-or($cim_os -match "Windows 10")){"win10-win11"}elseif(($cim_os -match "Windows 7")-or($cim_os -match "Windows 8")){"win8-win7"}
        $windowsArchitecture = if ([Environment]::Is64BitOperatingSystem){"64bit"}else{"32bit"}
        $cardtype = "/"
        $drivername1 = "desktop"
        $psid = "127"
        $pfid = "995"
        ## Check if Studio or Beta set
        if ($geforcedriver -eq 'Studio'){
            $whql = "4"
            $drivername2 = "nsd-dch"
        }
        if ($geforcedriver -eq 'Game'){
            $whql = "1"
            $drivername2 = "dch"
        }
    } elseif ($exists_nvidia.name -eq $null){
        # If no card set, default to 4090/win11/studio for driver check
        $nsd = "nsd-"
        $windowsVersion = "win10-win11"
        $os = "135"
        $windowsArchitecture = if ([Environment]::Is64BitOperatingSystem){"64bit"}else{"32bit"}
        $cardtype = "/"
        $drivername1 = "desktop"
        $psid = "127"
        $pfid = "995"
        $whql = "4"
        $drivername2 = "nsd-dch"
    }
    # Checking latest driver version from Nvidia website
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    $linkcreate = 'https://www.nvidia.com/Download/processFind.aspx?psid='+$psid+'&pfid='+$pfid+'&osid='+$os+'&lid=1&whql='+$whql+'&lang=en-us&ctk=0&qnfslb=10&dtcid=1'
    $link = Invoke-WebRequest -Uri $linkcreate -Method GET -UseBasicParsing
    $link -match '<td class="gridItem">([^<]+?)</td>' | Out-Null
    $version = $matches[1]
    if ($version -match "R"){
        ## Write-Host "Replacing invalid chars"
        $latest_version_nvidia = $version -replace '^.*\(|\)$',''
        RMM-Msg "Latest Nvidia driver : $latest_version_nvidia"
        }else {
        $latest_version_nvidia = $version
        RMM-Msg "Latest Nvidia driver : $latest_version_nvidia"
    }  
        # Create download URL
        $url = "https://international.download.nvidia.com/Windows$cardtype$latest_version_nvidia/$latest_version_nvidia-$drivername1-$windowsVersion-$windowsArchitecture-international-$drivername2-whql.exe"
        $rp_url = "https://international.download.nvidia.com/Windows$cardtype$latest_version_nvidia/$latest_version_nvidia-$drivername1-$windowsVersion-$windowsArchitecture-international-$drivername2-whql-rp.exe"
    return $latest_version_nvidia, $url, $rp_url
}

function Set-DriverUpdatesNvidia {
    param (
    [switch]$clean = $false, # Will delete old drivers and install the new ones
    [string]$folder = "C:\Temp"   # Downloads and extracts the driver here
    )
    RMM-Msg "Script Mode: `tUpdating NVIDIA drivers" -messagetype Verbose
    Set-Toast -Toasttitle "Updating Drivers" -Toasttext "Updating Nvidia Drivers" -UniqueIdentifier "default" -Toastenable $notifications
    $gpuInfoNvidia = $gpuInfo | Where-Object { $_.Name -match "nvidia" }
    $extractinfo = Get-extract
    if ($gpuInfoNvidia.DriverUptoDate -eq $True){
        RMM-Msg "Nvidia Drivers already upto date" -messagetype Verbose
        return "UptoDate"
    }

    # Temp folder
    New-Item -Path $folder -ItemType Directory 2>&1 | Out-Null
    $nvidiaTempFolder = "$folder\NVIDIA"
    New-Item -Path $nvidiaTempFolder -ItemType Directory 2>&1 | Out-Null

    # Variable Set
    $extractFolder = "$nvidiaTempFolder\$($gpuInfoNvidia.DriverLatest.Trim())"
    $filesToExtract = "Display.Driver HDAudio NVI2 PhysX EULA.txt ListDevices.txt setup.cfg setup.exe"

    # Downloading the installer
    $dlFile = "$nvidiaTempFolder\$($gpuInfoNvidia.DriverLatest.Trim()).exe"
    Get-DownloadUrls -urllist $gpuInfoNvidia.DriverLink -downloadLocation $dlFile

    # Extract the installer
    if ($extractinfo.'7zipinstalled') {
        Start-Process -FilePath $extractinfo.archiverProgram -NoNewWindow -ArgumentList "x -bso0 -bsp1 -bse1 -aoa $dlFile $filesToExtract -o""$extractFolder""" -wait
    }else {
        RMM-Error "Something went wrong. No archive program detected. This should not happen." -messagetype Verbose
        RMM-Exit 1
    }

    # Remove unneeded dependencies from setup.cfg
    (Get-Content "$extractFolder\setup.cfg") | Where-Object { $_ -notmatch 'name="\${{(EulaHtmlFile|FunctionalConsentFile|PrivacyPolicyFile)}}' } | Set-Content "$extractFolder\setup.cfg" -Encoding UTF8 -Force

    # Installing drivers
    RMM-Msg "Installing Nvidia drivers now..." -messagetype Verbose
    $install_args = "-passive -noreboot -noeula -nofinish -s"
    if ($clean) {
        $install_args = $install_args + " -clean"
    }
    Start-Process -FilePath "$extractFolder\setup.exe" -ArgumentList $install_args -wait

    # Cleaning up downloaded files
    RMM-Msg "Deleting downloaded files" -messagetype Verbose
    Remove-Item $nvidiaTempFolder -Recurse -Force

    # Driver installed, requesting a reboot
    RMM-Msg "Driver installed. You may need to reboot to finish installation." -messagetype Verbose
    RMM-Msg "Driver installed. $($gpuInfoNvidia.DriverLatest)" -messagetype Verbose
    Set-Toast -Toasttitle "Updating Drivers" -Toasttext "$($gpuInfoNvidia.DriverLatest) Nvidia Drivers Installed" -UniqueIdentifier "default" -Toastenable $notifications
    return "Updated"
}

function Set-DriverUpdatesintel{
    RMM-Msg "Script Mode: `tUpdating Intel drivers" -messagetype Verbose
    $gpuInfointel = $gpuInfo | Where-Object { $_.Name -match "intel" }
    $extractinfo = Get-extract
    if ($gpuInfointel.DriverUptoDate -eq $True){
      RMM-Msg "Intel Drivers already upto date" -messagetype Verbose
      $installstatus = "uptodate"
      return
    }
    $intelversion = $gpuInfointel.DriverLatest
    $intelurl = $gpuInfointel.DriverLink
    $inteldriverfile = "C:\temp\ninjarmm\$intelversion.exe"
    mkdir "C:\temp\ninjarmm\$intelversion"
    $extractFolder = "C:\temp\ninjarmm\$intelversion"
    if (-not(Test-Path -Path $inteldriverfile -PathType Leaf)){
    Invoke-WebRequest -Uri $intelurl -Headers @{'Referer' = 'https://www.intel.com/'} -Outfile C:\temp\ninjarmm\$intelversion.exe -usebasicparsing
    }
    if ($extractinfo.'7zipinstalled') {
      Start-Process -FilePath $extractinfo.archiverProgram -NoNewWindow -ArgumentList "x -bso0 -bsp1 -bse1 -aoa $inteldriverfile -o""$extractFolder""" -wait
  }else {
      RMM-Error "Something went wrong. No archive program detected. This should not happen." -messagetype Verbose
      RMM-Exit 1
  }
  
    # Installing drivers
    RMM-Msg "Installing Intel drivers now..." -messagetype Verbose
    $install_args = "--silent"
    Start-Process -FilePath "$extractFolder\installer.exe" -ArgumentList $install_args -wait
    RMM-Msg "Driver installed. You may need to reboot to finish installation." -messagetype Verbose
    RMM-Msg "Driver installed. $intelversion" -messagetype Verbose
    $installstatus = "Updated"
    return
}

function Get-TimeStamp() {
    return (Get-Date).ToString("dd-MM-yyyy HH:mm:ss")
}

function Register-BurntToast {
## Check if toast installed
if(-not (Get-Module BurntToast -ListAvailable)){
    Install-Module BurntToast -Force
    Import-Module BurntToast
    }else{
        Import-Module BurntToast
    }
if(-not (Get-Module RunAsUser -ListAvailable)){
    Install-Module RunAsUser -Force
    Import-Module RunAsUser
    }else{
        Import-Module RunAsUser
    }

#Checking if ToastReboot:// protocol handler is present
$null = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -erroraction silentlycontinue
$ProtocolHandler = get-item 'HKCR:\ToastReboot' -erroraction 'silentlycontinue'
if (!$ProtocolHandler) {
    #create handler for reboot
    New-item 'HKCR:\ToastReboot' -force
    set-itemproperty 'HKCR:\ToastReboot' -name '(DEFAULT)' -value 'url:ToastReboot' -force
    set-itemproperty 'HKCR:\ToastReboot' -name 'URL Protocol' -value '' -force
    new-itemproperty -path 'HKCR:\ToastReboot' -propertytype dword -name 'EditFlags' -value 2162688
    New-item 'HKCR:\ToastReboot\Shell\Open\command' -force
    set-itemproperty 'HKCR:\ToastReboot\Shell\Open\command' -name '(DEFAULT)' -value 'C:\Windows\System32\shutdown.exe -r -t 00' -force
}
}


Function Register-NotificationApp {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]$AppID,
        [Parameter(Mandatory=$true)]$AppDisplayName,
        [Parameter(Mandatory=$false)]$AppIconUri,
        [Parameter(Mandatory=$false)][int]$ShowInSettings = 0
    )
    $HKCR = Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue
    If (!($HKCR))
    {
        $null = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -Scope Script
    }
    $AppRegPath = "HKCR:\AppUserModelId"
    $RegPath = "$AppRegPath\$AppID"
    If (!(Test-Path $RegPath))
    {
        $null = New-Item -Path $AppRegPath -Name $AppID -Force
    }
    $DisplayName = Get-ItemProperty -Path $RegPath -Name DisplayName -ErrorAction SilentlyContinue | Select -ExpandProperty DisplayName -ErrorAction SilentlyContinue
    If ($DisplayName -ne $AppDisplayName)
    {
        $null = New-ItemProperty -Path $RegPath -Name DisplayName -Value $AppDisplayName -PropertyType String -Force
    }
    $IconUri = Get-ItemProperty -Path $RegPath -Name IconUri -ErrorAction SilentlyContinue | Select -ExpandProperty IconUri -ErrorAction SilentlyContinue
    If ($IconUri -ne $AppIconUri)
    {
        $null = New-ItemProperty -Path $RegPath -Name IconUri -Value $AppIconUri -PropertyType String -Force
    }
    $ShowInSettingsValue = Get-ItemProperty -Path $RegPath -Name ShowInSettings -ErrorAction SilentlyContinue | Select -ExpandProperty ShowInSettings -ErrorAction SilentlyContinue
    If ($ShowInSettingsValue -ne $ShowInSettings)
    {
        $null = New-ItemProperty -Path $RegPath -Name ShowInSettings -Value $ShowInSettings -PropertyType DWORD -Force
    }
    Remove-PSDrive -Name HKCR -Force
}

function RMM-Error{
    param (
    $Message,
    [ValidateSet('Verbose','Debug','Silent')]
    [string]$messagetype = 'Silent'
  )
  $Global:ErrorCount += 1
  if($logging -eq $true){
    $global:Output += "$(Get-Timestamp) - Error : $Message"+$Global:nl
    Add-content $logfile -value "$(Get-Timestamp) - Error : $message"
  }
  if($messagetype -eq 'Verbose'){
      Write-Warning "$Message"
  } elseif($messagetype -eq 'Debug'){
      Write-Debug "$Message"
  }
}

function RMM-Exit{  
    param(
        [string]$ExitCode = ""
    )
    if($logging -eq $true){
    $Message = '----------'+$Global:nl+"$(Get-Timestamp) - Errors : $Global:ErrorCount"
    $global:Output += "$(Get-Timestamp) $Message"
    Add-content $logfile -value "$(Get-Timestamp) - Exit  : $message Exit Code = $Exitcode"
    Add-content $logfile -value "$(Get-Timestamp) -----------------------------Log End"
    RMM-LogParse
    }
    Write-Output "Errors : $Global:ErrorCount"
    if($ExitCode -eq 0){
        Exit $ExitCode
    }
    if($ExitCode -eq 1){
        Exit $ExitCode
    }
    if($ExitCode -eq $null){
    }
}

function RMM-Initilize{
    if($logging -eq $true){
        Add-content $logfile -value "$(Get-Timestamp) -----------------------------$logdescription"
    }
}

function RMM-LogParse{
    if($logging -eq $true){
        $cutOffDate = (Get-Date).AddDays(-30)
        $lines = Get-Content -Path $logfile
        $filteredLines = $lines | Where-Object {
                if ($_ -match '^(\d{2}-\d{2}-\d{4} \d{2}:\d{2}:\d{2})') {
                    $lineDate = [DateTime]::ParseExact($matches[1], 'dd-MM-yyyy HH:mm:ss', $null)
                    $lineDate -ge $cutOffDate
                } else {
                    $true  # Include lines without a recognized date
                }
        }
        $filteredLines | Set-Content -Path $logfile
    }
}

function RMM-Msg{
    param (
      $Message,
      [ValidateSet('Verbose','Debug','Silent')]
      [string]$messagetype = 'Silent'
    )
    if($logging -eq $true){
      $global:Output += "$(Get-Timestamp) - Msg   : $Message"+$Global:nl
      Add-content $logfile -value "$(Get-Timestamp) - Msg   : $message"
    }
    if($messagetype -eq 'Verbose'){
      Write-Output "$Message"
    }elseif($messagetype -eq 'Debug'){
      Write-Debug "$Message"
    }
}  

function Set-Toast{
    param (
    [string]$Toastenable = $true,
    [string]$Toasttitle = "",
    [string]$Toasttext = "",
    [string]$Toastlogo = "$PSScriptRoot\resources\logos\logo_ninjarmm_square.png",
    [string]$UniqueIdentifier = "default",
    [switch]$Toastreboot = $false
    )
    if($Toastenable -eq $false){return}
    New-BTAppId -AppId "EasyDriverUpdate.Notification"
    if($Toastreboot){
            $scriptblock = {
                $logoimage = New-BTImage -Source $Toastlogo -AppLogoOverride -Crop Default
                $Text1 = New-BTText -Content  "$Toasttitle"
                $Text2 = New-BTText -Content "$Toasttext"
                $Button = New-BTButton -Content "Snooze" -Snooze -id 'SnoozeTime'
                $Button2 = New-BTButton -Content "Reboot now" -Arguments "ToastReboot:" -ActivationType Protocol
                $Button3 = New-BTButton -Content "Dismiss" -Dismiss
                $10Min = New-BTSelectionBoxItem -Id 10 -Content '10 minutes'
                $1Hour = New-BTSelectionBoxItem -Id 60 -Content '1 hour'
                $1Day = New-BTSelectionBoxItem -Id 1440 -Content '1 day'
                $Items = $10Min, $1Hour, $1Day
                $SelectionBox = New-BTInput -Id 'SnoozeTime' -DefaultSelectionBoxItemId 10 -Items $Items
                $action = New-BTAction -Buttons $Button, $Button2, $Button3 -inputs $SelectionBox
                $Binding = New-BTBinding -Children $text1, $text2 -AppLogoOverride $logoimage
                $Visual = New-BTVisual -BindingGeneric $Binding
                $Content = New-BTContent -Visual $Visual -Actions $action
                Submit-BTNotification -Content $Content -UniqueIdentifier $UniqueIdentifier -AppId "EasyDriverUpdate.Notification"
        }
        }else{
            $scriptblock = {
                $logoimage = New-BTImage -Source $Toastlogo -AppLogoOverride -Crop Default
                $Text1 = New-BTText -Content  "$Toasttitle"
                $Text2 = New-BTText -Content "$Toasttext"
                $Button = New-BTButton -Content "Dismiss" -Dismiss
                $action = New-BTAction -Buttons $Button
                $Binding = New-BTBinding -Children $text1, $text2 -AppLogoOverride $logoimage
                $Visual = New-BTVisual -BindingGeneric $Binding
                $Content = New-BTContent -Visual $Visual -Actions $action
                Submit-BTNotification -Content $Content -UniqueIdentifier $UniqueIdentifier -AppId "EasyDriverUpdate.Notification"
        }
    }
    if(($currentuser = whoami) -eq 'nt authority\system'){
        $systemcontext = $true
    }else {
        $systemcontext = $false
    }
    if($systemcontext -eq $true) {
        invoke-ascurrentuser -scriptblock $scriptblock
    }else{
        Invoke-Command -scriptblock $scriptblock 
    }
}

function Set-ToastProgress {
    $ParentBar = New-BTProgressBar -Title 'ParentTitle' -Status 'ParentStatus' -Value 'ParentValue'
    function Set-Downloadbar {
    $DataBinding = @{
        'ParentTitle'  = 'Installing Nvidia Drivers'
        'ParentStatus' = 'Downloading'
        'ParentValue'  = $currentpercentage
    }
    return $DataBinding
    }
    $Id = 'SecondUpdateDemo'
    $Text = 'Driver Updater', 'Drivers are currently updating'
    $currentpercentage = 0.1
    $DataBinding = Set-Downloadbar
    New-BurntToastNotification -Text $Text -UniqueIdentifier $Id -ProgressBar $ParentBar -DataBinding $DataBinding -Snoozeanddismiss
    $currentpercentage = 0.2
    $DataBinding = Set-Downloadbar
    Update-BTNotification -UniqueIdentifier $Id -DataBinding $DataBinding -ErrorAction SilentlyContinue
    $currentpercentage = 0.8
    $DataBinding = Set-Downloadbar
    Update-BTNotification -UniqueIdentifier $Id -DataBinding $DataBinding -ErrorAction SilentlyContinue

    New-BurntToastNotification -Progressbar @(
        New-BTProgressBar -Status 'Copying files' -Indeterminate
        New-BTProgressBar -Status 'Copying files' -Value 0.2 -ValueDisplay '4/20 files complete'
        New-BTProgressBar -Title 'File Copy' -Status 'Copying files' -Value 0.2
    ) -UniqueIdentifier 'ExampleToast' -Snoozeanddismiss

    Update-BTNotification -UniqueIdentifier 'ExampleToast' -DataBinding '$DataBinding' -ErrorAction SilentlyContinue

    $DataBinding

    New-BurntToastNotification -Text 'Server Update' -ProgressBar $ProgressBar -UniqueIdentifier 'Toast001' -Snoozeanddismiss
    New-BurntToastNotification -Text 'Server Updates' -ProgressBar $ProgressBar -UniqueIdentifier 'Toast001' -Snoozeanddismiss

}

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

function Set-GPUtoNinjaRMM {
    RMM-Msg "Script Mode: `tLogging details to NinjaRMM" -messagetype Verbose
    foreach ($gpu in $gpuInfo) {
        if ($gpu.IsDiscrete){
            $discreteGPUFound = $true
            Ninja-Property-Set hardwarediscretegpu $gpu.Name
            Ninja-Property-Set hardwarediscretedriverinstalled $gpu.DriverInstalled
            Ninja-Property-Set hardwarediscretedriverlatest $gpu.DriverLatest
            if($gpu.DriverUptoDate){
                Ninja-Property-Set hardwarediscretedriveruptodate "1"
            }else {
                Ninja-Property-Set hardwarediscretedriveruptodate "0"
            }
        }
        if ($gpu.IsIntegrated){
            $integratedGPUFound = $true
            Ninja-Property-Set hardwareintegratedgpu $gpu.Name
            Ninja-Property-Set hardwareintegrateddriverinstalled $gpu.DriverInstalled
            Ninja-Property-Set hardwareintegrateddriverlatest $gpu.DriverLatest
            if($gpu.DriverUptoDate){
                Ninja-Property-Set hardwareintegrateddriveruptodate "1"
            }else {
                Ninja-Property-Set hardwareintegrateddriveruptodate "0"
            }
        }

    }
if (-not $integratedGPUFound) {
Ninja-Property-Set hardwareintegratedgpu "Not Detected"
Ninja-Property-Set hardwareintegrateddriverinstalled clear
Ninja-Property-Set hardwareintegrateddriverlatest clear
Ninja-Property-Set hardwareintegrateddriveruptodate clear
}
if (-not $discreteGPUFound) {
Ninja-Property-Set hardwarediscretegpu "Not Detected"
}
return
}

Get-Warranty
