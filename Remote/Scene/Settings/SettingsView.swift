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
    @State var geotagging: Bool = false
    @State var batteryLevel: BatteryLevel?
    
    var body: some View {
        List {
            Section {
                if let info {
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
                } else {
                    ProgressView()
                }
            }
            
            Section {
                Toggle("Geotagging", isOn: $geotagging)
            } footer: {
                Text("Allow the Remote app to ...")
            }
            
            Section {
                if let batteryLevel = batteryLevel {
                    Text(batteryLevel)
                } else {
                    ProgressView()
                }
            }
            
        }
        .listStyle(.insetGrouped)
        .task {
            do {
                self.info = try await camera.info()
                self.geotagging = try await camera.geoTag() ?? false
                self.batteryLevel = try await camera.batteryLevel()
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(camera: Virtual())
    }
}
