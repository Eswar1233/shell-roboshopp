#!/bin/bash

source ./common.sh
app_name=catalogue

check_root
app_setup
nodejs_setup
systemd_setup

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>$LOG_FILE
VALIDATE $? "copying mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installing Mongodb client"

STATUS=$(mongosh --host mongodb.squareladdu.in --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.squareladdu.in </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "loading master data into MongoDB"
else
    echo -e "Data is alreacdy loaded ... $Y SKIPPING $N"
fi

print_time