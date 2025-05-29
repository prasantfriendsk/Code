# Configuration
$org = "your-org-name"
$token = "your-github-token"  # Replace with your GitHub Personal Access Token
$baseUrl = "https://api.github.com/orgs/$org/teams"
$headers = @{
    Authorization = "Bearer $token"
    "User-Agent"  = "PowerShellScript"
    Accept        = "application/vnd.github+json"
}

# Output list
$teamMemberList = @()

# Paginate through all teams
$page = 1
do {
    $teamUrl = "$baseUrl?per_page=100&page=$page"
    $teams = Invoke-RestMethod -Uri $teamUrl -Headers $headers -Method Get
    foreach ($team in $teams) {
        $teamName = $team.name
        $slug = $team.slug
        $teamMembersUrl = "https://api.github.com/orgs/$org/teams/$slug/members"

        $memberPage = 1
        do {
            $membersUrlPaged = "$teamMembersUrl?per_page=100&page=$memberPage"
            $members = Invoke-RestMethod -Uri $membersUrlPaged -Headers $headers -Method Get

            foreach ($member in $members) {
                $teamMemberList += [PSCustomObject]@{
                    TeamName     = $teamName
                    MemberLogin  = $member.login
                    MemberRole   = $member.role
                }
            }

            $memberPage++
        } while ($members.Count -eq 100)
    }
    $page++
} while ($teams.Count -eq 100)

# Export to CSV
$teamMemberList | Export-Csv -Path "GitHub_Teams_Members.csv" -NoTypeInformation
Write-Output "Exported team-member list to GitHub_Teams_Members.csv"
