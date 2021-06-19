#!/bin/bash

#   usage: bash budgets.sh <csv_file> [EXECUTE]
# example: bash budgets.sh budgets.csv [EXECUTE]

lines=()

# read file
while IFS= read -r x
do
    lines+=("$x")
done < $1

declare -A headers
#echo "${!headers[@]}" # ALL KEYS
#echo "${headers[@]}" # ALL VALUES
#echo "${headers[TagValue]}" # SPECIFIC KEY
#echo "${#headers[@]}" # COUNT OF KEY/VALUE PAIRS

# split into lines
for line_no in "${!lines[@]}"
do
    line="${lines[line_no]}"

    if [[ line_no -eq 0 ]] # HEADER ROW
    then
        IFS="," read -a headersArr <<< $line

        for header_no in "${!headersArr[@]}"
        do
            headers["${headersArr[header_no]}"]="$header_no"
        done
    else # DATA ROW
        IFS="," read -a dataArr <<< $line

        subscriptionId="${dataArr[${headers[SubscriptionId]}]}"
        tagName="${dataArr[${headers[TagName]}]}"
        tagValue="${dataArr[${headers[TagValue]}]}"
        budgetName="${dataArr[${headers[BudgetName]}]}"
        amount="${dataArr[${headers[Amount]}]}"
        startDate="$(date --date=${dataArr[${headers[StartDate]}]} '+%F')"
        endDate="$(date --date=${dataArr[${headers[EndDate]}]} '+%F')"
        timeGrain="${dataArr[${headers[TimeGrain]}]}"

        echo "## SID:$subscriptionId |$tagName:$tagValue| BUDGET:$budgetName AMOUNT:$amount START:$startDate END:$endDate TIMEGRAIN:$timeGrain"

        groupsCLIQuery="az group list --subscription $subscriptionId --query \"[?tags.$tagName == '$tagValue'].{ResourceGroup:name}\" -o tsv | sort | uniq"
        #echo "$groupsCLIQuery"

        groupsResults="$(eval $groupsCLIQuery)"
        #echo "$groupsResults"

        IFS=$'\n' read -a groupsArr -d '' <<< "$groupsResults"
        #echo "${groupsArr[@]}"

        for group in "${groupsArr[@]}"
        do
        
            budgetCLIQuery="az consumption budget create --subscription $subscriptionId --resource-group $group --budget-name $budgetName --category cost --amount $amount --start-date $startDate --end-date $endDate --time-grain $timeGrain"
            echo "$budgetCLIQuery"

            if [ ! -z "$2" ] && ([ $2 == "EXECUTE" ] || [ $2 == "execute" ])
            then
                eval $budgetCLIQuery
            fi

        done

        echo
        echo

    fi

done
