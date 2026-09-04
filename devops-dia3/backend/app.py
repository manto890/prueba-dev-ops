from flask import Flask
import psycopg

app = Flask(__name__)


@app.route("/")
def home():
    return "Hola desde el Backend!"


@app.route("/health")
def health():
    return "OK"


@app.route("/users")
def users():
    conn = psycopg.connect(
        host="postgres",
        port=5432,
        dbname="devopsdb",
        user="devops",
        password="devops123"
    )

    cur = conn.cursor()
    cur.execute("SELECT id, nombre FROM usuarios")
    users = cur.fetchall()

    cur.close()
    conn.close()

    return str(users)


app.run(host="0.0.0.0", port=5000)
