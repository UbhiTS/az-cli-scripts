#   usage: .\budgets-with-filter.ps1 <csv_file> [EXECUTE]
# example: .\budgets-with-filter.ps1 budgets-with-filter.csv [EXECUTE]

## PREPARE THE REQUEST TEMPLATE
$requestUrlTemplate = "https://management.azure.com/subscriptions/{{subscriptionId}}/providers/Microsoft.Consumption/budgets/{{budgetName}}?api-version={{apiVersion}}"
$requestBodyTemplate = @"
{
    "name": "{{budgetName}}",
    "eTag": null,
    "properties": {
        "category": "Cost",
        "amount": {{amount}},
        "timeGrain": "Monthly",
        "timePeriod": {
            "startDate": "{{startDate}}",
            "endDate": "{{endDate}}"
        },
        "notifications": {
            "Actual_GreaterThan_80_Percent": {
                "enabled": true,
                "operator": "GreaterThan",
                "threshold": 80,
                "contactEmails": [
                    "{{contactEmail1}}",
                    "{{contactEmail2}}"
                ],
                "contactRoles": [],
                "contactGroups": [],
                "thresholdType": "Actual",
                "locale": null
            },
            "Actual_GreaterThan_100_Percent": {
                "enabled": true,
                "operator": "GreaterThan",
                "threshold": 100,
                "contactEmails": [
                    "{{contactEmail1}}",
                    "{{contactEmail2}}"
                ],
                "contactRoles": [],
                "contactGroups": [],
                "thresholdType": "Actual",
                "locale": null
            }
        },
        "filter": {
            "tags": {
                "name": "{{tagName}}",
                "operator": "In",
                "values": [
                    "{{tagValue}}"
                ]
            }
        }
    }
}
"@

$i = 0

## READ THE CSV FILE
$csv = Import-Csv $args[0]
foreach ($row in $csv) {

    $i++

    write-host 'PROCESSING: Line'$i' -' $row.BudgetName ' ' -ForegroundColor Cyan

    ## SET THE SUBSCRIPTION
    if ($row.SubscriptionName -ne $null -and $row.SubscriptionName -ne "") {
        Set-AzContext -SubscriptionName $row.SubscriptionName
    } 
    elseif ($row.SubscriptionId -ne $null -and $row.SubscriptionId -ne "") {
        Set-AzContext -SubscriptionId $row.SubscriptionId
    }
    else {
        write-host 'ERROR: No Subscription Name or ID given' -ForegroundColor Red
        continue
    }

    ## GET THE ACCESS TOKEN FOR THE SUBSCRIPTION
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    $authHeader = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $token.AccessToken
    }

    ## CONSTRUCT REQUEST URL FROM TEMPLATE
    $subscriptionId = $azContext.Subscription.Id
    $apiVersion = "2019-10-01"
    $requestUrl = $requestUrlTemplate
    $requestUrl = $requestUrl.Replace("{{subscriptionId}}",$subscriptionId)
    $requestUrl = $requestUrl.Replace("{{budgetName}}",$row.BudgetName)
    $requestUrl = $requestUrl.Replace("{{apiVersion}}",$apiVersion)

    ## CONSTRUCT REQUEST BODY FROM TEMPLATE
    $requestBody = $requestBodyTemplate
    $requestBody = $requestBody.Replace("{{budgetName}}",$row.BudgetName)
    $requestBody = $requestBody.Replace("{{amount}}",$row.Amount)
    $requestBody = $requestBody.Replace("{{startDate}}",$row.StartDate)
    $requestBody = $requestBody.Replace("{{endDate}}",$row.EndDate)
    $requestBody = $requestBody.Replace("{{tagName}}",$row.TagName)
    $requestBody = $requestBody.Replace("{{tagValue}}",$row.TagValue)
    $requestBody = $requestBody.Replace("{{contactEmail1}}",$row.ContactEmail1)
    $requestBody = $requestBody.Replace("{{contactEmail2}}",$row.ContactEmail2)

    #echo $requestUrl
    #echo $requestBody

    ## EXECUTE REQUEST
    if ("EXECUTE" -in $args -or "execute" -in $args) {
        $response = Invoke-RestMethod -Uri $requestUrl -Method Put -Headers $authHeader -Body $requestBody
        echo $response
    }

    write-host 'COMPLETE' -ForegroundColor Green
}

write-host 'FILE PROCESSED' -ForegroundColor Green
