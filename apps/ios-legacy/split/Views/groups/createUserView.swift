//
//  createUserView.swift
//  split
//
//  Created by Andrei Giangu on 11.07.2021.
//

import SwiftUI
import Firebase
struct createUserView: View {
    @EnvironmentObject var info : AppDelegate
    @EnvironmentObject var helper: Helper
    @Environment(\.colorScheme) var scheme
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()
    @State var groupID : String
    @State var name = ""
    var body: some View {
        ZStack{
            

            scheme == .dark ? Color.black.ignoresSafeArea() :  Color.white.ignoresSafeArea()
            
            VStack{
            HStack{
                
                
               Spacer()
            
                
                Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }
                ,label:{
                    Text("Cancel")
                        
                        .padding()
                        .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                      
                })
                
            }
                
              Spacer()
              }.ignoresSafeArea(.keyboard)
            
            VStack{
                Spacer()
                
                HStack{
                    
                Text("Throw his nickname")
                    .font(.system(size:25))
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    .fontWeight(.heavy)
                    .padding(.leading)
                    .padding(.bottom,30)
             
                    
                          Spacer()
                
                }
                
                TextField("ex. 'John' ", text: $name).modifier(ClearButton(text: $name))
        .padding(.leading)
        .padding(.trailing)
        .keyboardType(.default)
        .font(.system(size: 25, weight: .medium, design: .default))
                    .onChange(of: self.name){ value in
            if (name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
                name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            }}
        .foregroundColor(Color.purple)
        
            .introspectTextField { textField in
                textField.becomeFirstResponder()
                
                
            }
                
                Divider()
                    .padding(.horizontal)
                    .padding(.bottom,10)
                 
            
               Button(action:{
                
                createUser(groupID: groupID, name: name)
                debtPerPersonXperson()
                
               
                presentationMode.wrappedValue.dismiss()
                
               }, label:{
                   Text("Create")
                       .fontWeight(.semibold)
                       .foregroundColor(.white)
                       .padding(.vertical,15)
                       .frame(maxWidth:.infinity)
                       .background(Color.green)
                       .cornerRadius(12)
                       .padding(.leading,20)
                       .padding(.trailing,20)
                    .keyboardAware()
               }).disabled(name == "" )
               .opacity((name == "") ? 0.6  : 1)
                
                
                
            }.ignoresSafeArea(.keyboard, edges: .bottom)
            
            
        }
    }
    
    
    
    func createUser(groupID: String, name: String){
        
        var db = Firestore.firestore()
        
        let newnewDocument = db.collection("groups").document("\(groupID)")
        let id  = UUID()
        newnewDocument.updateData(["createdUsers.\(id)" :  "\(name)"])
        
        
    }
    
    func debtPerPersonXperson() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            
            for i in info.groups {
                if(i.users.count != 0){
                    for k in i.users {
                        for j in i.users {
                           
                                            
                                   let glued = i.id + k + j
                      
                                helper.matrix["\(glued)"] = Double(0)
                            
                           
                                            
                                            for p in info.payments{
                                                if(p.group == i.id){
                                                    for (key,value) in p.split{
                                                        if key == k {
                                                            if(p.by == j){
                                                                
                                                                if(value != ""){
                                                                    
                                                                    let glued = i.id + k + j
                                                                 
                                                                    
                                                                    helper.matrix["\(glued)"]! += Double(value)!
                                                                    
                                                                    
                                                                   
                                                                    
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                            
                            
                         
                                            
                                        } }
                         
                    
                    
                }
            }
            
            for i in info.groups{
                if(i.users.count != 0){
                if(i.createdUsers.count != 0){
                    for (key,value) in i.createdUsers {
                        for k in i.users {
                            
                            let glued = i.id + key + k
                            
                            helper.matrix["\(glued)"] = Double(0)
                            
                            for p in info.payments{
                                if(p.group == i.id){
                                    for (key2,value2) in p.split{
                                        if key2 == key {
                                            if(p.by == k){
                                                
                                                if(value2 != ""){
                                                    
                                                    let glued = i.id + key + k
                                                 
                                                    
                                                    helper.matrix["\(glued)"]! += Double(value2)!
                                                    
                                                    
                                                   
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
        }
            
            for i in info.groups{
                if(i.users.count != 0){
                if(i.createdUsers.count != 0){
                    for k in i.users {
                    for (key,value) in i.createdUsers {
                        
                            
                            let glued = i.id + k + key
                            
                            helper.matrix["\(glued)"] = Double(0)
                            
                            for p in info.payments{
                                if(p.group == i.id){
                                    for (key2,value2) in p.split{
                                        if key2 == k {
                                            if(p.by == key){
                                                
                                                if(value2 != ""){
                                                    
                                                    let glued = i.id + k + key
                                                 
                                                    
                                                    helper.matrix["\(glued)"]! += Double(value2)!
                                                    
                                                    
                                                   
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
        }
            
            for i in info.groups{
              
                if(i.createdUsers.count != 0){
                    for (key,value) in i.createdUsers {
                        for (key2,value2) in i.createdUsers {
                            
                            let glued = i.id + key + key2
                            
                            helper.matrix["\(glued)"] = Double(0)
                            
                            for p in info.payments{
                                if(p.group == i.id){
                                    for (key3,value3) in p.split{
                                        if key3 == key {
                                            if(p.by == key2){
                                                
                                                if(value2 != ""){
                                                    
                                                    let glued = i.id + key + key2
                                                 
                                                    
                                                    helper.matrix["\(glued)"]! += Double(value3)!
                                                    
                                                    
                                                   
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                
            }
        }
        
      
            subtractMirroringDebts()
            smartTransferDebts()
       
        }
    }
    
    
    func subtractMirroringDebts() {
         for group in info.groups {
             if(group.users.count != 0){
                 for i in group.users{
                     for j in group.users {
                         if(i != j) {
                            let glued = group.id + i + j
                            let glued2 = group.id + j + i
                             if(helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]!) {

                                 helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                                 helper.matrix["\(glued2)"]! = 0

                             }
                             else {

                                 helper.matrix["\(glued2)"]! -=   helper.matrix["\(glued)"]!
                                 helper.matrix["\(glued)"]! = 0

                             }



                         }


                     }

                 }
             }
         }
        
        
        for group in info.groups {
            if(group.users.count  != 0 ){
                for (key,value) in group.createdUsers{
                    for i in group.users {
                        let glued = group.id + key + i
                        let glued2 = group.id + i + key
                        if(helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]!) {

                            helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                            helper.matrix["\(glued2)"]! = 0

                        }
                        else {

                            helper.matrix["\(glued2)"]! -=   helper.matrix["\(glued)"]!
                            helper.matrix["\(glued)"]! = 0

                        }
                    }
                    
                    
                }
                
            }
        }
        
        for group in info.groups {
            if(group.users.count  != 0 ){
                for (key,value) in group.createdUsers{
                    for i in group.users {
                        let glued = group.id + i + key
                        let glued2 = group.id + key + i
                        if(helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]!) {

                            helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                            helper.matrix["\(glued2)"]! = 0

                        }
                        else {

                            helper.matrix["\(glued2)"]! -=   helper.matrix["\(glued)"]!
                            helper.matrix["\(glued)"]! = 0

                        }
                    }
                    
                    
                }
                
            }
        }
    
        for group in info.groups {
            if(group.users.count  != 0 ){
                for (key,value) in group.createdUsers{
                    for (key2,value2) in group.createdUsers {
                        let glued = group.id + key + key2
                        let glued2 = group.id + key2 + key
                        if(helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]!) {

                            helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                            helper.matrix["\(glued2)"]! = 0

                        }
                        else {

                            helper.matrix["\(glued2)"]! -=   helper.matrix["\(glued)"]!
                            helper.matrix["\(glued)"]! = 0

                        }
                    }
                    
                    
                }
                
            }
        }
        
    
     }
    
    func smartTransferDebts(){
        
        for group in info.groups {
            if(group.users.count != 0){
                for i in group.users{
                    for j in group.users{
                        if j != i {
                            for k in group.users {
                                if(k != i && k != j){
                                    
                               
                                
                                let glued = group.id + i + j
                                let glued2 = group.id + j + k
                                let glued3 = group.id + i + k
                                
                                if helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]! {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued2)"]! = 0
                                    
                                }
                                    
                                else {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued2)"]! -= helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued)"]! = 0
                                    
                                }
                            }
                                
                                
                                
                                
                            }
                            
                            
                        }
                        
                        
                        
                    }
                }
                
            }
        }
        
        
        for group in info.groups {
            if(group.users.count != 0){
                for (i,value) in group.createdUsers{
                    for j in group.users{
                        if j != i {
                            for k in group.users {
                                if(k != i && k != j){
                                    
                               
                                
                                let glued = group.id + i + j
                                let glued2 = group.id + j + k
                                let glued3 = group.id + i + k
                                
                                if helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]! {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued2)"]! = 0
                                    
                                }
                                    
                                else {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued2)"]! -= helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued)"]! = 0
                                    
                                }
                            }
                                
                                
                                
                                
                            }
                            
                            
                        }
                        
                        
                        
                    }
                }
                
            }
        }
        for group in info.groups {
            if(group.users.count != 0){
                for (j,value) in group.createdUsers{
                    for i in group.users{
                        if j != i {
                            for k in group.users {
                                if(k != i && k != j){
                                    
                               
                                
                                let glued = group.id + i + j
                                let glued2 = group.id + j + k
                                let glued3 = group.id + i + k
                                
                                if helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]! {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued2)"]! = 0
                                    
                                }
                                    
                                else {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued2)"]! -= helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued)"]! = 0
                                    
                                }
                            }
                                
                                
                                
                                
                            }
                            
                            
                        }
                        
                        
                        
                    }
                }
                
            }
        }
        for group in info.groups {
            if(group.users.count != 0){
                for (i,value) in group.createdUsers{
                    for (j,value) in group.createdUsers{
                        if j != i {
                            for k in group.users {
                                if(k != i && k != j){
                                    
                               
                                
                                let glued = group.id + i + j
                                let glued2 = group.id + j + k
                                let glued3 = group.id + i + k
                                
                                if helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]! {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued2)"]! = 0
                                    
                                }
                                    
                                else {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued2)"]! -= helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued)"]! = 0
                                    
                                }
                            }
                                
                                
                                
                                
                            }
                            
                            
                        }
                        
                        
                        
                    }
                }
                
            }
        }
    }

        
    
    
}

