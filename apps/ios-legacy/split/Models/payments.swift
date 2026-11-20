//
//  payments.swift
//  split
//
//  Created by Andrei Giangu on 09.06.2021.
//

import Foundation
import FirebaseFirestoreSwift


struct Payment: Identifiable,Codable, Hashable{
    var id: String
    var by: String
    var name: String
    var price: String
    var isToggled: [String:Bool]  //userID - true or false
    var split: [String:String]  // userID - howmuch
    var group: String
    var part: [String]
    var date: Date

    
    enum CodingKeys: String, CodingKey {
      case id
      case name
      case price
      case by
      case isToggled
      case split
      case group
      case part
      case date

    }
    
}



