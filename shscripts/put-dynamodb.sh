#!/bin/bash
LNCNT=$(cat sample.txt | grep -v STATUS | wc -l)
for ((i=0; i<=$LNCNT; i++));
    do
    chart=( $(cat sample.txt | grep -v STATUS | awk  '{print $9}') )
    #chart=${chart[$i]}
    echo $chart
    version=( $(cat sample.txt | grep -v STATUS | awk  '{print $10}') )
    #version=${version[$i]}
    echo $version
    echo "Here is my aws cli dynamodb command will run for $version  and $chart"
    aws dynamodb put-item --table-name env_release_versions --item '{"CLUSTER_NS": {"S": "'$CLUSTER_NS$i'"}, "CHARTS": {"S": '$CHARTS'}, "APP_VERSIONS": {"S": '$APP_VERSIONS'}}'

done

#########################################################################################################
#!/bin/bash

CHARTS=( $(cat sample.txt | grep -v STATUS | awk  '{print $9}') )

version=( $(cat sample.txt | grep -v STATUS | awk  '{print $10}') )

aws dynamodb put-item --table-name env_release_versions --item '{"CLUSTER_NS": {"S": "'$CLUSTER_NS'"}, "CHARTS": {"SS": ["'${CHARTS[0]}'","'${CHARTS[1]}'","'${CHARTS[2]}'","'${CHARTS[3]}'","'${CHARTS[4]}'","'${CHARTS[5]}'" ] }, "APP_VERSIONS": {"SS": ["'${version[0]}'", "'${version[1]}'" ] } }'  


##############################################
