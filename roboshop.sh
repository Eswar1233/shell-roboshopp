#!/bin/bash


AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-06d806d4818b5c861"
# SUBNET_ID="subnet-069fb883317c20484" #it is taken as default
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "user" "cart" "shipping" "payment" "dispatch" "frontend" "catalogue")
ZONE_ID="Z1011474241AR8ZUHCM8Y" # present in route 53
DOMAIN_NAME="squareladdu.in" # present in route 53


for instance in ${INSTANCES[@]}
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-06d806d4818b5c861 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query "Instances[0].InstanceId" --output text)
    if [ $instance != "frontend" ]
    then 
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text) 
    fi  
    echo "$instance IP Address: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating or Updating a record set for cognito endpoint",
        "Changes": [{
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "'$instance'.'$DOMAIN_NAME'",
            "Type": "A",
            "TTL": 1,
            "ResourceRecords": [{ 
                "Value": "'$IP'"
            }]
        }
        }]
    }'
done