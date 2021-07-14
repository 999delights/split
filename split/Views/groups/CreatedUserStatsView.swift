//
//  CreatedUserStatsView.swift
//  split
//
//  Created by Andrei Giangu on 12.07.2021.
//

import SwiftUI

struct CreatedUserStatsView: View {
    @EnvironmentObject var info : AppDelegate
    @EnvironmentObject var helper: Helper
    var columns = Array(repeating: GridItem(.flexible(),spacing: 20), count: 2)
    @State var groupID : String
    @State var userID: String
    @Environment(\.colorScheme) var scheme
    
    
    var body: some View {
        
        VStack{
            
            
            ScrollView(showsIndicators: false) {
                
            
                VStack(spacing:18){
                    
                 
                    
                    LazyVGrid(columns: columns,spacing: 20){
                        
                      
                        
                        ForEach(info.usersInGroup.indices, id:\.self){i in
                            let grID = groupID
                            let us1ID = info.usersInGroup[i].id
                            let us2ID = userID
                            let glued = grID + us1ID + us2ID
                            let glued2 = grID + us2ID + us1ID
                            
                            let inf = helper.getGiveOrTake(glued: glued, glued2: glued2)
                            
                            ForEach(inf.sorted(by: >), id: \.key) { key, value in
                            if(info.usersInGroup[i].id != userID){
                            
                            Button(action:{
                            
    
                               
                                
                            }) {
                            VStack{
                                
                                
                                
                             
                                
                                profilePicUSERS(image: info.usersInGroup[i].profilePic, name: info.usersInGroup[i].nickname, r: 55).padding(.top)
                                
                                
                                Text("\(info.usersInGroup[i].nickname)").font(.system(size:18)).foregroundColor(scheme == .dark ?  Color.white : Color.black).fontWeight(.heavy)
                                
                                
                                    
                                    
                                    
                                    Text("\(key)").font(.system(size:15)).foregroundColor(scheme == .dark ?  Color.white : Color.black).fontWeight(.light)

                                
                                    if value != "" {
                                        
                                        
                                        Text("\(value)").font(.system(size:20))
                                            .foregroundColor(key == "owes you" ? Color("Cgroup5").opacity(0.75) : .red.opacity(0.5))
                                            
                                            
                                            .fontWeight(.medium).padding()
                                    }
                                    
                                    else if value == "" {
                                        
                                        Text("Settled Up").font(.system(size:20))
                                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                                            .fontWeight(.medium).padding()
                                        
                                    }
                                    
                            
                                }
                              
                            }
                            
                            .aspectRatio(contentMode: .fill)
                            
                            .frame(width: (UIScreen.main.bounds.width - 50) / 2, height: 180)
                            
                            .overlay(
                                       RoundedRectangle(cornerRadius: 15)
                                        .stroke(scheme == .dark ?  Color.white.opacity(0.3) : Color.black.opacity(0.3), lineWidth: 2)
                                   )
                         
                            }
                            }
                        }
                  
                        let createdUsers = info.groups[helper.find(value:groupID, in: info.groups) ?? 0].createdUsers
                        
                        if createdUsers.count != 0 {
                            
                        ForEach(createdUsers.keys.sorted(), id:\.self){ id1 in
                            let grID = groupID
                            let us1ID = id1
                            let us2ID = userID
                            let glued = grID + us1ID + us2ID
                            let glued2 = grID + us2ID + us1ID
                            let inf = helper.getGiveOrTake(glued: glued, glued2: glued2)
                            
                            ForEach(inf.sorted(by: >), id: \.key) { key, value in
                                
                                if(id1 != userID){
                                
                                Button(action:{
                                    
                              
                                
                                   
                                    
                                })
                            
                                {
                                VStack{
                                    
                                    
                                    profilePicCreatedUsers(name: createdUsers[id1]!, r:55)
                                        .padding(.top)
                                    
                                
                                    
                                    
                                    Text("\(createdUsers[id1]!)").font(.system(size:18)).foregroundColor(scheme == .dark ?  Color.white : Color.black).fontWeight(.heavy)
                                    
                                    
                                        
                                        
                                        
                                        Text("\(key)").font(.system(size:15)).foregroundColor(scheme == .dark ?  Color.white : Color.black).fontWeight(.light)

                                    
                                        if value != "" {
                                            
                                            
                                            Text("\(value)").font(.system(size:20))
                                                .foregroundColor(key == "owes you" ? Color("Cgroup5").opacity(0.75) : .red.opacity(0.5))
                                                
                                                
                                                .fontWeight(.medium).padding()
                                        }
                                        
                                        else if value == "" {
                                            
                                            Text("Settled Up").font(.system(size:20))
                                                .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                                                .fontWeight(.medium).padding()
                                            
                                        }
                                        
                                
                                    }
                                  
                                }
                                
                                .aspectRatio(contentMode: .fill)
                                
                                .frame(width: (UIScreen.main.bounds.width - 50) / 2, height: 180)
                                
                                .overlay(
                                           RoundedRectangle(cornerRadius: 15)
                                            .stroke(scheme == .dark ?  Color.purple.opacity(0.4) : Color.purple.opacity(0.4), lineWidth: 2)
                                       )
                              
                             
                                }

                                
                                
                                
                            }
                            
                        }
                        }
                        
                        
                    }
                    
                }
                
                .padding()
          
            }
        }
       
    }
}

