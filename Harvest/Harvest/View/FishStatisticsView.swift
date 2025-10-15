//
//  FishStatisticsView.swift
//  Harvest
//
//  Created by vu the vuong on 08-09-2025.
//

import SwiftUI
import RealmSwift

// dùng String vì WeighModel primary key là idWeigh: String
struct WeighID: Identifiable {
    let id: String
}

// nhỏ gọn: render 1 hàng cân
struct WeighRowView: View {
    let weigh: WeighModel
    let position: Int
    let formatter: NumberFormatter
    let price: Double

    var body: some View {
        let amount = weigh.weightNet * price
        HStack {
            Text("\(position + 1)")
                .frame(width: 40, alignment: .center)
            Spacer().frame(width: 8)

            Text(weigh.weightGross as NSNumber, formatter: formatter)
                .frame(width: 80, alignment: .center)

            Text(weigh.tare as NSNumber, formatter: formatter)
                .frame(width: 80, alignment: .center)

            // weightNet là computed property trong model
            Text(weigh.weightNet as NSNumber, formatter: formatter)
                .frame(width: 80, alignment: .center)

            Text(amount as NSNumber, formatter: formatter)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct FishStatisticsView: View {
    @ObservedRealmObject var fish: FishModel
    @State private var editingWeighID: WeighID?

    // --- state cho xác nhận xóa ---
    @State private var idsToConfirmDelete: [String] = []
    @State private var showingDeleteConfirmation = false

    var formatNumber: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let priceFish = String(format: "%.2f", fish.priceFish)

            Text("Thống kê: \(fish.nameFish) - Giá: \(priceFish)")
                .font(.title2)
                .bold()
                .padding(.vertical)

            HStack {
                Text("STT").frame(width: 40, alignment: .center)
                Spacer().frame(width: 8)
                Text("Cân").frame(width: 80, alignment: .center)
                Text("Bì").frame(width: 80, alignment: .center)
                Text("Tịnh").frame(width: 80, alignment: .center)
                Text("Thành\ntiền").frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.headline)
            .padding(.horizontal)
            .background(Color.gray.opacity(0.2))

            let indices = Array(fish.weighs.indices)
            List {
                ForEach(indices, id: \.self) { idx in
                    let weigh = fish.weighs[idx]
                    WeighRowView(weigh: weigh, position: idx, formatter: formatNumber, price: fish.priceFish)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // lưu id (String)
                            editingWeighID = WeighID(id: weigh.idWeigh)
                        }
                        .listRowInsets(EdgeInsets())
                }
                .onDelete { indexSet in
                    // 1) Lấy danh sách id từ snapshot (safe)
                    let toDeleteIndexes = indexSet.map { indices[$0] }
                    let ids: [String] = toDeleteIndexes.compactMap { idx in
                        return fish.weighs[idx].idWeigh
                    }

                    guard !ids.isEmpty else { return }

                    // Lưu state và show alert để xác nhận
                    idsToConfirmDelete = ids
                    showingDeleteConfirmation = true
                }

                // Tổng tiền
                HStack {
                    Text("TT").font(.headline).frame(width: 40, alignment: .leading)
                    Spacer().frame(width: 8)
                    
                    // tổng cân
                    Text(sumGross as NSNumber, formatter: formatNumber)
                        .frame(maxWidth: 80, alignment: .center)
                    
                    // bì
                    Text(sumTare as NSNumber, formatter: formatNumber)
                        .frame(maxWidth: 80, alignment: .center)
                    
                    // net
                    Text(sumNet as NSNumber, formatter: formatNumber)
                        .frame(maxWidth: 80, alignment: .center)
                    
                    Text(sumAmount as NSNumber, formatter: formatNumber)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title3)
                        .foregroundColor(.red)
                        .bold()
                }
                .padding()
                .listRowInsets(EdgeInsets())
            }
            .listStyle(.plain)
            .listSectionSpacing(0)
        }
        // sheet edit (bạn nhớ implement FishWeighView init with editing id String)
        .sheet(item: $editingWeighID) { wrapper in
            if let realm = try? Realm(),
               let _ = realm.object(ofType: WeighModel.self, forPrimaryKey: wrapper.id) {
                FishWeighView(fish: fish, editingWeighID: wrapper.id)
            } else {
                Text("Không tìm thấy cân để chỉnh sửa")
                    .padding()
            }
        }
        // --- Alert xác nhận xóa ---
        .alert(
            Text("Xác nhận xóa"),
            isPresented: $showingDeleteConfirmation,
            presenting: idsToConfirmDelete
        ) { ids in
            Button(role: .destructive) {
                deleteWeighs(ids: ids)
            } label: {
                Text("Xóa")
            }

            Button(role: .cancel) {
                idsToConfirmDelete = []
            } label: {
                Text("Hủy")
            }
        } message: { ids in
            Text("Bạn có chắc muốn xóa \(ids.count) mục không?")
        }
    }

    private var sumGross: Double {
       fish.weighs.reduce(0) { $0 + $1.weightGross }
    }

    private var sumTare: Double {
       fish.weighs.reduce(0) { $0 + $1.tare }
    }

    private var sumNet: Double {
       fish.weighs.reduce(0) { $0 + $1.weightNet }
    }

    private var sumAmount: Double {
       fish.weighs.reduce(0) { $0 + ($1.weightNet * fish.priceFish) }
    }

    // Hàm xóa (tái sử dụng liveRealm pattern của bạn)
    private func deleteWeighs(ids: [String]) {
        @MainActor func liveRealm() throws -> Realm {
            if let r = fish.realm, !r.isFrozen {
                return r
            }
            if let frozen = fish.realm {
                return try Realm(configuration: frozen.configuration)
            } else {
                return try Realm()
            }
        }

        do {
            let realm = try liveRealm()

            // ensure we are on the same thread as realm (UI/main thread)
            if Thread.isMainThread == false {
                DispatchQueue.main.async {
                    do {
                        try realm.write {
                            for id in ids {
                                if let live = realm.object(ofType: WeighModel.self, forPrimaryKey: id) {
                                    realm.delete(live)
                                }
                            }
                        }
                    } catch {
                        print("Realm delete error (async main):", error)
                    }
                }
                // dọn state
                idsToConfirmDelete = []
                showingDeleteConfirmation = false
                return
            }

            try realm.write {
                for id in ids {
                    if let live = realm.object(ofType: WeighModel.self, forPrimaryKey: id) {
                        realm.delete(live)
                    }
                }
            }
        } catch {
            print("Failed to open live Realm or delete: \(error)")
        }

        // dọn state
        idsToConfirmDelete = []
        showingDeleteConfirmation = false
    }
}

