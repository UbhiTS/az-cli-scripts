Write-Output("Start")


# import reusable code
Import-Module .\GPOReportHelper.psm1
Write-Output("Imported modules")


# create reports directory if not exists
$WorkingDir = (Get-Location).Path
$GPOReportsDir = "$WorkingDir\GPOReports"
if(!(test-path -PathType container $GPOReportsDir)) { New-Item -ItemType Directory -Path $GPOReportsDir }
Write-Output("Created reports directory (if not exists)")


# pull GPO information from DC
Get-GPOReport -All -ReportType XML -Path "$GPOReportsDir\gpo.xml"
Write-Output("Pulled GPO information from DC")


# get all xml reports generated from previous step
$GPOReportFiles = Get-ChildItem $GPOReportsDir -Filter *.xml
Write-Output("Reading GPO files")


$GPOComputers = @()

# extract the SOMPath(s) which each GPO links to
foreach ($GPOReportFile in $GPOReportFiles) {

    $filename = $GPOReportFile.Name
    $filepath = $GPOReportFile.FullName

    Write-Output("`t" + "File: " + $filename)

    $GPOReport = [xml](Get-Content $filepath)
    $GPOs = $GPOReport.report.GPO
   
    foreach ($GPO in $GPOs) {
        Write-Output("`t`t" + "GPO: " + $GPO.Name)

        if ($GPO.Name -eq "Default Domain Policy") { continue }

        foreach ($GPOLinksTo in $GPO.LinksTo) {
            Write-Output("`t`t`t" + "SOMPath: " + $GPOLinksTo.SOMPath)

            $OUPath = ConvertFrom-CanonicalOU($GPOLinksTo.SOMPath)
            $Computers = Get-ADComputer -Filter * -SearchBase "$OUPath"
            
            foreach ($Computer in $Computers) {
                Write-Output("`t`t`t`t" + "Computer: " + $Computer.Name)

                $GPOComputers += [PSCustomObject]@{
                    "GPOName" = $GPO.Name
                    "SOMPath" = $GPOLinksTo.SOMPath
                    "ComputerName" = $Computer.Name # DNSHostName, ObjectClass, ObjectGuid, SAMAccountName, SID
                }
            }
        }
    }
}

# $GPOComputers

# export the result to a CSV file
Write-Output("Outputting Result: GPOReport.csv")
$GPOComputers | Export-Csv -Path GPOReport.csv -NoTypeInformation -Delimiter ',' -Force

# get unique GPO names and Computer Name (to form a matrix)
$UniqueGPOs = $GPOComputers.GPOName | Select -Unique | Sort
Write-Output("Created unique Computers list")


$UniqueComputers = $GPOComputers.ComputerName | Select -Unique | Sort
Write-Output("Created unique GPOs list")


$ResultMatrix = @()

# parse the data for GPOs and Computers to create a table (matrix) structure
Write-Output("Creating result matrix")
foreach ($UniqueGPO in $UniqueGPOs) {
    Write-Output("`t" + $UniqueGPO)

    $ResultRow = [PSCustomObject]@{ GPOName = $UniqueGPO }

    foreach ($UniqueComputer in $UniqueComputers) {
        Write-Output("`t`t" + $UniqueComputer)

        $GPOApplies = $null
        if ($GPOComputers | where {$_.GPOName -eq $UniqueGPO -and $_.ComputerName -eq $UniqueComputer}) { $GPOApplies = "Y" }
        $ResultRow | Add-Member -NotePropertyName $UniqueComputer -NotePropertyValue $GPOApplies
    }

    $ResultMatrix += $ResultRow
}

# output the result
# $ResultMatrix | Format-Table -AutoSize -Wrap

# export the result to a CSV file
Write-Output("Outputting Result: GPOReportMatrix.csv")
$ResultMatrix | Export-Csv -Path GPOReportMatrix.csv -NoTypeInformation -Delimiter ',' -Force

Write-Output("Finish")
