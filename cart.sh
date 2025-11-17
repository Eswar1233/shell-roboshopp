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

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))

echo -e "Script exception completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
