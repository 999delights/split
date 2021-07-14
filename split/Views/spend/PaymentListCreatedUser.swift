//
//  PaymentList.swift
//  split
//
//  Created by Andrei Giangu on 12.07.2021.
//

import SwiftUI

struct PaymentListCreatedUser: View {
    @EnvironmentObject var helper : Helper
    @EnvironmentObject var info : AppDelegate
    @EnvironmentObject var payments : PaymentViewModel
    @State var groupID: String
    @State var userID : String
    @Environment(\.colorScheme) var scheme
    var body: some View {
        
        VStack{
        ForEach(payments.payments.split.sorted(by: >), id: \.key) { key, value in
            
            let createdUsers = info.groups[helper.find(value:groupID, in:info.groups) ?? 0].createdUsers
            ForEach(createdUsers.keys.sorted(), id:\.self) { user in
                
                if(key == user) {
                    if user == userID{
                    if(value != "") {
                        
                        VStack{
                            
                            HStack{
                                
                                profilePicUSERS(image: "", name: createdUsers[user]!, r: 30)
                                
                                
                                
                                
                                
                                Text("Me")
                                    
                                    
                                    .foregroundColor(Color.blue)
                                    .fontWeight(.medium)
                                
                                
                                Spacer()
                                
                                
                                Text("\(value)")
                                   
                                    .foregroundColor(user == userID ? Color.red.opacity(0.5) :  Color.green  )
                                    .fontWeight(.medium)
                            }
                            
                            
                        
                            
                        }.padding(.trailing)
                        .background(BlurView())
                        .cornerRadius(20)
                        .padding(.leading,20)
                        .padding(.trailing,20)
                        .shadow(color: Color.black.opacity(0.01),radius:1 , x:1 , y:1)
                        .shadow(color: Color.black.opacity(0.01),radius:1 , x:-1 , y:-1)
                        
                        
                        
                    }
                    }
                }

            }
            
            ForEach(createdUsers.keys.sorted(), id:\.self) { user in
                
                if(key == user) {
                    if user != userID{
                    if(value != "") {
                        
                        VStack{
                            
                            HStack{
                                
                                profilePicUSERS(image: "", name: createdUsers[user]!, r: 30)
                                
                                
                               
                                
                                Text("\(createdUsers[user]!)")
                                    
                                    
                                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                                    .fontWeight(.medium)
                                
                                
                            
                                
                                Spacer()
                                
                                
                                Text("\(value)")
                                   
                                    .foregroundColor(user == userID ? Color.red.opacity(0.5) :  Color.green  )
                                    .fontWeight(.medium)
                            }
                            
                            
                        
                            
                        }.padding(.trailing)
                        .background(BlurView())
                        .cornerRadius(20)
                        .padding(.leading,20)
                        .padding(.trailing,20)
                        .shadow(color: Color.black.opacity(0.01),radius:1 , x:1 , y:1)
                        .shadow(color: Color.black.opacity(0.01),radius:1 , x:-1 , y:-1)
                        
                        
                        
                    }
                    }
                }

            }
            
            ForEach(info.usersInGroup.indices, id:\.self) { i in
                if(key == info.usersInGroup[i].id) {
                    if(value != "") {
                        
                        VStack{
                            
                            HStack{
                                
                                profilePicUSERS(image: info.usersInGroup[i].profilePic, name: info.usersInGroup[i].nickname, r: 30)
                                
                        
                               
                                
                                Text("\(info.usersInGroup[i].nickname)")
                                    
                                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                                    .fontWeight(.medium)
                                
                                
                                Spacer()
                                
                                Text("\(value)")
                                    
                                    .foregroundColor(Color.green)
                                    .fontWeight(.medium)
                            }
                            
                        }.padding(.trailing)
                        .background(BlurView())
                        .cornerRadius(20)
                        .padding(.leading,20)
                        .padding(.trailing,20)
                        .shadow(color: Color.black.opacity(0.01),radius:1 , x:1 , y:1)
                        .shadow(color: Color.black.opacity(0.01),radius:1 , x:-1 , y:-1)
                   
            }

        }
    }
            
            
            
           

}
    }
        
    }
}


