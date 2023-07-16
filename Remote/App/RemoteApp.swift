//
//  RemoteApp.swift
//  Remote
//
//  Created by Dmitriy Zharov on 16.07.2023.
//

import SwiftUI

@main
struct RemoteApp: App {
    private let bluetoothService = BluetoothService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}