$ApiToken = 
$CsvFile = Join-Path -Path $OutputPath -ChildPath $FileName
$ApiEndpoint = "https://thrivent.service-now.com/api/now/table/sn_vul_vulnerable_item"
$BatchSize = 5000
$Offset = 0

# Define the fields to be returned by the API call.
$FieldsToRequest = @(
    "number",
    "vulnerability.vulnerability.ref_sn_vul_third_party_entry.cves_list",
    "vulnerability.name",
    "risk_score",
    "risk_rating",
    "cmdb_ci",
    "cmdb_ci.sys_class_name",
    "state",
    "sys_created_on",
    "last_found",
    "ttr_target_date",
    "vulnerability.summary",
    "short_description",
    "description"
) -join ','

$Query = 'sys_created_onBETWEENjavascript:gs.dateGenerate("2020-01-01","00:00:00")@javascript:gs.dateGenerate("2021-01-01","00:00:00")^ORDERBYnumber'

$Headers = @{
    "Accept"        = "application/json"
    "Authorization" = "Bearer $ApiToken"
}

$isFirstBatch = $true

while ($true) {
    Write-Host "Fetching records from offset $Offset..."
    $queryParams = @{
        "sysparm_limit"         = $BatchSize
        "sysparm_offset"        = $Offset
        "sysparm_fields"        = $FieldsToRequest
        "sysparm_display_value" = "true"
        "sysparm_query"         = $Query
    }

    try {
        $response = Invoke-RestMethod -Method Get -Uri $ApiEndpoint -Headers $Headers -Body $queryParams -ContentType "application/json" -ErrorAction Stop -TimeoutSec 120
    }
    catch {
        Write-Error "An error occurred while fetching data: $_"      
        break
    }

    $results = $response.result

    if (-not $results -or $results.Count -eq 0) {
        Write-Host "No more records to fetch. Script finished."
        break
    }

    $processedResults = foreach ($record in $results) {
        $properties = [ordered]@{}
        foreach ($property in $record.PSObject.Properties) {
            $key = $property.Name
            $value = $property.Value
            $finalValue = $null
            if ($value -is [System.Management.Automation.PSCustomObject] -and $value.PSObject.Properties.Name -contains 'display_value') {
                $finalValue = $value.display_value
            }
            else {
                $finalValue = $value
            }

            if ($finalValue -is [string]) {
                $properties[$key] = ($finalValue -replace '[\r\n]+', ' ').Trim()
            }
            else {
                $properties[$key] = $finalValue
            }
        }
        # Output a new custom object with the flattened properties.
        [PSCustomObject]$properties
    }

    # Export the processed data to the CSV file.
    if ($isFirstBatch) {
        # For the first batch, create the file and write the headers.
        $processedResults | Export-Csv -Path $CsvFile -NoTypeInformation -Force -Encoding UTF8
        $isFirstBatch = $false
    }
    else {
        # For subsequent batches, append to the existing file without headers.
        $processedResults | Export-Csv -Path $CsvFile -NoTypeInformation -Append -Encoding UTF8
    }

    Write-Host "Successfully fetched and saved $($processedResults.Count) records to $CsvFile."

    # Increment the offset for the next batch and pause briefly.
    $Offset += $BatchSize
    Start-Sleep -Seconds 2
}
