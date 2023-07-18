//
//  ContentView.swift
//  Remote
//
//  Created by Dmitriy Zharov on 16.07.2023.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State var camera: CameraConnector?
    @State var error: Error?
    
    @State var columnVisibility: NavigationSplitViewVisibility = .automatic
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            if let camera {
                SettingsView(camera: camera)
            } else {
                Button("Connect") {
                    store.bluetooth.connect { result in
                        switch result {
                        case let .success(peripheral):
                            self.camera = peripheral
                        case let .failure(error):
                            self.error = error
                        }
                    }
                }
                
                if let error {
                    Text(error.localizedDescription)
                }
            }
        } detail: {
            
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppStore())
    }
}
