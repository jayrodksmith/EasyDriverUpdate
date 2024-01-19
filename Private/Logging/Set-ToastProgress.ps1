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