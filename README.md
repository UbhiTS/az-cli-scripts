# Sync CSV Tags (Azure CLI Bash)
Sync Tags to Azure Resources or Resource Groups from a CSV file

Usage
---------------
bash synccsvtags.sh <csv_file> <azure_subscription_id>

Example
--------------
bash synccsvtags.sh tags.csv 11111111-1111-1111-1111-111111111111

CSV Sample
---------------
```csv
ResourceName,Tag1,Tag2,Tag3,Tag4
RG1,aaaa,bbbb,cccc,dddd
RG2,eeee,ffff,gggg,hhhh
```

Output
---------------
```shell
az tag create --resource-id /subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/RG1 --tags Tag1=aaaa Tag2=bbbb Tag3=cccc Tag4=dddd
az tag create --resource-id /subscriptions/11111111-1111-1111-1111-111111111111/resourcegroups/RG2 --tags Tag1=eeee Tag2=ffff Tag3=gggg Tag4=hhhh
```
