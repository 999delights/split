//
//  User.swift
//  split
//
//  Created by Andrei Giangu on 04.06.2021.
//

import Foundation
import FirebaseFirestoreSwift



struct User: Identifiable, Codable,Hashable {
    var id: String
    var email: String
    var nickname: String
    var profilePic: String
    var groups: [String]
    
    enum CodingKeys: String, CodingKey {
      case id
      case email
      case nickname
      case profilePic
        case groups
    }
}










