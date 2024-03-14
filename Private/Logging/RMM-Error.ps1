function RMM-Error{
    param (
    $Message,
    [ValidateSet('Verbose','Debug','Silent')]
    [string]$messagetype = 'Silent'
  )
  $Global:ErrorCount += 1
  $global:Output += "$(Get-Timestamp) - Error : $Message"+$Global:nl
  Add-content $logfile -value "$(Get-Timestamp) - Error : $message"
  if($messagetype -eq 'Verbose'){Write-Warning "$Message"}elseif($messagetype -eq 'Debug'){Write-Debug "$Message"}
}