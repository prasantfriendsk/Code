# ======= CONFIGURE THESE VALUES =======
$orgName = "your-org-name"  # <-- replace with your GitHub organization name
$token = "ghp_YOUR_GITHUB_TOKEN"  # <-- replace with your personal access token
$outputFile = "GitHubPeople.csv"
# ======================================

$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/vnd.github.v3+json"
    "User-Agent"  = "PowerShell-GitHubScript"
}

$perPage = 100
$page = 1
$allUsers = @()

do {
    $url = "https://api.github.com/orgs/$orgName/members?per_page=$perPage&page=$page"
    Write-Host "Fetching page $page from $url..."

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
        if ($response.Count -eq 0) { break }

        $allUsers += $response
        $page++
        Start-Sleep -Seconds 1  # avoid hitting rate limits
    } catch {
        Write-Error "Failed to retrieve data: $_"
        break
    }
} while ($true)

# Export selected fields to CSV
$allUsers |
    Select-Object login, id, type, site_admin, html_url |
    Export-Csv -Path $outputFile -NoTypeInformation

Write-Host "`nExport complete. File saved to: $outputFile"
