$results = @()
$TagsAsString = ""
$datetime = Get-Date -Format "yyyyMMddhhmm"

foreach ($sub in Get-AzSubscription) {
    
    Set-AzContext -SubscriptionId $sub.SubscriptionId | Out-Null
    Write-Host $sub.Name

    foreach ($rg in Get-AzResourceGroup) {
        Write-Host "`t" $rg.ResourceGroupName

        foreach ($tag in $rg.Tags) {

            $Tags = $rg.Tags

            #Checkign if tags is null or have value
            if ($Tags -ne $null) {
                $Tags.GetEnumerator() | % { $TagsAsString += $_.Key + ":" + $_.Value + ";" }
            }
            else {
                $TagsAsString = "NULL"
            }

            $details = @{
                SubscriptionName = $sub.Name
                ResourceGroupName = $rg.ResourceGroupName
                Tags = $TagsAsString
            }

            $results += New-Object PSObject -Property $details

            #Clearing Variable
            $TagsAsString = ""
        }
    }
}

$OutputPathWithFileName = $OutputCSVFilePath + ".\Tags-" + $datetime + ".csv"

$results | Select-Object -Property SubscriptionName, ResourceGroupName, Tags
$results | Select-Object -Property SubscriptionName, ResourceGroupName, Tags | export-csv -Path $OutputPathWithFileName -NoTypeInformation

