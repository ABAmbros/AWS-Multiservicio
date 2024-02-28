#! /bin/bash

```bash
aws configure
```

# Creación EC2
aws ec2 run-instances \
    --image-id AMI_ID \
    --instance-type INSTANCE_TYPE \
    --key-name KEY_PAIR_NAME \
    --subnet-id SUBNET_ID \
    --security-group-ids SECURITY_GROUP_ID \
    --region YOUR_REGION

# Creación S3
aws s3 api create-bucket --bucket NOMBRE_DEL_CUBO --region REGION

# Paso 1: Crear una tabla en DynamoDB
aws dynamodb create-table \
    --table-name Usuarios \
    --attribute-definitions \
        AttributeName=ID,AttributeType=N \
    --key-schema AttributeName=ID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region tu-region

# Subir el código a un Bucket de S3
aws s3 cp tu-archivo-.zip s3://tu-cubo/

# Paso 2: Crear una función Lambda
aws lambda create-function \
    --function-name GuardarUsuarioEnDynamoDB \
    --runtime python3.8 \
    --role arn:aws:iam::tu-id-de-cuenta:role/el-rol \
    --handler guardar_usuario.handler \
    --code S3Bucket=tu-bucket-con-el-codigo,Key=tu-archivo-zip-con-el-codigo.zip \
    --environment Variables={DYNAMODB_TABLE=Usuarios} \
    --region tu-region

# Paso 3: Crear una función Lambda que se active al crear un objeto en S3
aws lambda create-function \
    --function-name TriggerLambda \
    --runtime python3.8 \
    --role arn:aws:iam::tu-id-de-cuenta:role/tu-rol \
    --handler trigger_lambda.handler \
    --code S3Bucket=tu-bucket-con-el-codigo,Key=tu-archivo-zip-con-el-codigo.zip \
    --environment Variables={TARGET_LAMBDA_NAME=GuardarUsuarioEnDynamoDB} \
    --region tu-region

# Paso 4: Configurar el trigger de S3 para activar la función Lambda
aws s3api put-bucket-notification-configuration \
    --bucket tu-bucket-s3 \
    --notification-configuration '{"LambdaFunctionConfigurations":[{"LambdaFunctionArn":"arn:aws:lambda:tu-region:tu-id-de-cuenta:function:TriggerLambda","Events":["s3:ObjectCreated:*"]}]}'

# Roles y políticas

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