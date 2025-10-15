//
//  FishModel.swift
//  Harvest
//
//  Created by vu the vuong on 23-04-2025.
//

import UIKit
import RealmSwift

class FishModel: Object , ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var idFish: String
    @Persisted var nameFish: String
    @Persisted var priceFish: Double
    @Persisted var imageFish: Data?
    @Persisted var hasBii: Bool = false 
    @Persisted var weighs = List<WeighModel>()
}
