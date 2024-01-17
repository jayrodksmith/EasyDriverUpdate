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