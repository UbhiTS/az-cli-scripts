#!/bin/bash

#   usage: bash synccsvtags.sh <csv_file> <azure_subscription_id> [EXECUTE]
# example: bash synccsvtags.sh tags.csv 11111111-1111-1111-1111-111111111111 [EXECUTE]

lines=()

# read file
while IFS= read -r x
do
    lines+=("$x")
done < $1

tagnames=()

# split into lines
for line in "${!lines[@]}"
do

    IFS=',' read -r -a tags <<< "${lines[line]}"

    # get headers
    if [[ line -eq 0 ]]
    then
        tagnames=("${tags[@]}")
        continue
    fi

    new_tags=""

    # get tag values
    for index in "${!tags[@]}"
    do

        # skip resource name column
        if [[ index -eq 0 ]]
        then
            continue
        fi

        new_tags="${new_tags} ${tagnames[index]}=${tags[index]}"
        
    done

    #echo "$line : ${tags[0]} ${new_tags}"

    azclicommand="az tag create --resource-id /subscriptions/$2/resourcegroups/${tags[0]} --tags ${new_tags}"
    echo $azclicommand

    if [ ! -z "$3" ] && ([ $3 == "EXECUTE" ] || [ $3 == "execute" ])
    then
        eval $azclicommand
    fi
    
    echo

done
