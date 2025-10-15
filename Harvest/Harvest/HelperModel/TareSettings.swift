//
//  HelperModel.swift
//  Harvest
//
//  Created by vu the vuong on 26-09-2025.
//

import SwiftUI
// lưu và dùng json thay cho realm
struct TareSettings {
    static let key = "tareSettings"

    static func load() -> [String: Double] {
        if let data = UserDefaults.standard.data(forKey: key),
           let dict = try? JSONDecoder().decode([String: Double].self, from: data) {
            return dict
        }
        return [:]
    }

    static func save(_ dict: [String: Double]) {
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

//#Preview {
//    TareSettings.load()
//}
//
