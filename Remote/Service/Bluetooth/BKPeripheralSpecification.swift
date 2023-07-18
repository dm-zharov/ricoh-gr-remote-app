//
//  BKPeripheralSpecification.swift
//  Remote
//
//  Created by Dmitriy Zharov on 18.07.2023.
//

import Foundation

enum BKPeripheralSpecification {
    case identifier(_ uuid: UUID)
    case peripheral(_ name: String)
}
