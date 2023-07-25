//
//  Binding+Change.swift
//  Remote
//
//  Created by Dmitriy Zharov on 19.07.2023.
//

import SwiftUI

extension Binding {
    public func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}
