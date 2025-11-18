#!/bin/bash

source ./common.sh
check_root

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling default nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enabling  nginx"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing nginx"

systemctl enable nginx &>>$LOG_FILE
systemctl start nginx  &>>$LOG_FILE
VALIDATE $? "enable nginx, start nginx"


rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing defauklt content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html  &>>$LOG_FILE
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzipping frontend"

rm -rf /etc/nginx/nginx.conf &>>$LOG_FILE #remove nginx.conf as we dont vim editor and read the content 
VALIDATE $? "Remove default nginx conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "Copying nginx conf"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restarting nginx conf"

print_time