# flask_web/app.py

from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hey, we have Flask in a Docker container!'

@app.route('/version')
def get_version():
    return 'API version: 1.0.1'

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
