#!/bin/bash


USERID=$(id -u)
R="\e[31m"
G="\e[32m"
y="\e[31m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$( echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ] #$?privious output will come here as input
    then    
        echo "$2 ...$R failure"
        exit 1
    else
        echo "$2 ... $G success"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ] #ne=not equal
    then 
        echo "ERROR:: you must have sudo access to excute this script"
        exit 1 #other then 0
    fi
}

echo "Script started excuting at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf install mysql-server -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MYSQL server"

systemctl enable mysqld &>>$LOG_FILE_NAME
VALIDATE $? "enabling MYSQL server"

systemctl start mysqld &>>$LOG_FILE_NAME
VALIDATE $? "starting MYSQL server"

mysql_secure_installation --set-root-pass ExpenseApp@1
VALIDATE $? "setting root passwd"