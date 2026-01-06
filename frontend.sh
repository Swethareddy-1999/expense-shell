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

dnf install nginx -y &>>$LOG_FILE_NAME
VALIDATE $? " installing nginx "

systemctl start nginx &>>$LOG_FILE_NAME
VALIDATE $? " starting nginx "

systemctl enable nginx &>>$LOG_FILE_NAME
VALIDATE $? " enabling nginx "

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE_NAME
VALIDATE $? " removing existing code in webserver "

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? " downloading frontend latest code "

cd /usr/share/nginx/html 
VALIDATE $? "changing to HTML directory"

unzip /tmp/frontend.zip &>>$LOG_FILE_NAME
VALIDATE $? " unziping the code "

cp -r /home/ec2-user/expense-shell /etc/nginx/default.d/expense.conf 
VALIDATE $? " copy the code"

systemctl restart nginx &>>$LOG_FILE_NAME
VALIDATE $? " restarting nginx "