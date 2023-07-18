//
//  App.swift
//  Remote
//
//  Created by Dmitriy Zharov on 16.07.2023.
//

import SwiftUI

@main
struct App: SwiftUI.App {
    private let store = AppStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
