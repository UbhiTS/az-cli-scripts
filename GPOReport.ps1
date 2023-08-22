# import reusable code
Import-Module .\ADHelper.psm1

# create reports directory if not exists
$WorkingDir = (Get-Location).Path
$GPOReportsDir = "$WorkingDir\GPOReports"
if(!(test-path -PathType container $GPOReportsDir)) { New-Item -ItemType Directory -Path $GPOReportsDir }

# pull GPO information from DC
# Get-GPOReport -All -ReportType XML -Path "$GPOReportsDir\gpo.xml"

# get all xml reports generated from previous step
$GPOReportFiles = Get-ChildItem $GPOReportsDir -Filter *.xml

# extract the SOMPath(s) which each GPO links to
$GPOComputers = foreach ($GPOReportFile in $GPOReportFiles) {

    $filename = $GPOReportFile.Name
    $filepath = $GPOReportFile.FullName

    $GPOReport = [xml](Get-Content $filepath)
    $GPOs = $GPOReport.report.GPO
   
    foreach ($GPO in $GPOs) {
        foreach ($GPOLinksTo in $GPO.LinksTo) {
            $OUPath = ConvertFrom-CanonicalOU($GPOLinksTo.SOMPath)
            
            foreach ($Computer in (Get-ADComputer -Filter * -SearchBase $OUPath)) {
                [PSCustomObject]@{
                    "GPOName" = $GPO.Name
                    "SOMPath" = $GPOLinksTo.SOMPath
                    "ComputerName" = $Computer.Name # DNSHostName, ObjectClass, ObjectGuid, SAMAccountName, SID
                }
            }
        }
    }
}

$GPOComputers

# get unique GPO names and Computer Name (to form a matrix)
$UniqueGPOs = $GPOComputers.GPOName | Select -Unique | Sort
$UniqueComputers = $GPOComputers.ComputerName | Select -Unique | Sort

# parse the data for GPOs and Computers to create a table (matrix) structure
$ResultMatrix = foreach ($UniqueGPO in $UniqueGPOs) {

    $ResultRow = [PSCustomObject]@{ GPOName = $UniqueGPO }

    foreach ($UniqueComputer in $UniqueComputers) {
        $GPOApplies = $null
        if ($GPOComputers | where {$_.GPOName -eq $UniqueGPO -and $_.ComputerName -eq $UniqueComputer}) { $GPOApplies = "Y" }
        $ResultRow | Add-Member -NotePropertyName $UniqueComputer -NotePropertyValue $GPOApplies
    }

    $ResultRow
}

# output the result
# $ResultMatrix | Format-Table -AutoSize -Wrap

# export the result to a CSV file
$GPOComputers | Export-Csv -Path GPOReport.csv -NoTypeInformation -Delimiter ',' -Force
$ResultMatrix | Export-Csv -Path GPOReportMatrix.csv -NoTypeInformation -Delimiter ',' -Force
