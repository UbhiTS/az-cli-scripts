
$csv = Import-Csv ./costcentermap.csv
$headers=$csv[0].psobject.properties.name
$key=$headers[0]
$value=$headers[1]
$hash = @{}
$csv | ForEach-Object {$hash[$_."$key"] = $_."$value"}

foreach ($sub in Get-AzSubscription) {
    
    Set-AzContext -SubscriptionId $sub.SubscriptionId | Out-Null
    Write-Host $sub.Name

    foreach ($rg in Get-AzResourceGroup) {
        Write-Host "`t" $rg.ResourceGroupName

        foreach ($tag in $rg.Tags) {

            if (($null -ne $tag["costcenter"]) -and ($hash.ContainsKey($tag["costcenter"]))) {
                
                $cctags = @{ "oldcostcenter"=$tag["costcenter"]; "costcenter"=$hash[$tag["costcenter"]]; }
                Update-AzTag -ResourceId $rg.ResourceId -Tag $cctags -Operation Merge | Out-Null
                Write-Host "`t`t" $tag["costcenter"] ">" $hash[$tag["costcenter"]]
            }
        }
    }

    Write-Host
}
