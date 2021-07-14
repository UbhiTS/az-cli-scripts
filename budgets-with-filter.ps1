#   usage: .\budgets-with-filter.ps1 <csv_file> [EXECUTE]
# example: .\budgets-with-filter.ps1 budgets-with-filter.csv [EXECUTE]

## PREPARE THE REQUEST TEMPLATE
$requestUrlTemplate = "https://management.azure.com/subscriptions/{{subscriptionId}}/providers/Microsoft.Consumption/budgets/{{budgetName}}?api-version={{apiVersion}}"
$requestBodyTemplate = @"
{
  "properties": {
    "category": "Cost",
    "amount": {{amount}},
    "timeGrain": "Monthly",
    "timePeriod": {
      "startDate": "{{startDate}}",
      "endDate": "{{endDate}}"
    },
    "filter": {
      "and": [
        {
          "tags": {
            "name": "{{tagName}}",
            "operator": "In",
            "values": [
              "{{tagValue}}"
            ]
          }
        }
      ]
    },
    "notifications": {
      "BudgetLimit": {
        "enabled": true,
        "operator": "GreaterThan",
        "threshold": 100,
        "locale": "en-us",
        "contactEmails": [
          "{{contactEmail1}}"
        ],
        "thresholdType": "Actual"
      }
    }
  }
}
"@

## GET THE ACCESS TOKEN FROM THE CURRENT CONTEXT
$azContext = Get-AzContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}

## READ THE CSV FILE
$csv = Import-Csv $args[0]
foreach ($row in $csv) {

    ## CONSTRUCT REQUEST URL FROM TEMPLATE
    $subscriptionId = $azContext.Subscription.Id
    $apiVersion = "2019-10-01"
    $requestUrl = $requestUrlTemplate
    $requestUrl = $requestUrl.Replace("{{subscriptionId}}",$subscriptionId)
    $requestUrl = $requestUrl.Replace("{{budgetName}}",$row.BudgetName)
    $requestUrl = $requestUrl.Replace("{{apiVersion}}",$apiVersion)

    ## CONSTRUCT REQUEST BODY FROM TEMPLATE
    $requestBody = $requestBodyTemplate
    $requestBody = $requestBody.Replace("{{amount}}",$row.Amount)
    $requestBody = $requestBody.Replace("{{startDate}}",$row.StartDate)
    $requestBody = $requestBody.Replace("{{endDate}}",$row.EndDate)
    $requestBody = $requestBody.Replace("{{tagName}}",$row.TagName)
    $requestBody = $requestBody.Replace("{{tagValue}}",$row.TagValue)
    $requestBody = $requestBody.Replace("{{contactEmail1}}",$row.ContactEmail1)

    #echo $requestUrl
    #echo $requestBody

    ## EXECUTE REQUEST
    if ("EXECUTE" -in $args -or "execute" -in $args) {
        $response = Invoke-RestMethod -Uri $requestUrl -Method Put -Headers $authHeader -Body $requestBody
        echo $response
    }
}
