#!/bin/bash
FILES=test/*.tst
for f in $FILES
do
  echo "Processing $f file..."
  declare -A expected 
  while read -r line
  do
    pair=(${line//=/ })
    if [ ${pair[0]} != "IMAGE" ]
    then
      expected[${pair[0]}]=${pair[1]}
    else
      IMG=${pair[1]}
    fi
  done < "$f"

  declare -A ispresult
  while read -r line
  do
    pair=(${line//=/ })
    ispresult[${pair[0]}]=${pair[1]}
  done < <(./isp.sh test/${IMG}) 
  
  for key in "${!expected[@]}"
  do
    orgvalue=${expected[$key]}
    curvalue=${ispresult[$key]}
    if [ "$orgvalue" != "$curvalue" ]
    then
       echo "Error in $key, expected: $orgvalue got: $curvalue"
       exit
    fi
    #echo "Key: $key Value: ${expected[$key]}"
  done

done
