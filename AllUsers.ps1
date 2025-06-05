# GitHub API token with at least read:user scope
$token = "ghp_YOUR_PERSONAL_ACCESS_TOKEN"
$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/vnd.github.v3+json"
    "User-Agent"  = "PowerShellScript"
}

# Initialize
$users = @()
$perPage = 100
$sleepBetweenPages = 2  # to avoid rate-limiting
$url = "https://api.github.com/users?per_page=$perPage"
$page = 1

do {
    Write-Host "Fetching page $page..."
    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
    $users += $response

    # Check for pagination in Link header
    $linkHeader = ($response.PSObject.Properties["RawContent"]?.Value -split "`n") |
        Where-Object { $_ -like "*Link:*" } |
        ForEach-Object { $_ -replace "^Link:\s*", "" }

    if ($linkHeader) {
        $matches = [regex]::Matches($linkHeader, '<([^>]+)>;\s*rel="next"')
        $url = if ($matches.Count -gt 0) { $matches[0].Groups[1].Value } else { $null }
    } else {
        $url = $null
    }

    Start-Sleep -Seconds $sleepBetweenPages
    $page++

} while ($url)

# Prepare data for CSV
$users |
    Select-Object login, id, html_url, type, site_admin |
    Export-Csv -Path "GitHubUsers.csv" -NoTypeInformation

Write-Host "Export completed. File saved as GitHubUsers.csv"
