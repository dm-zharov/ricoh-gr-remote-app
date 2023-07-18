//
//  CameraView.swift
//  Remote
//
//  Created by Dmitriy Zharov on 18.07.2023.
//

import SwiftUI

struct SettingsView: View {
    let camera: CameraConnector
    
    @State var info: CameraInfo?
    
    var body: some View {
        List {
            if let info {
                Section {
                    if let version = info.version {
                        LabeledContent("Version", value: version)
                    }
                    if let modelNumber = info.modelNumber  {
                        LabeledContent("Model Number", value: modelNumber)
                    }
                    if let serialNumber = info.serialNumber {
                        LabeledContent("Serial Number", value: serialNumber)
                    }
                    if let bluetooth = info.bluetooth {
                        LabeledContent("Bluetooth", value: bluetooth)
                    }
                }
            } else {
                ProgressView()
                    .task {
                        info = await camera.info()
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(camera: Virtual())
    }
}
