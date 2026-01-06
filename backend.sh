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

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "disbling  existing default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling nodejs 20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing nodejs"

id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>>$LOG_FILE_NAME
    VALIDATE $? "adding expense user"
else
    echo "already expense user exist ... $y skipping"
fi        

    mkdir -p /app &>>$LOG_FILE_NAME  # -p:if app dir already exist then it won't create again, if not will it create
    VALIDATE $? "creating app dir"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "downloding backend"

cd /app
VALIDATE $? "change dir to app"

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzip backend"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "install npm"

cp /home/ec2-user/expense-shell/backend.service  /etc/systemd/system/backend.service &>>$LOG_FILE_NAME
VALIDATE $? "created backend.service file"

#prepare mysql schema

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "insatll mysql client"

mysql -h 172.31.16.62 -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? " ssetting up transaction schema and tables"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? " deamon reloding"

systemctl start backend &>>$LOG_FILE_NAME
VALIDATE $? " starting backend"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "enabling backend"