# PROYECTO EN AWS. THE BRIDGE. BOOTCAMP CLOUD & DEVOPS

![Alt text](img/aws.jpeg)

## Descripción
Este proyecto tiene como objetivo la realización de una serie de ejercicios prácticos en AWS como parte del Bootcamp Cloud & DevOps impartido por The Bridge. A lo largo de este README, encontrarás instrucciones detalladas, ejemplos de código y capturas de pantalla que te guiarán en la implementación de las tareas asignadas. El proyecto aborda diversos aspectos de AWS, incluyendo el despliegue de servicios en la nube, la automatización de tareas y la gestión de recursos.

## Ejercicios

### Ejercicio 1
El primer objetivo de este proyecto es establecer la capacidad de recibir ficheros JSON en un bucket de almacenamiento de S3 y automatizar la tarea de guardar su contenido en una base de datos DynamoDB. La estructura del JSON que se recibe es la siguiente:

```json
{
    "ID": 123456,
    "Nombre": "Juan Pérez",
    "Correo electrónico": "juan.perez@example.com",
    "Fecha de registro": "2022-01-01T10:00:00Z"
}
```

La primera etapa del proyecto incluye:

1. Crear una base de datos en DynamoDB y un bucket en S3.
2. Implementar una función Lambda que pueda recibir manualmente un JSON y guardarlo en la base de datos.
3. Configurar la función Lambda para que lea automáticamente JSONs desde el bucket del almacenamiento S3, en orden de llegada, y los vaya almacenando en nuestra base de datos DynamoDB.

### Ejercicio 2
El siguiente objetivo de este proyecto es establecer la capacidad de mostrar la base de datos de usuarios almacenada en DynamoDB a través de una página web. Como primer paso, se considerará ejecutar la web en un entorno local. Si esta solución se demuestra viable, se planteará su ejecución en un servidor EC2. Dado que la empresa no posee un amplio conocimiento en programación web, se ha decidido utilizar ChatGPT para abordar esta tarea.

### Ejercicio 3 (Avanzado)
Una vez completados los ejercicios anteriores, se contempla la creación de un formulario web para evitar la necesidad de rellenar manualmente los JSON de usuarios y almacenarlos en S3. Con este fin, se considera desarrollar una aplicación web en el lenguaje que el proveedor decida que genere un formulario. Cuando se guarden los datos en el formulario, se generará un archivo JSON en S3. La creación de este archivo en S3 activará automáticamente la función que cumple con el primer requerimiento y, al mismo tiempo, actualizará la aplicación de seguimiento de usuarios.


## Pasos a seguir

### Ejercicio 1

### Paso 1: Creación de la Base de Datos DynamoDB

En este primer paso, procedimos a la creación de la base de datos DynamoDB que servirá como repositorio de usuarios. La base de datos se configuró con los siguientes campos: 'ID', 'Nombre', 'Correo electrónico' y 'Fecha de registro'. La tabla principal de la Base de Datos se nombró como 'Usuarios'.

### Paso 2: Creación de un Rol para la Función Lambda

En este segundo paso, procedimos a crear un rol que será asignado a la función Lambda. Este rol debe otorgar los permisos necesarios para interactuar tanto con la base de datos DynamoDB como con el bucket que se creará posteriormente en S3.

A continuación, se muestra un resumen de los pasos necesarios para crear el rol:

1. Acceder al servicio IAM (Identity and Access Management) en la consola de AWS.

2. Seleccionar "Roles" en el panel de navegación y hacer clic en "Crear rol".

3. Elegir "Lambda" como tipo de entidad que confiará en este rol y hacer clic en "Siguiente: Permisos".

4. En la página "Permisos", buscar y seleccionar las políticas necesarias que permitan el acceso a DynamoDB y S3. Estos serán, "AmazonDynamoDBFullAccess" y "AmazonS3ReadOnlyAccess".

5. Continuar con los pasos de configuración y revisar los detalles antes de crear el rol.

6. Asignar este rol a la función Lambda que se creará para procesar los JSONs desde S3 y guardarlos en DynamoDB.

Este rol asegurará que la función Lambda tenga los permisos adecuados para conectarse a ambas fuentes de datos.

A continuación, continuaremos con los pasos adicionales para completar el ejercicio 1.


### Paso 3: Creación de un Bucket en Amazon S3

En el tercer paso, procedimos a crear un bucket en Amazon S3 que servirá como almacenamiento de los JSONs. Estos JSONs serán procesados y transferidos a la base de datos DynamoDB a través de la función Lambda que configuraremos más adelante.

El bucket se creó con el nombre 'bucket-juan-antonio'.

A continuación, se muestra un resumen de los pasos para crear el bucket:

1. Acceder al servicio Amazon S3 en la consola de AWS.

2. Hacer clic en "Create bucket" y proporcionar el nombre del cubo, en este caso, 'bucket-juan-antonio'.

3. Configurar las opciones adicionales del cubo según sea necesario y revisar los detalles antes de la creación.

El bucket 'bucket-juan-antonio' estará listo para almacenar los JSONs que se procesarán a través de la función Lambda.

En los siguientes pasos, detallaremos cómo configurar la función Lambda y conectarla con DynamoDB y este bucket.


### Paso 4: Creación de una Función Lambda

En este cuarto paso, procedimos a crear una función Lambda con el objetivo de recoger los JSONs del bucket, procesarlos y enviarlos para su almacenamiento en las tablas de la base de datos DynamoDB. En la sección "Trigger" de la configuración, agregamos el bucket de S3 para que la función Lambda se active automáticamente cuando reciba nuevos datos JSON.

Además, al crear la Lambda, asignamos el rol previamente creado que contiene los permisos necesarios para interactuar con S3 y DynamoDB.

A continuación, detallamos los pasos para configurar la función Lambda:

1. Acceder al servicio AWS Lambda en la consola de AWS.

2. Hacer clic en "Create function" y seleccionar "Author from scratch".

3. Proporcionar un nombre para la función, 'Lambda_funcion_Dynamo_s3'.

4. En la sección "Runtime", seleccionar el entorno de ejecución de Python.

5. En la sección "Role", seleccionar "Choose an existing role" y asignar el rol previamente creado con permisos para S3 y DynamoDB.

6. En la sección "Trigger", agregar el bucket de S3 que contendrá los JSONs.

Con esta configuración, la función Lambda estará lista para procesar y almacenar los JSONs en DynamoDB.

A continuación, proporcionaremos el código de la función Lambda que llevará a cabo esta tarea.

### Código

```python
# Librerías necesarias
import json
import boto3
import urllib.parse

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Usuarios')
bucket_name = 'bucket-juan-antonio'

def lambda_handler(event, _):
    # Comprueba si el evento proviene de S3
    if 'Records' in event and 's3' in event['Records'][0]:
        # El evento es un archivo nuevo en S3
        file_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])
        response = s3.get_object(Bucket=bucket_name, Key=file_key)
        content = response['Body'].read().decode('utf-8')
        data = json.loads(content)

        # Inserta los datos en la tabla DynamoDB
        response = table.put_item(Item=data)

        return {
            'statusCode': 200,
            'body': json.dumps('Datos insertados en DynamoDB')
        }
    else:
        return {
            'statusCode': 400,
            'body': json.dumps('Evento no válido')
        }
```

Con este código, la función Lambda recopila los JSONs del bucket de S3, los procesa y los almacena en la tabla DynamoDB. La configuración del disparador de S3 garantiza que la función se ejecute automáticamente cuando se agregan nuevos archivos al bucket.

![Alt text](img/AWS_SERVICES.jpeg)


### Ejercicio 2

#### Paso 1: Creación de un Rol con Permisos para S3 y DynamoDB

Para avanzar en el desarrollo del Ejercicio 2, en este primer paso procederemos a crear un rol en AWS con permisos de "full access" (acceso completo) para Amazon S3 y DynamoDB. Este rol se utilizará posteriormente al crear una instancia EC2 para alojar la página web que mostrará la base de datos de usuarios.

A continuación, se detallan los pasos para crear este rol:

1. Acceder al servicio IAM (Identity and Access Management) en la consola de AWS.

2. Seleccionar "Roles" en el panel de navegación y hacer clic en "Create role" (Crear rol).

3. Elegir el tipo de entidad que confiará en este rol (por ejemplo, EC2) y hacer clic en "Next: Permissions" (Siguiente: Permisos).

4. En la página "Permissions" (Permisos), buscar y seleccionar las políticas necesarias, como "AmazonS3FullAccess" y "AmazonDynamoDBFullAccess," que otorgan acceso completo a S3 y DynamoDB respectivamente.

5. Continuar con los pasos de configuración y revisar los detalles antes de crear el rol.

Una vez creado este rol, estará listo para ser asignado a la instancia EC2 que se utilizará para ejecutar la página web.

En los siguientes pasos, detallaremos la configuración de la instancia EC2.


#### Paso 2: Creación de una Instancia EC2

En este segundo paso, procedemos a crear una instancia EC2 con las siguientes especificaciones:

- Nombre de la instancia: 'servidor-juan-antonio'.
- AMI: Ubuntu con arquitectura de 64 bits (x86).
- Tipo de instancia: t2.micro.
- Nombre del par de claves (Key pair name): Seleccionamos una clave previamente creada para otras instancias.
- Grupos de seguridad (Firewall): Elegiremos un grupo de seguridad previamente creado que incluye las siguientes reglas de entrada:
    - Permite el tráfico SSH desde cualquier dirección IP ('0.0.0.0/0').
    - Permite el tráfico HTTPS desde Internet.
    - Permite el tráfico HTTP desde Internet.
    - Permite el tráfico a través del puerto 8080, con un "custom TCP"
- Configuración de almacenamiento: Por defecto.

A continuación, los pasos para crear y configurar esta instancia:

1. Acceder al servicio Amazon EC2 en la consola de AWS.

2. Hacer clic en "Instances" (Instancias) en el panel de navegación y luego en "Launch Instance" (Iniciar instancia).

3. Seleccionar la AMI de Ubuntu con arquitectura de 64 bits (x86).

4. En la sección "Instance Type" (Tipo de instancia), seleccionar 't2.micro'.

5. En "Key pair name" (Nombre del par de claves), seleccionar una clave existente previamente creada.

6. En "Security Groups" (Grupos de seguridad), seleccionar el grupo que contiene las reglas especificadas.

7. Continuar con la configuración y revisar los detalles antes de lanzar la instancia.

Una vez que la instancia esté creada y en funcionamiento, procederemos a asignar el rol creado en el paso anterior. Para hacerlo, iremos al apartado "Actions" (Acciones), luego a "Security details" (Detalles de seguridad) y finalmente a "Modify IAM Role" (Modificar Rol IAM).

Con esta instancia EC2 configurada y el rol asignado, estará lista para alojar la página web que mostrará la base de datos de usuarios.

En los siguientes pasos, detallaremos la configuración y despliegue de la página web en esta instancia EC2.


#### Paso 3: Transferencia de Archivos a la Instancia EC2

En este tercer paso, procederemos a transferir los archivos necesarios para levantar la aplicación web en la instancia EC2 creada en AWS, lo haremos desde la terminal de nuestro equipo a la instancia EC2 creada en AWS. Los archivos que debemos copiar son los siguientes:

- `app.py`: Código de la aplicación web que se utilizará para visualizar la base de datos de usuarios.
- `app_save_formulario.py`: Código de la aplicación web que se utilizará en el Ejercicio 3 para el formulario web que evita tener que rellenar a mano los JSON de usuarios y los guarda en S3.
- `requirements.txt`: Archivo que contiene las bibliotecas necesarias para instalar las dependencias requeridas por los códigos de los archivos `.py`.

Utilizaremos el comando `scp -r` para copiar el directorio completo que contiene estos archivos a la instancia EC2.

Una vez completada la transferencia, los archivos necesarios estarán disponibles en la instancia EC2 y listos para ser utilizados en la configuración y ejecución de las aplicaciones web.

En los siguientes pasos, detallaremos la configuración y ejecución de las aplicaciones en la instancia EC2.


#### Paso 4: Instalación y actualización de librerías en la Instancia EC2 y Modificación de `app.py`

En este cuarto paso, procederemos a realizar la configuración de la instancia EC2 que hemos preparado para el proyecto.

1. Acceder a la consola de la instancia EC2.

2. Actualizar los paquetes del sistema utilizando el comando `apt update`.

3. Instalar Python y pip si no están ya instalados en la instancia.

4. Instalar las bibliotecas y dependencias requeridas para el proyecto utilizando el archivo `requirements.txt`.

5. Utilizar el editor de texto `nano` para abrir el archivo `app.py`. Este archivo es la aplicación web que visualizará la base de datos de usuarios. Realizaremos modificaciones en este archivo para adaptarlo a nuestras configuraciones y nombres específicos, como la base de datos, el bucket de S3, etc.

A continuación, mostraremos cómo es el archivo `app.py` original y luego proporcionaremos la versión modificada con las explicaciones de las modificaciones realizadas.

**Archivo 'app.py' original:**

```python
import boto3
import dash
from dash import html

# Configura la conexión a la tabla de DynamoDB
dynamodb = boto3.resource('dynamodb')
tabla_usuarios = dynamodb.Table('tablon_usuarios')

# Obtener los elementos de la tabla
response = tabla_usuarios.scan()
items = response['Items']

# Crea una aplicación de Dash
app = dash.Dash(__name__)

# Crea el diseño de la aplicación
app.layout = html.Div(children=[
    html.H1(children='Usuarios'),

    # Crea la tabla utilizando Dash y la biblioteca PrettyTable
    dash.dash_table.DataTable(items)
])

if __name__ == '__main__':
    # Ejecuta la aplicación
    app.run_server(debug=True)
```

**Archivo 'app.py' modificado:**

```python
import boto3
import dash
from dash import html

# Configura la conexión a la tabla de DynamoDB
dynamodb = boto3.resource('dynamodb', region_name="eu-west-3")
tabla_usuarios = dynamodb.Table('Usuarios')

# Obtener los elementos de la tabla
response = tabla_usuarios.scan()
items = response['Items']

# Crea una aplicación de Dash
app = dash.Dash(__name__)

# Crea el diseño de la aplicación
app.layout = html.Div(children=[
    html.H1(children='Usuarios'),

    # Crea la tabla utilizando Dash y la biblioteca PrettyTable
    dash.dash_table.DataTable(items)
])

if __name__ == '__main__':
    # Ejecuta la aplicación
    app.run(host="0.0.0.0", port=8080, debug=True)
```

### Explicaciones de los Cambios en 'app.py'

1. **Parámetro `region_name="eu-west-3"`**:
   - Se agregó el parámetro `region_name="eu-west-3"` en la configuración de la conexión a DynamoDB para especificar la región de AWS en la que se encuentra la tabla. Esto asegura que la aplicación se conecte a la región correcta.

2. **Cambio nombre de la tabla de DynamoDB**:
   - Se cambió el nombre de la tabla de DynamoDB de `'tablon_usuarios'` a `'Usuarios'` para reflejar el nombre de la tabla real que tiene en el proyecto.

3. **Se agregaron parámetros `host="0.0.0.0"` y `port=8080` en el comando app-run**:
   - Se agregaron parámetros `host="0.0.0.0"` y `port=8080` en la configuración para que la aplicación se ejecute en cualquier host accesible desde fuera de la instancia EC2 a través del puerto 8080.

Estos cambios permiten que la aplicación se conecte a DynamoDB en la región correcta y utilice la tabla de usuarios adecuada. Además, la aplicación se podrá ejecutar desde cualquier host, y en el puerto específico '8080' para la instancia EC2.


## Paso 5: Levantar la Aplicación Web en la Instancia EC2

Una vez realizados los cambios pertinentes en el archivo 'app.py', procederemos a levantar la aplicación web en la instancia creada en EC2 'servidor-juan-antonio'. Para hacerlo, seguimos estos pasos:

1. En la consola de la instancia dentro de AWS, ejecutaremos el archivo 'app.py' modificado utilizando el siguiente comando:

```shell
python3 app.py
```

La aplicación se ejecutará y te indicará que todo está en orden.

Para acceder a la aplicación web, seguimos estos pasos:

1. En la página de la instancia en AWS, copiamos la ip pública 'Public IPv4'.

2. En el navegador, iremos a la dirección `http://nuestraipv4:8080`, donde `nuestraipv4`es la ip copiada.

3. Al acceder a esta URL, se nos mostrará la aplicación web con la tabla de nuestra base de datos en DynamoDB.

Este paso nos permitirá visualizar la aplicación web en nuestra instancia EC2 y acceder a la tabla de la base de datos en DynamoDB.



## Ejercicio 3 (Avanzado)

El Ejercicio 3 se centra en la creación de una aplicación web que incluye un formulario para evitar la entrada manual de datos JSON de los usuarios. El objetivo es que, al guardar el formulario, se genere un archivo JSON que se almacene en un bucket de S3. Cuando se crea este archivo en S3, se activará automáticamente la función Lambda que procesa los nuevos datos que entran al bucket y los almacena en la base de datos DynamoDB.

#### Paso 1: Modificar el Archivo 'app_save_formulario.py'

**Modificar el Archivo 'app_save_formulario.py'**

Para lograr esto, siguimos estos pasos:

1. Abrimos con el editor de texto `nano` el archivo `app_save_formulario.py` que ya tenemos guardado en la instancia de EC2. Este archivo es parte de la aplicación web que se encargará del formulario.

2. Realizamos las modificaciones necesarias en el archivo `app_save_formulario.py` para que se ajuste a nuestras configuraciones y necesidades específicas.

Con estas modificaciones en `app_save_formulario.py`, la aplicación web será capaz de generar y almacenar archivos JSON en el bucket de S3, lo que desencadenará la función Lambda para procesar los nuevos datos y almacenarlos en la base de datos DynamoDB.

A continuación, mostraremos cómo es el archivo `app_save_formulario.py` original y luego proporcionaremos la versión modificada con las explicaciones de las modificaciones realizadas.

**app_save_formulario.py (Original):**

```python
import json
import boto3
import dash
from dash import dcc
from dash import html
import random
import datetime

# Crear una aplicación Flask
app = dash.Dash(__name__)

# Crear una aplicación Dash
app.layout = html.Div([
    html.H1('Formulario de Usuarios'),
    dcc.Input(id='nombre', type='text', placeholder='Nombre', value=''),
    dcc.Input(id='email', type='email', placeholder='Email', value=''),
    html.Button('Enviar', id='submit-button', n_clicks=0),
    html.Div(id='output-container-button', children='Hit the button to update.')
])

# Crear un cliente de boto3 para acceder a S3
s3 = boto3.client('s3')

today = datetime.date.today().strftime('%Y-%m-%d')

# Ruta para manejar la subida de datos del formulario
@app.callback(
    dash.dependencies.Output('output-container-button', 'children'),
    [dash.Input('submit-button', 'n_clicks'),
     dash.Input('nombre', 'value'),
     dash.Input('email', 'value')]
)
def submit_form(n_clicks, nombre, email):
    # Obtener los datos del formulario

    # Crear un diccionario con los datos del usuario
    usuario = {
        'ID': random.randint(100000, 999999),
        'Nombre': nombre,
        'Correo electrónico': email,
        'Fecha de registro': today
    }

    # Guardar los datos del usuario en un archivo JSON en S3
    s3.put_object(Bucket='formularios-json', Key=f'usuarios{today}.json', Body=json.dumps(usuario))

if __name__ == '__main__':
    app.run_server(port=8080, debug=True)
```

**app_save_formulario.py (Modificado):**

```python
import json
import boto3
import dash
from dash import dcc
from dash import html
import random
import datetime

# Crear una aplicación Flask
app = dash.Dash(__name__)

# Crear una aplicación Dash
app.layout = html.Div([
    html.H1('Formulario de Usuarios'),
    dcc.Input(id='nombre', type='text', placeholder='Nombre', value=''),
    dcc.Input(id='email', type='email', placeholder='Email', value=''),
    html.Button('Enviar', id='submit-button', n_clicks=0),
    html.Div(id='output-container-button', children='Hit the button to update.')
])

# Crear un cliente de boto3 para acceder a S3
s3 = boto3.client('s3', region_name='eu-west-3')

today = datetime.date.today().strftime('%Y-%m-%d')

# Ruta para manejar la subida de datos del formulario
@app.callback(
    dash.dependencies.Output('output-container-button', 'children'),
    [dash.Input('submit-button', 'n_clicks'),
     dash.State('nombre', 'value'),
     dash.State('email', 'value')]
)
def submit_form(n_clicks, nombre, email):
    # Obtener los datos del formulario

    # Crear un diccionario con los datos del usuario
    usuario = {
        'ID': random.randint(100000, 999999),
        'Nombre': nombre,
        'Correo electrónico': email,
        'Fecha de registro': today
    }

    # Guardar los datos del usuario en un archivo JSON en S3
    s3.put_object(Bucket='bucket-juan-antonio', Key=f'usuarios{today}.json', Body=json.dumps(usuario))

if __name__ == '__main__':
    app.run_server(host='0.0.0.0', port=8080, debug=True)
```

**Diferencias y Cambios:**
- Se agregó la región `eu-west-3` al configurar el cliente de boto3 para acceder a S3.
- Se modificó el nombre del bucket S3 de `formularios-json` a `bucket-juan-antonio` en la función `s3.put_object`.
- Se agregaron parámetros en `app.run_server`: `host="0.0.0.0"` y `port=8080` para que la aplicación se ejecute en cualquier host accesible desde fuera de la instancia EC2 y en el puerto 8080.
- Se cambiaron en `@app.callback` la parte referida al campo rellenable del nombre y del email, de cómo recibe los valores. Estaban así: `dash.Input`, y al visualizar el formulario en la web y meter los parámetros, daba un error. Este error causaba, que por cada tecla pulsada en el teclado para ingresar texto en las ventanas tanto de nombre como de email, se mandara información al bucket de S3, y este iba guardando en la base de datos cada caracter que ingresamos, sumandose una cantidad ingente de registros sin valor ninguno, ya que estaban incompletos y no tenían sentido. La solución para este problema la encontramos cambiando la parte antes mencionada de `dash.Input` por `dash.State`, tanto para el nombre como para el email.

Estos cambios aseguran que la aplicación web funcione correctamente con la región de S3 pertinente, y guarde los datos en el bucket de forma adecuada, registro por registro, conforme se vaya rellenando formulario, y este se envíe.

## Paso 2: Fusionar las Aplicaciones Web

El objetivo de este paso es fusionar la aplicación web 'app.py' modificada (que muestra la tabla de usuarios) con la aplicación 'app_save_formulario.py' modificada (que permite agregar datos a la base de datos a través de un formulario) en un único script de Python. Esto creará una única página web que tendrá dos endpoints: la página de inicio para agregar información a la base de datos y la página de datos para mostrar la tabla de usuarios.

Para lograr esto, hemos combinado ambos códigos en un solo script. Asegurándonos de mantener la funcionalidad de ambas partes, y de que no haya conflictos entre las rutas y funciones definidas en cada uno de los scripts.

Una vez que hayamos fusionado con éxito ambos scripts, ejecutaremos el código resultante. Esto nos permitirá que la página web esté disponible con ambas funcionalidades en tu instancia de EC2.

A continuación, mostraremos el código resultante de la fusión de ambos scripts. Este creará la aplicación web en Flask sustituyendo cómo se hacía en los otros dos scripts por separado con Dash.

## Descripción

Esta es una aplicación para una página web que se conecta a una base de datos DynamoDB, utiliza un bucket S3 y una función Lambda para actualizar la base de datos con los JSON subidos al bucket. También se despliega en una instancia de EC2. La página web tiene dos endpoints: la página de inicio, que contiene un formulario para agregar información a la base de datos, y la página de datos, que muestra la tabla de usuarios de la base de datos.

Para lograr una navegación entre endpoints, hemos separado el html en tres ficheros distintos: El primero `layout.html` para unificar la web entera bajo un mismo formato y una misma barra de menú, el segundo `index.html` que contiene el html del formulario, y finalmente `data.html`que contiene el hbtml de la tabla

## Script Fusionado

`application.py` contiene el código flask para realizar las funciones backend de la web:

```python
from flask import Flask, render_template, request, redirect
import boto3
import json
import random
import datetime
import time

# Creamos un cliente de boto3 para acceder a S3
s3 = boto3.client('s3', region_name="eu-west-3")
today = datetime.date.today().strftime('%Y-%m-%d')

# Crea una aplicación de Flask
app = Flask(__name__)

@app.route("/", methods=["GET", "POST"])
def index():
    """
    Endpoint para la página de inicio de la web. Contiene un formulario.

    Form: Nombre - Nombre insertado por el usuario.
    Form: Correo electrónico - email insertado por el usuario.

    Return: index.html
    """
    if request.method == "POST":
        # Creamos un diccionario con los datos del usuario
        usuario = {
            'ID': random.randint(100000, 999999),
            'Nombre': request.form.get("nombre"),               # Dato procedente de la web
            'Correo electrónico': request.form.get("email"),    # Dato procedente de la web
            'Fecha de registro': today                          # Dato procedente de la variable creada arriba
        }

        # Guardamos los datos del usuario en un archivo JSON en S3
        s3.put_object(Bucket='bucket-antonio-juan', Key=f'usuarios{today}.json', Body=json.dumps(usuario))
        time.sleep(5)
        return redirect("/data")
    else:
        return render_template("index.html")

@app.route("/data")
def data():
    """
    Endpoint para la página de la tabla de usuarios.

    Items - diccionario de datos extraídos de la base de datos

    Return: data.html
    """

    # Configurar conexión con DynamoDB
    dynamodb = boto3.resource('dynamodb', region_name="eu-west-3")
    tabla_usuarios = dynamodb.Table('database-antonio-juan')

    # Obtener los elementos de la tabla
    response = tabla_usuarios.scan()
    items = response['Items']
    return render_template("data.html", items=items)

if __name__ == '__main__':
    # Ejecuta la aplicación
    app.run(host="0.0.0.0", port=8080, debug=True)
```

`layout.html` contiene el html principal de la web. Está diseñada para ser una plantilla que se importará a los otros dos htm, manteniendo así una estructura única a través de toda la web.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <!-- http://getbootstrap.com/docs/5.1/ -->
    <link crossorigin="anonymous" href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" rel="stylesheet">
    <script crossorigin="anonymous" src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p"></script>
    <title>{% block title %}{% endblock %}</title>
</head>

<body>

    <nav class="bg-dark border-bottom navbar navbar-expand-md navbar-dark" style="position: fixed; top: 0; width: 100%; z-index: 0;">
        <div class="container-fluid">
            <a class="navbar-brand"><span class="red">Cloud - The Bridge</span></a>
            <button aria-controls="navbar" aria-expanded="false" aria-label="Toggle navigation" class="navbar-toggler" data-bs-target="#navbar" data-bs-toggle="collapse" type="button">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbar">
                <ul class="navbar-nav me-auto mt-2">
                    <li class="nav-item"><a class="nav-link" href="/">Formulário</a></li>
                    <li class="nav-item"><a class="nav-link" href="/data">Tabla de usuarios</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <main class="container-fluid py-5 text-center">
        <br>
        {% block main %}{% endblock %}
    </main>

    {% for message in get_flashed_messages() %}
    <div class="alert alert-primary">
        {{ message }}
    </div>
    {% endfor %}

</body>
</html>
```

`index.html` contiene el html de la página de inicio de nuestra web, el formulario. Este fichero importa `layout.html` como plantilla.

```html
{% extends "layout.html" %}

{% block main %}
<br>
    <form action="/" method="post">
        <div class="mb-3">
            <input autocomplete="off" autofocus class="form-control mx-auto w-25" id="nombre" name="nombre" placeholder="Nombre" type="text">
        </div>
        <div class="mb-3">
            <input autocomplete="off" class="form-control mx-auto w-25" id="email" name="email" placeholder="Correo Electrónico" type="email">
        </div>
        <button class="btn btn-primary" type="submit">Enviar</button>
    </form>

{% endblock %}
```
**El resultado:**

![INDEX](https://images2.imgbox.com/30/29/02aRrFN1_o.png)

`data.html` contiene el html de la tábla de datos extraídos de nuestra base de datos. También importa `layout.html` como plantilla.

```html
{% extends "layout.html" %}

{% block title %}
    Tabla de usuarios
{% endblock %}

{% block main %}

    <h3>Tabla de usuarios</h3>
    <table class="table mx-auto w-50">
        <thead>
            <tr>
                <th scope="col">ID</th>
                <th scope="col">Nombre</th>
                <th scope="col">Correo eletrónico</th>
                <th scope="col">Fecha de registro</th>
            </tr>
        </thead>
        <tbody>
        {% for item in items %}
            <tr>
                <td class="center-align">{{ item["ID"] }}</td>
                <td class="center-align">{{ item["Nombre"] }}</td>
                <td class="center-align">{{ item["Correo electrónico"] }}</td>
                <td class="center-align">{{ item["Fecha de registro"] }}</td>
            </tr>
        {% endfor %}
        </tbody>
    </table>

{% endblock %}
```

**El resultado:**

![DATA](https://images2.imgbox.com/b4/25/KSpcJsa8_o.png)

Finalmente, la estética y el CSS de esta web se gestiona íntegramente por la libreria `Bootstrap`, que es gratuíta y se encuentra en la web `https://getbootstrap.com/`


# Ejercicio AWS CLI

![Alt text](img/aws_CLI_2.png)

En este ejercicio intentarémos lanzar todas los servicios de AWS, que hemos creado manualmente a través de la interfaz web, utilizando un script de bash que contendrá todos los comandos de la AWS Command Line Interface (AWS CLI) necesarios. Esto nos permitirá lograr exactamente lo mismo que hicimos interactuando con AWS a través de la página web, pero de una manera automatizada y mediante la línea de comandos.

Crearemos recursos en AWS utilizando la AWS CLI, como la creación de un bucket S3, una base de datos DynamoDB, una instancia EC2 y la configuración de roles y permisos necesarios. Además, nos aseguraremos de que estos recursos se utilicen en conjunto para mantener la funcionalidad del proyecto. El script de bash contendrá todos los comandos de AWS CLI necesarios para configurar todos los componentes de nuestro proyecto, incluyendo la configuración de roles, permisos y la interacción entre los servicios.

El script de bash resultante servirá como una representación de la infraestructura como código, lo que facilita la reproducción y la automatización de la creación de recursos en el futuro mediante AWS CLI.


## SCRIPT:

### Ejercicio AWS CLI - Creación de Recursos

A continuación, se muestra el script de bash que utiliza la AWS Command Line Interface (AWS CLI) para crear varios recursos en AWS, incluyendo un bucket S3, una tabla de DynamoDB, roles de ejecución, una función Lambda y una instancia EC2. 

**Por desgracia, para esta presentación, este ejercicio ha quedado incompleto. Vamos a verlo:**
```bash
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

# Agregar trigger a la lambda    NO FUNCIONA!!!
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
```
