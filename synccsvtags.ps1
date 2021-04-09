#   usage: .\synccsvtags.ps1 <csv_file> <azure_subscription_id> [EXECUTE]
# example: .\synccsvtags.ps1 tags.csv 11111111-1111-1111-1111-111111111111 [EXECUTE]

$csv = Import-Csv $args[0]
$headers = ($csv | Get-Member -MemberType NoteProperty).Name
foreach ($row in $csv) {
    $tags = ""
    #$csv.IndexOf($row)
    foreach ($header in $headers) {
        if ($header -eq "ResourceName") { continue }
        $tags = $tags + " " + $header + "=" + $row.$header
    }

    $azclicommand="az tag update --resource-id /subscriptions/" + $args[1] + "/resourcegroups/" + $row.ResourceName + " --operation merge --tags" + $tags
    write-host $azclicommand

    if ("EXECUTE" -in $args -or "execute" -in $args) {
        iex $azclicommand
    }
}
