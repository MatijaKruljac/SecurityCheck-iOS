//
//  TestObject.swift
//  SecurityCheck
//
//  Created by Matija Kruljac on 25.04.2023..
//

import Foundation

class TestObject: NSObject, NSCoding {

    let property1: Int
    let property2: String

    init(property1: Int, property2: String) {
        self.property1 = property1
        self.property2 = property2
    }

    required init?(coder: NSCoder) {
        property1 = coder.decodeInteger(forKey: "property1")
        property2 = coder.decodeObject(forKey: "property2") as? String ?? ""
    }

    func encode(with coder: NSCoder) {
        coder.encode(property1, forKey: "property1")
        coder.encode(property2, forKey: "property2")
    }
}
