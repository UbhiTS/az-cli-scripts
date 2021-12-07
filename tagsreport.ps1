$results = @()
$TagsAsString = ""
$datetime = Get-Date -Format "dd-MM-yy-hh-mm"

#Getting all Azure Resource
$resources = Get-AzureRmResource
foreach ($resource in $resources) {
    #Fetching Tags
    $Tags = $resource.Tags
    #Checkign if tags is null or have value
    if ($Tags -ne $null) {
        $Tags.GetEnumerator() | % { $TagsAsString += $_.Key + ":" + $_.Value + ";" }
    }
    else {
        $TagsAsString = "NULL"
    }

    #Adding to Results
    $details = @{
        ResourceGroup = $resource.ResourceGroupName
        Resource = $resource.Name
        Tags = $TagsAsString
    }

    $results += New-Object PSObject -Property $details

    #Clearing Variable
    $TagsAsString = ""
}

$OutputPathWithFileName = $OutputCSVFilePath + ".\Tags-" + $SubscriptionName + "-" + $datetime + ".csv"

$results | Select-Object -Property ResourceGroup, Resource, Tags
$results | Select-Object -Property ResourceGroup, Resource, Tags | export-csv -Path $OutputPathWithFileName -NoTypeInformation
