Get-AzSubscription | Foreach-Object {
    $sub = Set-AzContext -SubscriptionId $_.SubscriptionId
    $vms = Get-AzVM

    foreach ($vm in $vms) {
        [PSCustomObject]@{
            SubscriptionName = $sub.Subscription.Name
            ResourceGroupName = $vm.ResourceGroupName
            VMName = $vm.Name
            Location = $vm.Location
            VMSize = $vm.HardwareProfile.vmSize
        }
    }
} | Export-Csv -Delimiter "," -Path "vms.csv"
