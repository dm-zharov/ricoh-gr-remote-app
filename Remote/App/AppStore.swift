//
//  AppStore.swift
//  Remote
//
//  Created by Dmitriy Zharov on 18.07.2023.
//

import Foundation

class AppStore: ObservableObject {
    let bluetooth = BKCentralManager(for: .peripheral("GR_"), restoreIdentifier: "Remote")
}
