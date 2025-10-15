//
//  PermissionManager.swift
//  Harvest
//
//  Created by vu the vuong on 19-08-2025.
//

import PhotosUI

class PermissionManager {
    static func requestPhotoPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            completion(true) // đã có quyền
        case .denied, .restricted:
            completion(false) // user từ chối
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        @unknown default:
            completion(false)
        }
    }
}
