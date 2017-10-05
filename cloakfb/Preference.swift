//
//  Preference.swift
//  cloakfb
//
//  Created by  Hsu Ching Feng on 06/10/2017.
//  Copyright © 2017 App Design. All rights reserved.
//

import Foundation

class Preference {
    static let shared = Preference()
    private init() {
        UserDefaults.standard.register(defaults: ["friendsSidebar": true])
    }

    var showFriendsSidebar: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "friendsSidebar")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "friendsSidebar")
            UserDefaults.standard.synchronize()
        }
    }
}
