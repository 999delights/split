//
//  groups.swift
//  split
//
//  Created by Andrei Giangu on 09.06.2021.
//

import Foundation
import FirebaseFirestoreSwift

struct Event: Identifiable,Codable, Hashable{
    var id: String
    var name: String
    var profilePic: String
    var users: [String]  //users id
    var paymentsId: [String:String]  //userid/paymentid
    var date: Date
    var color: String
    var createdUsers: [String:String] //id : name
    
    enum CodingKeys: String, CodingKey {
      case id
      case name
      case profilePic
      case users
      case paymentsId
      case date
      case color
      case createdUsers
    }
    
}





extension Optional where Wrapped == String {
    var _bound: String? {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    public var bound: String {
        get {
            return _bound ?? ""
        }
        set {
            _bound = newValue.isEmpty ? nil : newValue
        }
    }
}
