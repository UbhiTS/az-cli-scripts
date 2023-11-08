$report = @()

$vms = Get-AzVM

foreach ($vm in $vms) {

    $vmName = $vm.Name
    $resourceGroupName = $vm.ResourceGroupName
    $region = $vm.Location
    $vmSize = $vm.HardwareProfile.VmSize
    $osType = $vm.StorageProfile.ImageReference.Sku + " " + $vm.StorageProfile.ImageReference.Offer

    $sizeDetails = Get-AzVMSize -Location $vm.Location | where {$_.Name -eq $vm.HardwareProfile.VmSize}
    $cores = $sizeDetails.NumberOfCores
    $memory = $sizeDetails.MemoryInMB

    $diskType = 'OS'
    $diskName = $vm.StorageProfile.OsDisk.Name
    $lun = $null
    $diskSize = (Get-AzDisk -DiskName $diskName).DiskSizeGB

    # ------------------------------------------------
    # Uncomment the below to show the OS Disks as well
    # ------------------------------------------------
    # $report += [pscustomobject]@{ vmName = $vmName; resourceGroupName = $resourceGroupName; region = $region; vmSize = $vmSize; osType = $osType; cores = $cores; memory = $memory; diskType = $diskType; diskSizeGB = $diskSize; lun = $lun; diskName = $diskName; maxIOPSPercent = $null; maxBandwidthPercent = $null}

    if ($vm.StorageProfile.DataDisks.Count -gt 0) {
        foreach ($dd in $vm.StorageProfile.DataDisks) {
            
            $diskType = 'Data'
            $diskName = $dd.Name
            $lun = $dd.Lun
            $diskSize = (Get-AzDisk -DiskName $diskName).DiskSizeGB

            $lunFilter = New-AzMetricFilter -Dimension LUN -Operator eq -Value $dd.Lun 
            $maxIOPSPerDay = Get-AzMetric -ResourceId $vm.Id -MetricName 'Data Disk IOPS Consumed Percentage' -TimeGrain 1.00:00:00 -AggregationType Maximum -StartTime (Get-Date).adddays(-30) -EndTime (Get-Date) -MetricFilter $lunFilter
            $maxBandwidthPerDay = Get-AzMetric -ResourceId $vm.Id -MetricName 'Data Disk Bandwidth Consumed Percentage' -TimeGrain 1.00:00:00 -AggregationType Maximum -StartTime (Get-Date).adddays(-30) -EndTime (Get-Date) -MetricFilter $lunFilter

            $maxIOPSPercent = 0.0
            $maxBandwidthPercent = 0.0

            foreach ($iopsVal in $maxIOPSPerDay.Data) {
                if ($iopsVal.Maximum -gt $maxIOPSPercent) {
                    $maxIOPSPercent = $iopsVal.Maximum
                }
            }

            foreach ($bandwidthVal in $maxBandwidthPerDay.Data) {
                if ($bandwidthVal.Maximum -gt $maxBandwidthPercent) {
                    $maxBandwidthPercent = $bandwidthVal.Maximum
                }
            }

            $report += [pscustomobject]@{ vmName = $vmName; resourceGroupName = $resourceGroupName; region = $region; vmSize = $vmSize; osType = $osType; cores = $cores; memory = $memory; diskType = $diskType; diskSizeGB = $diskSize; lun = $lun; diskName = $diskName; maxIOPSPercent = [int]$maxIOPSPercent; maxBandwidthPercent = [int]$maxBandwidthPercent}
        }
    }
}

$report | Sort-Object -Property VmName, LUN | ft VmName, LUN, DiskType, DiskName, DiskSizeGB, MaxIOPSPercent, MaxBandwidthPercent
