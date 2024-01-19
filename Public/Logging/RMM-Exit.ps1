function RMM-Exit{  
    param(
        [int]$ExitCode = 0
    )
    $Message = '----------'+$Global:nl+"$(Get-Timestamp) - Errors : $Global:ErrorCount"
    $global:Output += "$(Get-Timestamp) $Message"
    Add-content $Script:logfile -value "$(Get-Timestamp) - Exit  : $message Exit Code = $Exitcode"
    Add-content $Script:logfile -value "$(Get-Timestamp) -----------------------------Log End"
    Write-Output "Errors : $Global:ErrorCount"
    RMM-LogParse
    Exit $ExitCode
}