# Sync CSV Tags (Azure CLI BASH or PowerShell)
Sync Tags to Azure Resources or Resource Groups from a CSV file

- one execution for all tags per resource
- pass in any number of tags in the CSV file, it's not hardcoded :)
- see the actual Azure CLI commands that will run before you choose to execute

Usage
---------------
Bash
```shell
bash synccsvtags.sh <csv_file> <azure_subscription_id> [EXECUTE]
```
PowerShell
```shell
.\synccsvtags.ps1 <csv_file> <azure_subscription_id> [EXECUTE]
```

Example
--------------
To just view the commands: 
```shell
bash synccsvtags.sh tags.csv 11111111-1111-1111-1111-111111111111
```
To execute the commands:
```shell
bash synccsvtags.sh tags.csv 11111111-1111-1111-1111-111111111111 EXECUTE
```

Output
---------------
```shell
az tag create --resource-id /subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/RG1 --tags Tag1=aaaa Tag2=bbbb Tag3=cccc Tag4=dddd
az tag create --resource-id /subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/RG2 --tags Tag1=eeee Tag2=ffff Tag3=gggg Tag4=hhhh
```

CSV Sample
---------------
```csv
ResourceName,Tag1,Tag2,Tag3,Tag4
RG1,aaaa,bbbb,cccc,dddd
RG2,eeee,ffff,gggg,hhhh
```
