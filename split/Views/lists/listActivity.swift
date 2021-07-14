//
//  listActivity.swift
//  split
//
//  Created by Andrei Giangu on 23.06.2021.
//

import SwiftUI

struct listActivity: View {
    @EnvironmentObject var info : AppDelegate
    @EnvironmentObject var helper : Helper
    @Environment(\.colorScheme) var scheme
    var item : Payment
    var body: some View {
        
        HStack(spacing:22){


        ForEach(info.users.indices, id:\.self){j in
            if(info.users[j].id == item.by){

                ForEach(info.groups.indices, id:\.self){k in
                    if(item.group == info.groups[k].id){

                        profilePicUserActivity(userName: info.users[j].nickname, r: 45, r2: 25, userImage: info.users[j].profilePic, groupImage: info.groups[k].profilePic, groupName: info.groups[k].name,t:15, color: info.groups[k].color)
                    }


                }


            }
        }

            VStack(alignment: .leading, spacing: 8, content: {
          
                
                HStack{
                    Text("\(item.name)").font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(scheme == .dark ? Color.white : Color.black)
                        .lineLimit(1)
                        .truncationMode(.tail)
                
                Spacer()
                    
                    Text("\(item.price)").foregroundColor(scheme == .dark ? Color.white : Color.black)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                HStack{
                    ForEach(item.split.keys.sorted(), id: \.self) { key in
                        if(key == info.userLog.id){

                            Text("You owe \(Text(item.split[key]!.description).font(.subheadline))")
                                   
                                    .foregroundColor(Color("red"))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                        }
                    }



                    
                }.padding(.leading,5)
                
                
            }).frame(maxWidth: .infinity, alignment: .leading)


      



    }
        .padding(.top,8)
        .padding(.bottom,8)
        .padding(.horizontal)
            .frame(width: (UIScreen.main.bounds.width - 50) , height: 80)
            
            .background(BlurView().opacity(0.5))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(scheme == .dark ? Color.white : Color.black, lineWidth: 1))
            .cornerRadius(15)
            .padding(.top,3)
            .padding(.bottom,3)
    }
}

