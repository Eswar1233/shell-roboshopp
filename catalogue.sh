#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD  #starting ekkada undho adhi variable laga tesukuntundhi

mkdir -p $LOGS_FOLDER
echo "script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root privilages or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root Access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling default nodejs module"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enbaling required current nodejs module"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs"

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

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue"

rm -rf /app/* #app directory lo unna content ni delete chestham
cd /app  &>>$LOG_FILE
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzipping catalogue"

cd /app &>>$LOG_FILE
VALIDATE $? "Go to app directory"

npm install &>>$LOG_FILE
VALIDATE $? "Install npm"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "copying catalogue service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "daemon reloaded, enabling catalogue , starting catalogue"

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
