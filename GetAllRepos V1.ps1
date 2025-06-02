# ---------------------- CONFIG ----------------------
$GitHubToken = "your_personal_access_token_here"
$OrgOrUser = "your_org_or_username_here"   # Can be a user or org
$IsOrg = $true                              # Set $false if it's a user
$OutputPath = "C:\GitHubRepos.csv"
# ----------------------------------------------------

$Headers = @{
    Authorization = "Bearer $GitHubToken"
    Accept        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

$Repos = @()
$Page = 1
$PerPage = 100

do {
    if ($IsOrg) {
        $url = "https://api.github.com/orgs/$OrgOrUser/repos?per_page=$PerPage&page=$Page"
    } else {
        $url = "https://api.github.com/users/$OrgOrUser/repos?per_page=$PerPage&page=$Page"
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $Headers -Method Get
        if ($response.Count -gt 0) {
            $Repos += $response
        }
    } catch {
        Write-Error "Failed to fetch page $Page: $_"
        break
    }

    $Page++
} while ($response.Count -eq $PerPage)

# Export selected repo fields to CSV
$Repos | Select-Object name, full_name, html_url, description, visibility, created_at, updated_at, pushed_at |
    Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Host "Exported $($Repos.Count) repositories to $OutputPath"
