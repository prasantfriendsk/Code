# Set your variables
$org = "your-org-name"
$token = "your_github_token"
$outputFile = "GitHubMembersWithStatus.csv"

# Base API endpoint
$membersUrl = "https://api.github.com/orgs/$org/members"

# Headers with auth token
$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/vnd.github+json"
    "User-Agent"  = "PowerShellScript"
}

# Initialize
$page = 1
$perPage = 100
$allMembers = @()

do {
    Write-Host "Fetching members page $page..."

    $response = curl -s -H "Authorization: Bearer $token" `
        -H "Accept: application/vnd.github+json" `
        -H "User-Agent: PowerShellScript" `
        "$membersUrl?per_page=$perPage&page=$page"

    $json = $response | ConvertFrom-Json

    if (-not $json -or $json.Count -eq 0) {
        break
    }

    foreach ($user in $json) {
        $username = $user.login

        # Fetch membership status for the user
        $membershipResponse = curl -s -H "Authorization: Bearer $token" `
            -H "Accept: application/vnd.github+json" `
            -H "User-Agent: PowerShellScript" `
            "https://api.github.com/orgs/$org/memberships/$username"

        $membership = $membershipResponse | ConvertFrom-Json

        $allMembers += [PSCustomObject]@{
            Login             = $user.login
            Id                = $user.id
            Url               = $user.html_url
            Type              = $user.type
            Site_Admin        = $user.site_admin
            Membership_State  = $membership.state  # e.g., "active" or "pending"
            Role              = $membership.role   # e.g., "member", "admin"
        }

        Start-Sleep -Milliseconds 300  # Respect API rate limit
    }

    $page++
    Start-Sleep -Seconds 1
} while ($true)

# Export to CSV
$allMembers | Export-Csv -Path $outputFile -NoTypeInformation
Write-Host "Exported $($allMembers.Count) members to $outputFile"
