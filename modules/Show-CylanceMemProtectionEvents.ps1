function Show-CylanceMemProtectionEvents {
    param(
        [parameter(Mandatory = $false)]
        [String]$applicationId,
        [parameter(Mandatory = $false)]
        [String]$applicationSecret,
        [parameter(Mandatory = $false)]
        [String]$tenantId,
        [parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]$count = 10,
        [parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [ValidateSet("apne1", "au", "euc1", "sae1", "us")]
        [String]$region
    )

    Write-Banner
    try {
        $bearerToken = Get-BearerToken -applicationId $applicationId -applicationSecret $applicationSecret -tenantId $tenantId -region $region
        Write-HostAs -mode "Info" -message "Fetching data, this may take a while."
        $response = Get-MemProtectionEvents -count $count -bearerToken $bearerToken -region $region
        $memProtectionEvents = $response | ForEach-Object { $_.created = [DateTime]$_.created; $_ }

        foreach ($memProtectionEvent in $memProtectionEvents) {
            try {
                $fullDevice = Get-FullCylanceDevice -device $memProtectionEvent.device_id -bearerToken $bearerToken -region $region
                $memProtectionEvent | Add-Member -NotePropertyName "device_name" -NotePropertyValue $fullDevice.name
                $memProtectionEvent | Add-Member -NotePropertyName "device_policy" -NotePropertyValue $fullDevice.policy.name
            }
            catch {
                Write-HostAs -mode "Error" -message "Can't get full device details for $($device.name)."
                Write-Error "$($device.name): $($_.Exception.Message)"
            }
            $memProtectionEvent | Add-MemProtectionActionDescription
            $memProtectionEvent | Add-MemProtectionViolationTypeDescription
        }

        if ($memProtectionEvents.Count -gt 0) {
            Write-Host ($memProtectionEvents | Select-Object @{Name = 'Image'; Expression = { "$($_.image_name) ($($_.process_id))" } },
                @{Name = 'User'; Expression = { "$($_.user_name)" } },
                @{Name = 'Device'; Expression = { "$($_.device_name)" } },
                @{Name = 'Device policy'; Expression = { "$($_.device_policy)" } },
                @{Name = 'Violation type'; Expression = { "$($_.violation_type_description)" } },
                @{Name = 'Action'; Expression = { "$($_.action_description)" } },
                @{Name = 'Created'; Expression = { $_.created } } | Format-Table -Wrap -AutoSize | Out-String)
        }
        else {
            Write-HostAs -mode "Info" -message "No memory protection events were found."
        }
    }
    catch {
        Write-ExceptionToConsole($_)
    }
}
