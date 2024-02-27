#! /bin/bash

# Crear Bucket de S3
aws s3 mb s3://antoniojuan-storage --region eu-west-3

# Crear tabloa de dynamoDB
aws dynamodb create-table \
    --table-name antoniojuan-database \
    --region eu-west-3 \
    --attribute-definitions AttributeName=ID,AttributeType=N \
    --key-schema AttributeName=ID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5


# Crear rol de ejecución dynamoDBallowall y S3readonly
aws iam create-role \
    --role-name forlambda-dynamodballowall-s3readonly \
    --region eu-west-3 \
    --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}'

# Agregar políticas de permisos al rol creado
aws iam attach-role-policy \
    --role-name forlambda-dynamodballowall-s3readonly \
    --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

aws iam attach-role-policy \
    --role-name forlambda-dynamodballowall-s3readonly \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Crear lambda
aws lambda create-function \
    --function-name antoniojuan-funcionS3aDB \
    --zip-file fileb://funcionS3aDB.zip \
    --handler index.handler \
    --runtime python3.11 \
    --role $(aws iam get-role --role-name forlambda-dynamodballowall-s3readonly --query 'Role.Arn' --output text)  > output.txt

# Agregar trigger a la lambda                   NO FUNCIONA!!!
aws lambda add-permission \
    --function-name antoniojuan-funcionS3aDB \
    --principal s3.amazonaws.com \
    --statement-id S3InvokePermission1 \
    --action lambda:InvokeFunction \
    --source-arn arn:aws:s3:::antoniojuan-storage \
    --source-account $(aws sts get-caller-identity --query Account --output text)


aws s3api put-bucket-notification-configuration \
    --region eu-west-3 \
    --bucket antoniojuan-database \
    --notification-configuration '{
    "LambdaFunctionConfigurations": [
        {
            "LambdaFunctionArn": $(aws lambda get-function --function-name antoniojuan-funcionS3aDB --query 'Configuration.FunctionArn' --output text),
            "Events": ["s3:ObjectCreated:*"],
            "Filter": {
                "Key": {
                    "FilterRules": [
                        {
                            "Name": "suffix",
                            "Value": ".json"
                        }
                    ]
                }
            }
        }
    ]
}'


# Crear rol de ejecución dynamoDBreadonly y S3fullaccess
aws iam create-role \
    --role-name EC2-readdynamoDB-fullaccessS3 \
    --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}'

arn_rol_ec2=$(aws iam get-role --role-name forlambda-dynamodballowall-s3readonly --query 'Role.Arn' --output text)

# Agregar políticas de permisos al rol creado
aws iam attach-role-policy \
    --role-name EC2-readdynamoDB-fullaccessS3 \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam attach-role-policy \
    --role-name EC2-readdynamoDB-fullaccessS3 \
    --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess

# Crear perfil de seguridad para HTTP, HTTPS, SSH y TCP personalizado a través del puerto 8080
# POR HACER!!!

# Crear instancia    INCOMPLETO!!!
aws ec2 run-instances \
    --image-id ami-00983e8a26e4c9bd9 \
    --count 1 \
    --instance-type t2.micro \
    --key-name ficheroclaves \
    --iam-instance-profile Name=EC2-read-dynamoDB-fullaccess-S3     # AQUI HAY TRAMPA!!!
