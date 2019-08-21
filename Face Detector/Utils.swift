//
//  Utils.swift
//  Face Detector
//
//  Created by Manjit Bedi on 2019-08-21.
//  Copyright © 2019 Noorg. All rights reserved.
//

import Foundation

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}
