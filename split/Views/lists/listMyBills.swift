//
//  listMyBills.swift
//  split
//
//  Created by Andrei Giangu on 23.06.2021.
//

import SwiftUI

struct listMyBills: View {
    @EnvironmentObject var info : AppDelegate
    @EnvironmentObject var helper : Helper
    @Environment(\.colorScheme) var scheme
    var item: Payment
    
    var body: some View {
        
        
        HStack(spacing:22){


        ForEach(info.users.indices, id:\.self){j in
            if(info.users[j].id == item.by){

                ForEach(info.groups.indices, id:\.self){k in
                    if(item.group == info.groups[k].id){

                        profilePicGROUPS(image: info.groups[k].profilePic, name: info.groups[k].name, r: 40, t: 20, color: info.groups[k].color)
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
                
                }
                HStack{
                    
                    Text("You get back \(Text(helper.totalGivePerPayment(payments: info.payments, userID: info.userLog.id, paymentID: item.id)).font(.subheadline))")
                        .foregroundColor(Color("Cgroup5").opacity(0.75))
                        .font(.caption2)
                        .fontWeight(.bold)
                    
                    
                }
                HStack{
                    ForEach(item.split.keys.sorted(), id: \.self) { key in
                        if(key == info.userLog.id){

                            Text("Spent \(Text(Double(item.split[key]!)!.clean2).font(.subheadline))")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color("red"))

                        }
                    }

                   

                   
                    
                    
                }
              
                
       
                })
            .frame(maxWidth: .infinity, alignment: .leading)
           
    



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

