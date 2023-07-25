//
//  CameraView.swift
//  Remote
//
//  Created by Dmitriy Zharov on 18.07.2023.
//

import SwiftUI

struct SettingsView: View {
    let camera: CameraConnector
    
    // MARK: Device Info
    
    @State var info: CameraInfo?
    
    // MARK: Geotagging

    @State var geoTag: Bool = false
    @State var geoTagRequest: Bool = true
    
    // MARK: Date & Time
    @State var dateTime: Date?
    
    // MARK: Last Sync Timestamp
    @State var syncTimestamp: Date?
    
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
                    LabeledContent("Camera Info") {
                        ProgressView()
                    }
                }
            }
            
            Section {
                LabeledContent("Geotagging") {
                    Toggle(isOn: $geoTag.onChange { _ in
                        geoTagRequest = true
                    }) {
                        
                    }
                    .disabled(geoTagRequest)
                }
                if geoTag {
                    LabeledContent("Geographic Data") {
                        Text("Automatic")
                    }
                }
                
            } footer: {
                Text("Allow the Remote app to ...")
            }
            
            if let dateTime, let syncTimestamp,
               fabs(dateTime.timeIntervalSince1970 - syncTimestamp.timeIntervalSince1970) > 120 // s
            {
                Section {
                    LabeledContent("Date") {
                        Text(dateTime.formatted(date: .abbreviated, time: .omitted))
                    }
                    LabeledContent("Time") {
                        Text(dateTime.formatted(date: .omitted, time: .standard))
                    }
                } footer: {
                    Text("Camera time doesn't match to current.")
                        .foregroundStyle(.red)
                }
            }
            
        }
        .listStyle(.insetGrouped)
        .task {
            do {
                self.info = try await camera.info()
                self.geoTag = try await camera.geoTag() ?? false
                self.geoTagRequest = false
                self.dateTime = try await camera.dateTime()
                self.syncTimestamp = Date()
            } catch {
                assertionFailure(error.localizedDescription)
            }
        }
        .onChange(of: geoTagRequest) {
            guard geoTagRequest else {
                return
            }
            Task {
                do {
                    try await camera.setGeoTag(geoTag)
                    geoTagRequest = false
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(camera: Virtual())
    }
}
