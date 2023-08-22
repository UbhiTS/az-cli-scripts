# configuration parameters
$PullPolicyInfo = $true

# create reports directory if not exists
$WorkingDir = (Get-Location).Path
$GPRSOPReportsDir = "$WorkingDir\GPRSOPReports"
if(!(test-path -PathType container $GPRSOPReportsDir)) { New-Item -ItemType Directory -Path $GPRSOPReportsDir }

# get all computers objects in your active directory
$Computers = Get-ADComputer -Filter * | Select-Object Name, DNSHostName, ObjectClass, ObjectGuid, SAMAccountName, SID

# pull "Resultant Set of GPOs" from each computer
if ($PullPolicyInfo) {
    foreach ($Computer in $Computers) {
        $ComputerName = $Computer.DNSHostName
        Get-GPResultantSetOfPolicy -Computer $ComputerName -ReportType XML -Path "$GPRSOPReportsDir\$computername.xml"
    }
}

# get all xml reports generated from previous step
$RSOPReportFiles = Get-ChildItem $GPRSOPReportsDir -Filter *.xml

# extract the GPOs applied to each computer from the xmls and store into a collection variable
$ComputerGPOs = foreach ($RSOPReportFile in $RSOPReportFiles) {

    $filename = $RSOPReportFile.Name
    $filepath = $RSOPReportFile.FullName

    $RSOPReport = [xml](Get-Content $filepath)
    $GPOs = $RSOPReport.Rsop.ComputerResults.GPO
   
    [PSCustomObject]@{
        "ComputerName" = $filename.Replace(".xml", "")
        "GPOs" = $GPOs | Select -ExpandProperty Name | Sort
    }
}

# [debug] Computer to GPO Mapping Console Output
# $ComputerGPOs | Sort-Object ComputerName | Format-Table -AutoSize -Wrap

# get unique GPO names and Computer Name (to form a matrix)
$UniqueComputers = $ComputerGPOs.ComputerName | Select -Unique | Sort
$UniqueGPOs = $ComputerGPOs.GPOs | Select -Unique | Sort

# pivot the data for GPOs to create a table (matrix) structure
$GPOComputers = foreach ($UniqueGPO in $UniqueGPOs) {

    $Computers = [PSCustomObject]@{ GPOName = $UniqueGPO }

    foreach ($ComputerGPO in $ComputerGPOs) {
        $GPOApplies = $null
        if ($ComputerGPO.GPOs -contains $UniqueGPO) { $GPOApplies = "Y" }
        $Computers | Add-Member -NotePropertyName $ComputerGPO.ComputerName -NotePropertyValue $GPOApplies
    }

    $Computers
}

# output the result
$GPOComputers | Format-Table -AutoSize -Wrap

# export the result to a CSV file
$GPOComputers | Export-Csv -Path GPOComputers.csv -NoTypeInformation -Delimiter ',' -Force
