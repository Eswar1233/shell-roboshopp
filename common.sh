#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "script started executing at: $(date)" | tee -a $LOG_FILE

app_setup(){
    id roboshop &>>$LOG_FILE
    if [ $? -ne 0 ]
    then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
        VALIDATE $? "Creating system user"
    else
        echo -e "SYstem user roboshop is alrweady created ... $Y SKIPPING $N"
    fi

    mkdir -p /app &>>$LOG_FILE
    VALIDATE $? "Creating app directory"

    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$LOG_FILE
    VALIDATE $? "Downloading $app_name"

    rm -rf /app/* #app directory lo unna content ni delete chestham
    cd /app  &>>$LOG_FILE
    unzip /tmp/$app_name.zip &>>$LOG_FILE
    VALIDATE $? "unzipping $app_name"
}

nodejs_setup(){
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "disabling default nodejs module"

    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "Enbaling required current nodejs module"

    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "Installing nodejs"

    npm install &>>$LOG_FILE
    VALIDATE $? "Install npm"
}

systemd_setup(){
  cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service &>>$LOG_FILE
  VALIDATE $? "copying $app_name service"

  systemctl daemon-reload &>>$LOG_FILE
  systemctl enable $app_name &>>$LOG_FILE
  systemctl start $app_name &>>$LOG_FILE
  VALIDATE $? "daemon reloaded, enabling $app_name , starting $app_name"
}

check_root(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R ERROR:: Please run this script with root Access $N" | tee -a $LOG_FILE
        exit 1 #give other than 0 upto 127
    else
        echo "You are running with root access" | tee -a $LOG_FILE
    fi
}

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
    fi
}

print_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(($END_TIME - $START_TIME))
    echo -e "Script executed successfully. $Y Time taken: $TOTALTIME seconds"
}