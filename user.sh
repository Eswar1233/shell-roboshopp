#!/bin/bash

source ./common.sh
app_name=user

check_root
nodejs_setup


id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "SYstem user roboshop is alrweady created ... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading user"

rm -rf /app/* #app directory lo unna content ni delete chestham
cd /app  &>>$LOG_FILE
unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "unzipping user"

cd /app &>>$LOG_FILE
VALIDATE $? "Go to app directory"

npm install &>>$LOG_FILE
VALIDATE $? "Install npm"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOG_FILE
VALIDATE $? "copying user service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable user &>>$LOG_FILE
systemctl start user &>>$LOG_FILE
VALIDATE $? "daemon reloaded, enabling user , starting user"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>$LOG_FILE
VALIDATE $? "copying mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installing Mongodb client"

print_time
