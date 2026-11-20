//
//  GroupViewModel.swift
//  split
//
//  Created by Andrei Giangu on 09.06.2021.
//

import Foundation
import Firebase


class GroupViewModel: ObservableObject {
    
    var limit:Int = 12
    @Published var groups : Event = Event(id: "", name: "", profilePic: "", users: [], paymentsId: [:], date: Date(), color: "", createdUsers: [:]){
        didSet {
            if groups.name.count > limit {
                groups.name = String(groups.name.prefix(limit))
            }
        }
    }

    
    private var db = Firestore.firestore()
    
    
    func createGroup(){
             
        let Userid = Auth.auth().currentUser?.uid
        let newDocument = db.collection("groups").document()
  
        let random = Int.random(in: 1..<17)
        groups.color = "Cgroup\(random)"
        groups.id = "\(newDocument.documentID)"
        groups.users.append(Userid!)
        groups.date = Date()
        let newNewDocument = db.collection("users").document("\(Userid ?? "")")

        newNewDocument.updateData(["groups": FieldValue.arrayUnion(["\(newDocument.documentID)"])])
     
        do{
       let _ =  try newDocument.setData(from:groups)
            
        }
        catch{
            print(error)
        }
    }
    

    
    
}



