function Get-DriverLatestVersionNvidia {
    ## Check OS Level
    if ($cim_os -match "Windows 11"){$os = "135"}
    elseif ($cim_os-match "Windows 10"){$os = "57"}
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
        }elseif ($exists_nvidia.name -match "Geforce") {
        $nsd = "nsd-"
        $windowsVersion = if (($cim_os -match "Windows 11")-or($cim_os -match "Windows 10")){"win10-win11"}elseif(($cim_os -match "Windows 7")-or($cim_os -match "Windows 8")){"win8-win7"}
        $windowsArchitecture = if ([Environment]::Is64BitOperatingSystem){"64bit"}else{"32bit"}
        $cardtype = "/"
        $drivername1 = "desktop"
        $psid = "101"
        $pfid = "816"
        ## Check if Studio or Beta set
        if ($Script:geforcedriver -eq 'Studio'){
            $whql = "4"
            $drivername2 = "nsd-dch"
        }
        if ($Script:geforcedriver -eq 'Game'){
            $whql = "1"
            $drivername2 = "dch"
        }
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