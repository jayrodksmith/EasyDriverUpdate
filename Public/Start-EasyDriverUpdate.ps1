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
        [bool]$notifications = $true,
        [bool]$autoupdate = $false,
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
        Write-Debug "EasyDriverUpdate running as admin"}
        else{
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

    ###############################################################################
    # Global Variable Setting
    ###############################################################################

    $Script:EasyDriverUpdatePath = (Join-Path -Path $ENV:ProgramData -ChildPath "EasyDriverUpdate")
    $Script:logfilelocation = "$EasyDriverUpdatePath\logs"
    $Script:logfile = "$Script:logfilelocation\EasyDriverUpdate.log"
    $Script:logdescription = "EasyDriverUpdate"
    $Script:geforcedriver = $geforcedriver

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
    if (-not (Test-Path -Path $Script:logfilelocation -PathType Container)) {
        # Create the folder and its parent folders if they don't exist
        New-Item -Path $Script:logfilelocation -ItemType Directory -Force | Out-Null
    }
    $Global:nl = [System.Environment]::NewLine
    $Global:ErrorCount = 0
    $global:Output = '' 
    ###############################################################################
    # Function - Notifications
    ###############################################################################
    Register-BurntToast
    $AppID = "EasyDriverUpdate.Notification"
    $AppDisplayName = "EasyDriverUpdate"
    $RootPath = Split-Path $PSScriptRoot -Parent
    $AppIconUri = "$RootPath\Private\Logging\resources\logos\logo_ninjarmm_square.png"
    Register-NotificationApp -AppID $AppID -AppDisplayName $AppDisplayName -AppIconUri $AppIconUri
    ###############################################################################
    # Main Script Starts Here
    ###############################################################################
    # Get GPU Info and print to screen
    RMM-Initilize
    $gpuInfo = Get-GPUInfo
    $Script:gpuInfo = $gpuInfo

    # Send GPU Info to RMM
    if($RMMPlatform -eq "NinjaOne"){
        Set-GPUtoNinjaRMM
    }
    # Cycle through updating drivers if required
    if($UpdateAmd -eq $true){ 
        Set-DriverUpdatesamd
        if($Script:installstatus -ne "Updated"){
            Set-Toast -Toasttitle "Driver Check" -Toasttext "No new AMD drivers found" -UniqueIdentifier "nonew" -Toastenable $notifications
        }
    }
    if($UpdateNvidia -eq $true){
        Set-DriverUpdatesNvidia
        if($Script:installstatus -ne "Updated"){
            Set-Toast -Toasttitle "Driver Check" -Toasttext "No new Nvidia drivers found" -UniqueIdentifier "nonew" -Toastenable $notifications
        }
    }
    if($UpdateIntel -eq $true){
        Set-DriverUpdatesintel
        if($Script:installstatus -ne "Updated"){
            Set-Toast -Toasttitle "Driver Check" -Toasttext "No new Intel drivers found" -UniqueIdentifier "nonew" -Toastenable $notifications
        } 
    }
    $gpuInfo
    # Restart machine if required
    if($Restart -eq $true -and $Script:installstatus -eq "Updated"){
        shutdown /r /t 30 /c "In 30 seconds, the computer will be restarted to finish installing GPU Drivers"
        RMM-Exit 0
    }

    if($Restart -eq $false -and $Script:installstatus -eq "Updated"){
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