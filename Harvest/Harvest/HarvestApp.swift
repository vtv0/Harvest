//
//  HarvestApp.swift
//  Harvest
//
//  Created by vu the vuong on 23-04-2025.
//

import SwiftUI
import RealmSwift

@main
struct HarvestApp: App {
    
    init() {
        migrateRealm()
    }
    var body: some Scene {
        WindowGroup {
            FishListView()
        }
    }
    
    private func migrateRealm() {
            let config = Realm.Configuration(
                schemaVersion: 3, // tăng version lên mỗi khi bạn sửa model
                migrationBlock: { migration, oldSchemaVersion in
                    if oldSchemaVersion < 3 {
                        // Realm sẽ tự động thêm field mới với giá trị mặc định
                        // Nếu muốn, bạn có thể xử lý migration chi tiết tại đây
                    }
                }
            )
            
            // Áp dụng config mặc định
            Realm.Configuration.defaultConfiguration = config
        }
}
