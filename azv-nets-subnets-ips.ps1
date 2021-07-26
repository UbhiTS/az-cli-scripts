Get-AzSubscription | Foreach-Object {
    $sub = Set-AzContext -SubscriptionId $_.SubscriptionId
    $vnets = Get-AzVirtualNetwork

    foreach ($vnet in $vnets) {
        [PSCustomObject]@{
            SubscriptionName = $sub.Subscription.Name
            VNetName = $vnet.Name
            VNetAddressSpaces = $vnet.AddressSpace.AddressPrefixes -join ','
        }
    }
} | Export-Csv -Delimiter ";" -Path "VNets.csv"

Get-AzSubscription | Foreach-Object {
    $sub = Set-AzContext -SubscriptionId $_.SubscriptionId
    $vnets = Get-AzVirtualNetwork

    foreach ($vnet in $vnets) {
        foreach($subnet in $vnet.Subnets)
        {
            [PSCustomObject]@{
                SubscriptionName = $sub.Subscription.Name
                VNetName = $vnet.Name
                SubnetName = $subnet.Name
                SubnetAddressPrefix = $subnet.AddressPrefix -join ','
                UsedIPs = $subnet.IpConfigurations.Count
                FreeIPs = [math]::Pow(2, (32 - $subnet.AddressPrefix.Split("/")[1])) - 5 - $subnet.IpConfigurations.Count # 5 IPs are used by Azure Networking
            }
        }
    }
} | Export-Csv -Delimiter ";" -Path "Subnets.csv"
