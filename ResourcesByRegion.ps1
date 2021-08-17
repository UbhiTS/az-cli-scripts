# Azure Resource Graph Query = resources | summarize instances = count() by type
# Export CSV Results to "ResourcesByRegion.csv"
# Modify ResourcesByRegion.ps1 with the Regions you want to check services for
# Run the PowerShell script with ./ResourcesByRegion.ps1
# The results will be appended in the same input CSV file "ResourcesByRegion.csv"

$locations = ("Global","West US","West US 2","West US 3")
$result= @()
$csv = Import-Csv "ResourcesByRegion.csv"
$csv | Foreach-Object {

    $providerNs = $_.TYPE
    $resourceType = $_.TYPE
    $splitpoint = $_.TYPE.IndexOf('/')
    
    if ($splitpoint -gt -1) {
        $providerNs = $_.TYPE.Substring(0, $splitpoint)
        $resourceType = $_.TYPE.Substring($splitpoint + 1, $resourceType.Length - $splitpoint - 1)
    }

    $data = [PSCustomObject]@{
        TYPE = $_.TYPE
        INSTANCES = $_.INSTANCES
        #ProviderNamespace = $providerNs
        #ResourceType = $resourceType
        Locations = ((((Get-AzResourceProvider -ProviderNamespace $providerNs).ResourceTypes | where ResourceTypeName -eq $resourceType).Locations | where {$locations -contains $_} | Sort-Object) -join ",")
    }

    $result += $data

    Write-Output ($data | ft -HideTableHeaders | Out-String).Trim()
}

$result | Export-Csv -Delimiter "," -Path "ResourcesByRegion.csv"
