function RMM-LogParse{
    $cutOffDate = (Get-Date).AddDays(-30)
    $lines = Get-Content -Path $Script:logfile
    $filteredLines = $lines | Where-Object {
          if ($_ -match '^(\d{2}-\d{2}-\d{4} \d{2}:\d{2}:\d{2})') {
              $lineDate = [DateTime]::ParseExact($matches[1], 'dd-MM-yyyy HH:mm:ss', $null)
              $lineDate -ge $cutOffDate
          } else {
              $true  # Include lines without a recognized date
          }
      }
    $filteredLines | Set-Content -Path $Script:logfile
}