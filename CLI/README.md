# Ejercicio AWS CLI

![Alt text](img/aws_CLI_2.png)

En este ejercicio intentarémos lanzar todas los servicios de AWS, que hemos creado manualmente a través de la interfaz web, utilizando un script de bash que contendrá todos los comandos de la AWS Command Line Interface (AWS CLI) necesarios. Esto nos permitirá lograr exactamente lo mismo que hicimos interactuando con AWS a través de la página web, pero de una manera automatizada y mediante la línea de comandos.

Crearemos recursos en AWS utilizando la AWS CLI, como la creación de un bucket S3, una base de datos DynamoDB, una instancia EC2 y la configuración de roles y permisos necesarios. Además, nos aseguraremos de que estos recursos se utilicen en conjunto para mantener la funcionalidad del proyecto. El script de bash contendrá todos los comandos de AWS CLI necesarios para configurar todos los componentes de nuestro proyecto, incluyendo la configuración de roles, permisos y la interacción entre los servicios.

El script de bash resultante servirá como una representación de la infraestructura como código, lo que facilita la reproducción y la automatización de la creación de recursos en el futuro mediante AWS CLI.


# Ejercicio AWS CLI - Creación de Recursos

A continuación, se muestra el script de bash que utiliza la AWS Command Line Interface (AWS CLI) para crear varios recursos en AWS, incluyendo un bucket S3, una tabla de DynamoDB, roles de ejecución, una función Lambda y una instancia EC2. 

## Resumen:

### Configurar AWS en la máquina

```bash
aws configure
```
Esto te pedirá que ingreses la información de tus credenciales de AWS:

- AWS Access Key ID: Tu clave de acceso de AWS.
- AWS Secret Access Key: Tu clave secreta de acceso de AWS.
- Default region name: La región de AWS que deseas utilizar (por ejemplo, us-east-1).

## Creación EC2

```bash
aws ec2 run-instances \
    --image-id AMI_ID \
    --instance-type INSTANCE_TYPE \
    --key-name KEY_PAIR_NAME \
    --subnet-id SUBNET_ID \
    --security-group-ids SECURITY_GROUP_ID \
    --region YOUR_REGION
```
## Creación S3

```bash
aws s3 api create-bucket --bucket NOMBRE_DEL_CUBO --region REGION
```

Podrías tener problemas con tu región, por lo cual es recomendable usar una variable de entorno:

```bash
export NOMBRE_DE_VARIABLE=valor
```

Para establecerla de manera permanente, generalmente se agrega esa línea al archivo de perfil del usuario, como ~/.bashrc o ~/.bash_profile. Puedes editar estos archivos con un editor de texto como nano o vim.

```bash
echo 'export NOMBRE_DE_VARIABLE=valor' >> ~/.bashrc
source ~/.bashrc
```
## Creamos una base de datos en DynamoDB y una función Lambda

### Paso 1: Crear una tabla en DynamoDB

```bash
aws dynamodb create-table \
    --table-name Usuarios \
    --attribute-definitions \
        AttributeName=ID,AttributeType=N \
    --key-schema AttributeName=ID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region tu-region
```
### Subir el código a un Bucket de S3

Antes de ejecutar el comando para crear la función Lambda, necesitaremos tener el código de la función en un archivo ZIP y almacenarlo en un bucket de S3.

```bash
aws s3 cp tu-archivo-.zip s3://tu-cubo/
```

### Paso 2: Crear una función Lambda

```bash
aws lambda create-function \
    --function-name GuardarUsuarioEnDynamoDB \
    --runtime python3.8 \
    --role arn:aws:iam::tu-id-de-cuenta:role/el-rol \
    --handler guardar_usuario.handler \
    --code S3Bucket=tu-bucket-con-el-codigo,Key=tu-archivo-zip-con-el-codigo.zip \
    --environment Variables={DYNAMODB_TABLE=Usuarios} \
    --region tu-region
```

### Paso 3: Crear una función Lambda que se active al crear un objeto en S3

```bash
aws lambda create-function \
    --function-name TriggerLambda \
    --runtime python3.8 \
    --role arn:aws:iam::tu-id-de-cuenta:role/tu-rol \
    --handler trigger_lambda.handler \
    --code S3Bucket=tu-bucket-con-el-codigo,Key=tu-archivo-zip-con-el-codigo.zip \
    --environment Variables={TARGET_LAMBDA_NAME=GuardarUsuarioEnDynamoDB} \
    --region tu-region
```
### Paso 4: Configurar el trigger de S3 para activar la función Lambda

```bash
aws s3api put-bucket-notification-configuration \
    --bucket tu-bucket-s3 \
    --notification-configuration '{"LambdaFunctionConfigurations":[{"LambdaFunctionArn":"arn:aws:lambda:tu-region:tu-id-de-cuenta:function:TriggerLambda","Events":["s3:ObjectCreated:*"]}]}'
```

## Roles y políticas

### Crear rol de ejecución dynamoDBallowall y S3readonly
```bash
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
```


### Agregar políticas de permisos al rol creado
```bash
aws iam attach-role-policy \
    --role-name forlambda-dynamodballowall-s3readonly \
    --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
```

```bash
aws iam attach-role-policy \
    --role-name forlambda-dynamodballowall-s3readonly \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

### Crear rol de ejecución dynamoDBreadonly y S3fullaccess

```bash
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
```


```bash
arn_rol_ec2=$(aws iam get-role --role-name forlambda-dynamodballowall-s3readonly --query 'Role.Arn' --output text)
```

### Agregar políticas de permisos al rol creado
```bash
aws iam attach-role-policy \
    --role-name EC2-readdynamoDB-fullaccessS3 \
    --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

```bash
aws iam attach-role-policy \
    --role-name EC2-readdynamoDB-fullaccessS3 \
    --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess
```