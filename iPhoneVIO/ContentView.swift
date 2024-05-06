//
//  ContentView.swift
//  iPhoneVIO
//
//  Created by David Gao on 4/26/24.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    @ObservedObject var viewController: ViewController = ViewController()
    @State private var newHostIP: String = "192.168.123.18"
    @State private var newHostPort: String = "5555"

    var body: some View {
        ARViewContainer(viewController: self.viewController)
            .edgesIgnoringSafeArea(.all).overlay(){
                VStack{
                    Text(viewController.displayString)
                        .font(.system(size: 20).monospaced())
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    HStack{
                        TextField("Host IP", text: $newHostIP)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 160)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(16)

                        TextField("Host Port", text: $newHostPort)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(16)
                    }
                    
                    Button{
                        ARManager.shared.actionStream.send(.update(ip: newHostIP, port: Int(newHostPort)!))
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .padding()
                                .background(.regularMaterial)
                                .cornerRadius(16)
                        }
                }.padding()
            }
    }
}


struct ARViewContainer: UIViewControllerRepresentable {
    
    @ObservedObject var viewController: ViewController
    
    func makeUIViewController(context: Context) -> ViewController {
        return self.viewController
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
    }
}


#Preview {
    ContentView()
}
