import SocketIO
import simd

class DataPacket {
    var transformMatrix: simd_float4x4
    var timestamp: Double

    init(transformMatrix: simd_float4x4, timestamp: Double) {
        self.transformMatrix = transformMatrix
        self.timestamp = timestamp
    }
    func toBytes() -> Data {
        var data = Data()

        // Append pose data
        for i in 0..<4 {
            for j in 0..<4 {
                var val = transformMatrix[i][j]
                data.append(Data(bytes: &val, count: MemoryLayout<Float>.size))
            }
        }

        // Append timestamp
        var timestampVal = timestamp
        data.append(Data(bytes: &timestampVal, count: MemoryLayout<Int64>.size))

        return data
    }
}


class SocketClient{
    private var manager: SocketManager?
    private var socket: SocketIOClient?

    var ready: Bool = false
    var socketOpened: Bool
    var prevTimestamp: Double = 0
    init(){
        socketOpened = false
    }

    func connect(hostIP: String, hostPort: Int) {
        self.ready = false
        print("Connecting to \(hostIP):\(hostPort)")
        self.manager = SocketManager(socketURL: URL(string: "http://\(hostIP):\(hostPort)")!, config: [.log(true), .compress])
        usleep(100000)
        self.socket = self.manager?.defaultSocket
        self.socket?.connect()
        usleep(100000)
        self.ready = true
    }

    func sendData(_ data: DataPacket) {
        if !ready {
            print("Not ready to send")
            return
        }
        print("Start sending package, freq: \(1/(data.timestamp - prevTimestamp))Hz")
        prevTimestamp = data.timestamp
        self.ready = false
        self.socket?.emit("update", data.toBytes().base64EncodedString())
        self.ready = true
    }

    func disconnect() {
        self.ready = false
        socket?.disconnect()
        usleep(100000)
        self.socketOpened = false
    }
}
