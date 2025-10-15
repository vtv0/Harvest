//
//  WeighModel.swift
//  Harvest
//
//  Created by vu the vuong on 08-09-2025.
//

import Foundation
import RealmSwift

class WeighModel: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var idWeigh = UUID().uuidString
    @Persisted var weightGross: Double = 0.0      // số kg cân được (cả bì)
    @Persisted var price: Double = 0.0       // giá tại thời điểm cân
    @Persisted var tare: Double = 0.0        // bì (mặc định 0, có thể chỉnh sửa)
    @Persisted var date: Date = Date()

    var weightNet: Double { max(0, weightGross - tare) }
    // Tự động tính tiền
    var totalAmount: Double {
        let netWeight = max(0, weightGross - tare)
        return netWeight * price
    }

    @Persisted(originProperty: "weighs") var fish: LinkingObjects<FishModel>
}
