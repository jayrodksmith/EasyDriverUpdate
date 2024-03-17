function RMM-Initilize{
    if($logging -eq $true){
        Add-content $logfile -value "$(Get-Timestamp) -----------------------------$logdescription"
    }
}