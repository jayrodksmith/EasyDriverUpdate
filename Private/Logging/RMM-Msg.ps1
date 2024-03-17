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