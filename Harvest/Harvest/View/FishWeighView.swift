import SwiftUI
import RealmSwift

struct FishWeighView: View {
    @AppStorage("defaultTare") private var defaultTare: String = "4"
    @Environment(\.dismiss) private var dismiss
    
    
    var fish: FishModel
    let editingWeighID: String? // cờ == nil thì tạo mới , != nil thì edit
    
    @State private var rawWeight: String = ""    // trọng lượng tổng
    @State private var useTare = true            // có trừ bì?
    @State private var customTare: String = ""   // sẽ set 30 hoặc 0 tùy loại
    @State private var priceText: String = ""
    
    @ObservedResults(WeighModel.self) var weighs // theo dõi Realm
    private var isFormValid: Bool {
        guard let weight = Double(rawWeight), weight > 0 else { return false }
        return true
    }

    
    private var isTramFish: Bool {
//        fish.nameFish.lowercased().contains("trắm")
        return true
    }
    
    private var tareValue: Double {
        guard useTare else { return 0 }

        // Lấy danh sách bì đã lưu từ UserDefaults
        let savedTare = TareSettings.load()

        // Nếu có bì cho cá này → dùng, không thì mặc định 0
        let fishTare = savedTare[fish.nameFish] ?? 0

        return fishTare
    }

    private var totalWeight: Double {
        Double(rawWeight) ?? 0
    }
    private var netWeight: Double {
        max(totalWeight - tareValue, 0)
    }
    
    init (fish: FishModel, editingWeighID: String? = nil) {
        self.fish = fish
        self.editingWeighID = editingWeighID
        
        if let id = editingWeighID {
            if let realm = try? Realm(),
               let weigh = realm.object(ofType: WeighModel.self, forPrimaryKey: id) {  // sửa
                _rawWeight = State(initialValue: String(weigh.weightGross))
                _customTare = State(initialValue: String(weigh.tare))
                _useTare = State(initialValue: weigh.tare > 0)
                _priceText = State(initialValue: String(weigh.price))
            } else {
                // fallback
                _rawWeight = State(initialValue: "")
                _customTare = State(initialValue: isTramFish ? "4" : "0")
                _useTare = State(initialValue: true)
                _priceText = State(initialValue: String(fish.priceFish))
            }
        } else {
            // create new
            _rawWeight = State(initialValue: "")
            _customTare = State(initialValue: isTramFish ? "4" : "0")
            _useTare = State(initialValue: true)
            _priceText = State(initialValue: String(fish.priceFish))
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("\(fish.nameFish) - Giá: \(fish.priceFish, specifier: "%.2f") VND/kg")) {
                    Group {
                        if #available(iOS 17.0, *) {
                            TextField("Nhập trọng lượng (kg)", text: $rawWeight)
                                .keyboardType(.decimalPad)
                                .onChange(of: rawWeight) { _, newValue in
                                    // Cho phép nhập dấu phẩy hoặc chấm -> thay về dấu chấm
                                    rawWeight = newValue.replacingOccurrences(of: ",", with: ".")
                                }
                        } else {
                            TextField("Nhập trọng lượng (kg)", text: $rawWeight)
                                .keyboardType(.decimalPad)
                                .onChange(of: rawWeight) { newValue in
                                    // Cho phép nhập dấu phẩy hoặc chấm -> thay về dấu chấm
                                    rawWeight = newValue.replacingOccurrences(of: ",", with: ".")
                                }
                        }
                    }
                }
                
                Section(header: Text("Tùy chọn bì")) {
                    Toggle(isOn: $useTare) {
                        Text("Có trừ bì")
                    }

                    if useTare {
                        TextField("Nhập bì (kg)", text: $customTare)
                            .keyboardType(.decimalPad)
                        
                        HStack {
                            Text("Bì trừ:")
                            Spacer()
                            Text("\(Double(customTare) ?? 0, specifier: "%.2f") kg")
                        }
                    }
                }


                Section(header: Text("Kết quả")) {
                    HStack {
                        Text("Trọng lượng tịnh:")
                        Spacer()
                        Text("\(netWeight, specifier: "%.2f") kg")
                    }
                    HStack {
                        Text("Tổng tiền:")
                        Spacer()
                        // priceText có thể sửa — ưu tiên priceText nếu có
                       let price = Double(priceText) ?? fish.priceFish
                       Text("\(netWeight * price, specifier: "%.2f") VND")
                    }
                }
            }
            .navigationTitle(editingWeighID == nil ? "Nhập cân mới" : "Sửa trọng lượng")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        saveWeigh()
                        dismiss()
                    }
                    .disabled(!isFormValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
            }
            .onAppear {
                // Khi mở view: lấy bì đã lưu theo tên cá
                let savedTare = TareSettings.load()
                if let tare = savedTare[fish.nameFish] {
                    customTare = String(tare)
                } else {
                    customTare = "0"
                }
            }

        }
    }
    
    private func saveWeigh() {
        let realm = try! Realm()
        let gross = Double(rawWeight) ?? 0
        let tare = useTare ? (Double(customTare) ?? (isTramFish ? 4 : 0)) : 0
        let net = max(gross - tare, 0)
        let price = Double(priceText) ?? fish.priceFish
        
        do {
            try realm.write {
                if let id = editingWeighID {
                    // editingWeighID kiểu String (idWeigh), vì bạn dùng UUID string
                    if let live = realm.object(ofType: WeighModel.self, forPrimaryKey: id) {
                        // chỉ cập nhật các trường persisted
                        live.weightGross = gross
                        live.tare = tare
                        live.price = price
                        // KHÔNG gán live.weightNet vì nó là computed
                    } else {
                        // fallback: tạo mới nếu không tìm thấy
                        let newWeigh = WeighModel()
                        newWeigh.weightGross = gross
                        newWeigh.tare = tare
                        newWeigh.price = price
                        realm.add(newWeigh)
                        if let fishObj = realm.object(ofType: FishModel.self, forPrimaryKey: fish.idFish) {
                            fishObj.weighs.append(newWeigh)
                        }
                    }
                } else {
                    // create new weigh
                    let newWeigh = WeighModel()
                    newWeigh.weightGross = gross
                    newWeigh.tare = tare
                    newWeigh.price = price
                    realm.add(newWeigh)
                    if let fishObj = realm.object(ofType: FishModel.self, forPrimaryKey: fish.idFish) {
                        fishObj.weighs.append(newWeigh)
                    }
                }
            }
        } catch {
            print("Realm save error:", error)
        }

    }
}

