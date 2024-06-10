function Get-NvidiaGpuInfo {
    $possiblePaths = @(
        "C:\Windows\system32\nvidia-smi.exe",
        "C:\Windows\System32\DriverStore\FileRepository"
    )

    $nvSmiPath = $null

    # Check the first possible path directly
    if (Test-Path $possiblePaths[0]) {
        $nvSmiPath = $possiblePaths[0]
    } else {
        # Search for nvidia-smi.exe in directories starting with "nv" in the FileRepository
        $nvSmiPath = Get-ChildItem -Path $possiblePaths[1] -Recurse -Directory -Filter "nv*" -ErrorAction SilentlyContinue |
                     Get-ChildItem -Filter "nvidia-smi.exe" -ErrorAction SilentlyContinue |
                     Select-Object -First 1 -ExpandProperty FullName
    }

    if ($nvSmiPath) {
        # Query GPU information
        $output = & $nvSmiPath --query-gpu=index,name,power.draw,temperature.gpu,driver_version,fan.speed,utilization.gpu --format=csv,noheader,nounits

        # Query detailed power information
        $powerOutput = & $nvSmiPath -q -d POWER

        # Split the output into lines and process each line
        $gpuInfoList = @()
        $powerLines = $powerOutput -split "`n"
        $powerData = @{}
        $currentIndex = ""
        $gpuIndexMap = @{}  # To map GPU bus IDs to indices

        foreach ($line in $powerLines) {
            if ($line -match "GPU ([0-9A-F:]+)") {
                $currentIndex = $matches[1]
                # Map the GPU bus ID to an index
                if (-not $gpuIndexMap.ContainsKey($currentIndex)) {
                    $gpuIndexMap[$currentIndex] = [string]($gpuIndexMap.Count)
                }
                $normalizedIndex = $gpuIndexMap[$currentIndex]
                $powerData[$normalizedIndex] = @{
                    CurrentPowerLimit = $null
                    MaxPowerLimit     = $null
                }
            } elseif ($line -match "Current Power Limit\s*:\s*([0-9\.]+)\s*W") {
                $powerData[$normalizedIndex]["CurrentPowerLimit"] = [decimal]::Parse($matches[1])
	          } elseif ($line -match "Power Limit                       :\s*([0-9\.]+)\s*W") {
                $powerData[$normalizedIndex]["CurrentPowerLimit"] = [decimal]::Parse($matches[1])
            } elseif ($line -match "Max Power Limit\s*:\s*([0-9\.]+)\s*W") {
                $powerData[$normalizedIndex]["MaxPowerLimit"] = [decimal]::Parse($matches[1])
            } 
        }

        $gpuInfoList = foreach ($line in $output) {
            $data = $line -split ","

            $index = $data[0].Trim()

            # Retrieve power limits from detailed output
            $maxlimitTDP = if ($powerData.ContainsKey($index)) { [math]::Round($powerData[$index]["MaxPowerLimit"], 2) } else { $null }
           $currentlimitTDP = if ($powerData.ContainsKey($index)) { [math]::Round($powerData[$index]["CurrentPowerLimit"], 2) } else { $null }

            # Create a PowerShell object with the GPU information
            $gpuInfo = [PSCustomObject]@{
                #Index            = [int]$data[0].Trim()
                Model             = ($data[1].Trim() -replace "NVIDIA", "").Trim()
                'TDP Draw'        = if ($data[2].Trim() -eq "[N/A]") { $null } else { [math]::Round([decimal]::Parse($data[2].Trim()), 2) }
                'TDP Limit'       = $currentlimitTDP
                'TDP Limit Max'   = $maxlimitTDP
                Temp              = if ($data[3].Trim() -eq "[N/A]") { $null } else { [int]$data[3].Trim() }
                Driver            = $data[4].Trim()
                FanSpeed          = if ($data[5].Trim() -eq "[N/A]") { $null } else { [int]$data[5].Trim() }
                Utilization       = if ($data[6].Trim() -eq "[N/A]") { $null } else { [int]$data[6].Trim() }
            }
            return $gpuInfo
        }

        return $gpuInfoList
    } else {
        Write-Error "NVIDIA SMI tool not found in the expected locations."
        return $null
    }
}

# Function to check for NVIDIA GPU
function Check-NvidiaGpu {
    $nvidiaGpus = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }

    if ($nvidiaGpus.Count -eq 0) {
        Write-Output "No NVIDIA GPU found. Exiting script."
        exit
    } else {
        Write-Output "NVIDIA GPU found"
    }
}

# Check for NVIDIA GPU
Check-NvidiaGpu

# Get and display the GPU information
$gpuInfoList = Get-NvidiaGpuInfo
$gpuInfoList
