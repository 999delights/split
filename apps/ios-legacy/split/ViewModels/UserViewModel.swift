//
//  UserViewModel.swift
//  split
//
//  Created by Andrei Giangu on 24.05.2021.
//

import Foundation
import SwiftUI
import Firebase

class UserViewModel: ObservableObject{
    
    @Published var user: User = User(id: "", email: "", nickname: "", profilePic: "", groups: [])

    
    
    private var db = Firestore.firestore()
    

    func logWithEmail(email:String){
        let Userid = Auth.auth().currentUser?.uid
       
        let newDocument = db.collection("users").document("\(Userid ?? "")")
   
        newDocument.setData(["id" : "\(newDocument.documentID)", "email": "\(email.trimmingCharacters(in: .whitespacesAndNewlines))"],merge:true )
    }
    
    
    func saveNewUser(email:String){
        logWithEmail(email: email)
    }
    

    
    func addUserLog(user: User) {
        
        let Userid = Auth.auth().currentUser?.uid
   
        let newDocument = db.collection("users").document("\(Userid ?? "")")

        newDocument.setData(["nickname":"\(user.nickname.trimmingCharacters(in: .whitespacesAndNewlines))","profilePic": "" , "groups":[]] ,merge:true)
    
    }
    
    
    
    
    
    
    

    
    func save(){
        
        addUserLog(user:user)
    }
 

    
    
    
    
    
@Published var id = ""
    
}
