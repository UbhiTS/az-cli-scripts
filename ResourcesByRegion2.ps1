# ============================================================================================================================================
# Required: Install-Module -Name Az.ResourceGraph
# Locations List: Get-AzLocation | Select-Object DisplayName, PhysicalLocation, GeographyGroup, PairedRegion | Sort-Object "DisplayName"  | ft
# --------------------------------------------------------------------------------------------------------------------------------------------
# Modify ResourcesByRegion2.ps1 with the Regions you want to check services for
# Run the PowerShell script with ./ResourcesByRegion2.ps1
# The results will be shown on the screen and saved in "ResourcesByRegion2.csv" file
#
# To verify the locations of a single Resource Type, run the following command replacing the Provider and ResourceType
# ((Get-AzResourceProvider -ProviderNamespace "microsoft.labservices").ResourceTypes | where ResourceTypeName -eq "labplans").Locations
# ============================================================================================================================================


$regions = ("Global", "United States", "West US", "West US 2", "West US 3", "East US", "South Central US")


$headers = [PSCustomObject]@{ Type = $null; Instances = $null }
$regions | Foreach-Object { $headers | Add-Member -MemberType NoteProperty $_ -Value $null }
$result = @($headers)

$services = (Search-AzGraph -Query 'resources | summarize instances = count() by type | order by type asc')
$services | Foreach-Object {

    Write-Host (($services.IndexOf($_) + 1).ToString() + "/"+ $services.Count.ToString() + " > " + $_.TYPE)

    $providerNs = $_.TYPE
    $resourceType = $_.TYPE
    $splitpoint = $_.TYPE.IndexOf('/')
    
    if ($splitpoint -gt -1) {
        $providerNs = $_.TYPE.Substring(0, $splitpoint)
        $resourceType = $_.TYPE.Substring($splitpoint + 1, $resourceType.Length - $splitpoint - 1)
    }

    $data = [PSCustomObject]@{ Type = $_.TYPE; Instances = $_.INSTANCES }
    $locations = (((Get-AzResourceProvider -ProviderNamespace $providerNs).ResourceTypes | where ResourceTypeName -eq $resourceType).Locations | where {$regions -contains $_})
    $locations | Foreach-Object { $data | Add-Member -MemberType NoteProperty $_ -Value "Yes" }

    $result += $data
}

$result | Export-Csv -Delimiter "," -Path "ResourcesByRegion2.csv"
$result | Format-Table -AutoSize
