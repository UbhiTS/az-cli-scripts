# Sync CSV Tags
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
