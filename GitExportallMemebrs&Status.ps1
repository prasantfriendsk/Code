$org = "your-org-name"
$token = "your_github_token"
$outputFile = "GitHubMembersWithStatus.csv"

$membersUrl = "https://api.github.com/orgs/$org/members"
$page = 1
$perPage = 100
$allMembers = @()

do {
    Write-Host "Fetching page $page..."

    $response = & curl.exe -s `
        -H "Authorization: Bearer $token" `
        -H "Accept: application/vnd.github+json" `
        -H "User-Agent: PowerShellScript" `
        "$membersUrl?per_page=$perPage&page=$page"

    $json = $response | ConvertFrom-Json

    if (-not $json -or $json.Count -eq 0) { break }

    foreach ($user in $json) {
        $username = $user.login

        $membershipResponse = & curl.exe -s `
            -H "Authorization: Bearer $token" `
            -H "Accept: application/vnd.github+json" `
            -H "User-Agent: PowerShellScript" `
            "https://api.github.com/orgs/$org/memberships/$username"

        $membership = $membershipResponse | ConvertFrom-Json

        $allMembers += [PSCustomObject]@{
            Login            = $user.login
            Id               = $user.id
            Url              = $user.html_url
            Type             = $user.type
            Site_Admin       = $user.site_admin
            Membership_State = $membership.state
            Role             = $membership.role
        }

        Start-Sleep -Milliseconds 300
    }

    $page++
    Start-Sleep -Seconds 1
} while ($true)

$allMembers | Export-Csv -Path $outputFile -NoTypeInformation
Write-Host "Exported $($allMembers.Count) members to $outputFile"
