from flask import Flask,jsonify
import socket

app = Flask(__name__)

@app.route('/')
def server_inf0():
    try:
        data = {'host': socket.gethostname(), 'host_ip': socket.gethostbyname(socket.gethostname())}
        return jsonify(data)
    except:
        return jsonify({'result': 'error'})

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8080)