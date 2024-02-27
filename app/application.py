"""
Aplicación para página web conectada a una base de datos dynamoDB,
un bucket S3, una lambda que actualiza la base de datos con
los json subidos al bucket, y una instancia de EC2 para desplegar
la web.
La página web tendrá dos endpoints. La página de inicio, que
contiene el formulario para agregar información a la base de datos,
y la página de data, que contiene la tabla de usuarios de la base
de datos.
"""

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
    Definición: Endpoint para la página de inicio de la web. Contiene un formulario.

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
    Definición: Endpoint para la página de la tabla de usuarios.

    Items - diccionario de datos extraídos de la base de datos

    return: data.html
    """

    # Configurar conexión con dynamoDB
    dynamodb = boto3.resource('dynamodb', region_name="eu-west-3")
    tabla_usuarios = dynamodb.Table('database-antonio-juan')

    # Obtener los elementos de la tabla
    response = tabla_usuarios.scan()
    items = response['Items']
    return render_template("data.html", items=items)


if __name__ == '__main__':
    # Ejecuta la aplicación
    app.run(host="0.0.0.0", port=8080, debug=True)
