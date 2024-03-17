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