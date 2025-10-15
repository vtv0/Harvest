//
//  HideKeyboard.swift
//  Harvest
//
//  Created by vu the vuong on 22-09-2025.
//

import UIKit


extension UIApplication {
    func hideKeyBoard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
