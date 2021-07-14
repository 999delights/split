//
//  PaymentViewModel.swift
//  split
//
//  Created by Andrei Giangu on 09.06.2021.
//

import Foundation
import Firebase


class PaymentViewModel: ObservableObject {

    var nameLimit : Int = 12
    var priceLimit : Double = 99999
    var priceLimit2: Int = 6
    var priceLimit3: Int = 8
    @Published var numberToggled = 0
    @Published var toggle1 = false
    @Published var toggleToti = false
    
    @Published var changed: [String:Bool] = [:]
    
    @Published var payments : Payment = Payment(id: "", by: "", name: "", price: "", isToggled: [:], split: [:], group: "", part: [],date: Date()){
        didSet {
            
            
            for (k,_) in payments.split {
                if payments.split[k]?.count ?? 0 > priceLimit3 {
                    payments.split[k] = String(payments.split[k]?.prefix(priceLimit3) ?? "")
                }
                
            }
            
            
            if payments.name.count > nameLimit {
                payments.name = String(payments.name.prefix(nameLimit))
            }

                if Double(payments.price) ?? 0 > priceLimit{
                    payments.price = String(priceLimit.clean)
                }
                
            if payments.price.count > priceLimit2{
                payments.price = String(payments.price.prefix(priceLimit2))
            }
            
            if payments.price.count == priceLimit2 && payments.price.last == "," || payments.price.last == "."{
                payments.price.removeLast()
            }
        }
    }

    
    private var db = Firestore.firestore()
    
    
    func createPayment(group: String, by: String){
        
        if(Auth.auth().currentUser != nil){
            
        let Userid = Auth.auth().currentUser?.uid
        
        let newDocument = db.collection("payments").document()
        
        payments.id = "\(newDocument.documentID)"
        payments.by = by
        payments.group = group
        payments.date = Date()
        
            let newnewDocument = db.collection("groups").document("\(group)")
            
            newnewDocument.updateData(["paymentsId.\(Userid)" :  "\(newDocument.documentID)"])
            
            
        do{
       let _ =  try newDocument.setData(from:payments)
            
        }
        catch{
            print(error)
        }
        
        
    }
    
    }
    
    
    func updatePayment(paymentID: String, group: String){
        if(Auth.auth().currentUser != nil){
            
            let newDocument = db.collection("payments").document("\(paymentID)")
            
            newDocument.updateData(["split" : payments.split])
            newDocument.updateData(["isToggled": payments.isToggled])
            newDocument.updateData(["part": payments.part])
            
        }
        
    }

    
}
