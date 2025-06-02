# === Configuration ===
$OrgName = "your-org-name"  # Replace with your GitHub organization name
$Token = "ghp_yourTokenHere"  # Replace with your GitHub Personal Access Token

$Headers = @{
    Authorization = "Bearer $Token"
    Accept        = "application/vnd.github+json"
    "User-Agent"  = "PowerShellScript"
}

# === Initialize ===
$Page = 1
$PerPage = 100
$AllRepos = @()

do {
    $Url = "https://api.github.com/orgs/$OrgName/repos?per_page=$PerPage&page=$Page"
    try {
        $Response = Invoke-RestMethod -Uri $Url -Headers $Headers -Method Get
    } catch {
        Write-Error "Failed to fetch page $Page. Error: $_"
        break
    }

    if ($Response.Count -gt 0) {
        foreach ($Repo in $Response) {
            $AllRepos += [PSCustomObject]@{
                RepoName     = $Repo.name
                FullName     = $Repo.full_name
                Private      = $Repo.private
                Visibility   = $Repo.visibility
                CreatedAt    = $Repo.created_at
                UpdatedAt    = $Repo.updated_at
                DefaultBranch= $Repo.default_branch
                HtmlUrl      = $Repo.html_url
            }
        }
        $Page++
    } else {
        break
    }

} while ($Response.Count -eq $PerPage)

# === Export to CSV ===
$AllRepos | Export-Csv -Path ".\GitHub_All_Repos.csv" -NoTypeInformation
Write-Host "✅ Export complete. File saved as GitHub_All_Repos.csv"
