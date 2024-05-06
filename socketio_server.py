import base64
import time
import eventlet
import socketio
# from zmq_subscriber import decode_data, DataPacket

import base64
import struct
import numpy as np
class DataPacket:
    def __init__(self, transform_matrix: np.ndarray, timestamp):
        self.transform_matrix = transform_matrix.copy()
        self.timestamp = timestamp

    def __str__(self):
        return f"Translation: {self.transform_matrix[:3, 3]}, Timestamp: {self.timestamp:.3f}"

def decode_data(encoded_str):
    # Decode the base64 string to bytes
    data_bytes = base64.b64decode(encoded_str)
    
    transform_matrix = np.zeros((4, 4))
    # Unpack transform matrix (16 floats)
    for i in range(4):
        for j in range(4):
            transform_matrix[i, j] = struct.unpack('f', data_bytes[4 * (4 * i + j):4 * (4 * i + j + 1)])[0]
    # The transform matrix is stored in column-major order in swift, so we need to transpose it in python
    transform_matrix = transform_matrix.T
    
    # Unpack timestamp (1 double)
    timestamp = struct.unpack('d', data_bytes[64:72])[0]
    
    return DataPacket(transform_matrix, timestamp)


# Create a Socket.IO server
sio = socketio.Server()

# Create a WSGI app
app = socketio.WSGIApp(sio)

# Event handler for new connections
@sio.event
def connect(sid, environ):
    print("Client connected", sid)

# Event handler for disconnections
@sio.event
def disconnect(sid):
    print("Client disconnected", sid)

prev_time = 0
package_cnt = 0
# Event handler for messages on 'update' channel
@sio.on('update')
def handle_message(sid, data):
    # Assuming data is base64-encoded from the client
    global prev_time, package_cnt
    structured_data = decode_data(data)
    print(f"{structured_data}, fps: {1/(structured_data.timestamp - prev_time):.2f}")
    prev_time = structured_data.timestamp
    package_cnt += 1
    # Process data here as needed

# Run the server
if __name__ == '__main__':
    np.set_printoptions(precision=4, suppress=True)
    eventlet.wsgi.server(eventlet.listen(('', 5555)), app)
