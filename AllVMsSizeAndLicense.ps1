$result = @()

Get-AzSubscription | Foreach-Object {
    $sub = Set-AzContext -SubscriptionId $_.SubscriptionId
    $vms = Get-AzVM

    foreach ($vm in $vms) {

        $result += [PSCustomObject]@{
            SubscriptionName = $sub.Subscription.Name
            ResourceGroupName = $vm.ResourceGroupName
            VMName = $vm.Name
            Location = $vm.Location
            VMSize = $vm.HardwareProfile.vmSize
            vCPUs = (Get-AzVMSize -VMName $vm.Name -ResourceGroupName $vm.ResourceGroupName | where{$_.Name -eq $vm.HardwareProfile.vmSize}).NumberOfCores
            MemoryInGB = (Get-AzVMSize -VMName $vm.Name -ResourceGroupName $vm.ResourceGroupName | where{$_.Name -eq $vm.HardwareProfile.vmSize}).MemoryInMB / 1024
            LicenseType = $vm.LicenseType
        }
    }
}

$result | Format-Table -AutoSize -Wrap
