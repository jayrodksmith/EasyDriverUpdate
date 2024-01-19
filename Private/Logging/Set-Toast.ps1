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