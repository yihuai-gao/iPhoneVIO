//
//  ARSessionManager.swift
//  iPhoneVIO
//
//  Created by David Gao on 4/26/24.
//

import Foundation
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate, ObservableObject {
    @Published var displayString: String = ""

    let session = ARSession()
    let socketClient = SocketClient()
    var hostIP: String = "192.168.123.18"

    var hostPort: Int = 5555
    var prevTimestamp: Double = 0.0
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARSession()
        subscribeToActionStream()
    }
    
    func setupARSession() {
        socketClient.connect(hostIP: hostIP, hostPort: hostPort)
        self.publishPose = true
        session.delegate = self
        let configuration = ARWorldTrackingConfiguration()
        session.run(configuration)
    }

    private var cancellables: Set<AnyCancellable> = []
    private var publishPose: Bool = false

    func subscribeToActionStream() {
        
        ARManager.shared
            .actionStream
            .sink { [weak self] action in
                switch action {
                    case .update(let ip, let port):
                        self?.publishPose = false
                        self?.socketClient.disconnect()
                        self?.hostIP = ip
                        self?.hostPort = port
                        print("Reconnecting to ZMQ Publisher: \(self!.hostIP):\(self!.hostPort)")
                        self?.socketClient.connect(hostIP: self!.hostIP, hostPort: self!.hostPort)
                        self?.publishPose = true
                }
            }
            .store(in: &cancellables)
        

    }
    
    // ARSessionDelegate method
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let transform = frame.camera.transform
        let timestamp = frame.timestamp
        let x = transform.columns.3.x
        let y = transform.columns.3.y
        let z = transform.columns.3.z

        displayString = "x: \(String(format: "%.4f", transform[3][0])), y: \(String(format: "%.4f", transform[3][1])), z: \(String(format: "%.4f", transform[3][2])), fps: \(String(format: "%.3f", 1/(timestamp - self.prevTimestamp)))"
        // displayString = "x: \(String(format: "%.4f", x)), y: \(String(format: "%.4f", y)), z: \(String(format: "%.4f", z)), fps: \(String(format: "%.3f", 1/(timestamp - self.prevTimestamp)))"
        prevTimestamp = timestamp
        if publishPose {
            let dataPacket = DataPacket(transformMatrix: transform, timestamp: timestamp)
            socketClient.sendData(dataPacket)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
    }
}
