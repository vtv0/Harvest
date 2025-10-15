//
//  FishViewModel.swift
//  Harvest
//
//  Created by vu the vuong on 11-06-2025.
//

import Foundation
import SwiftUI
import RealmSwift


final class FishViewModel: ObservableObject {
    @Published var fishes: [FishModel] = []
    private var token: NotificationToken?
    
    private var realm: Realm? {
        try? Realm()
    }

    init() {
        loadAll()
        // Tự động cập nhật khi Realm thay đổi
        if let results = realm?.objects(FishModel.self) {
            token = results.observe { [weak self] _ in
                self?.loadAll()
            }
        }
    }

    deinit {
        token?.invalidate()
    }
    
    private func loadAll() {
        if let results = realm?.objects(FishModel.self).sorted(byKeyPath: "priceFish") {
            fishes = Array(results)
        }
    }
    
    func addFish(name: String, price: Double, imageData: Data?) {
        let fish = FishModel()
        fish.idFish = UUID().uuidString
        fish.nameFish = name
        fish.priceFish = price
        fish.imageFish = imageData
        
        try? realm?.write {
            realm?.add(fish)
        }
    }
    
    func update(_ fish: FishModel, name: String, price: Double, imageData: Data?) {
        guard let realm = fish.realm else { return }
        // thaw object
        if let thawedFish = fish.thaw() {
            try? realm.write {
                thawedFish.nameFish = name
                thawedFish.priceFish = price
                thawedFish.imageFish = imageData
            }
        }
    }

    
    func delete(at offsets: IndexSet) {
        guard let realm = realm else { return }
        let toDelete = offsets.map { fishes[$0] }
        try? realm.write {
            realm.delete(toDelete)
        }
    }
}
