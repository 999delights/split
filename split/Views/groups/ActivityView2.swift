//
//  ActivityView.swift
//  split
//
//  Created by Andrei Giangu on 10.07.2021.
//

import SwiftUI
import Firebase
import FirebaseDynamicLinks

struct ActivityView2: View {
    
    @EnvironmentObject var info : AppDelegate
    @EnvironmentObject var helper: Helper
    var columns = Array(repeating: GridItem(.flexible(),spacing: 20), count: 2)
    @State var groupID : String
    @State var paymentID : String
    @Environment(\.colorScheme) var scheme
    @Binding var showPayment : Bool
    @Binding var isViewDisplayed : Bool
    @Binding var spend : Bool
    
    var body: some View {
        
        
        VStack{
            
            
            if isViewDisplayed {
            if(info.paymentsInGroup.count == 0){
                
                
                if(info.usersInGroup.count < 2 && info.groups[helper.find(value: groupID, in: info.groups)!].createdUsers.count == 0) {
                    
                    VStack{
                        Spacer()
                        
                        Text("More friends are needed")
                        
                        Button(action:{
                            
                            helper.groupInvite(groupID: groupID, title: info.groups[helper.find(value: groupID, in: info.groups) ?? 0].name)
                        },label:{
                            
                            Text("share link")
                        })
                   
                        Spacer()
                        
                    }
               
                    
                }
                
            if(info.usersInGroup.count >= 2 || info.groups[helper.find(value: groupID, in: info.groups)!].createdUsers.count != 0) {
            
            VStack{
                
                Spacer()
                
                Text("no payments yet")
                
                
                Button("Spend", action:{
                    
                    withAnimation{

                        spend.toggle()
                        }

                })
            
                Spacer()
                
                
            }
       
            }
            }
       
            if(info.paymentsInGroup.count != 0){
                
                ScrollView(showsIndicators: false) {
                    
                    
                    VStack(spacing:18){
                        
                        let sortedPayments = info.paymentsInGroup.sorted {
                $0.date > $1.date
                    }
                        
                    
                            
                        ForEach(sortedPayments.indices, id:\.self){i in
                        
                            if(sortedPayments[i].by == info.userLog.id || sortedPayments[i].part.contains(info.userLog.id) ){
           
                                    
                                    Button(action:{
                                        paymentID = sortedPayments[i].id
                                        helper.indexPayment = helper.find2(value: paymentID, in: info.payments)
                                        showPayment = true
                                        
                                    }) {
                                        HStack(spacing:22){
                                    
                                    ForEach(info.usersInGroup.indices, id:\.self){j in
                                        if(info.usersInGroup[j].id == sortedPayments[i].by){

                                            
                                        profilePicUSERS(image: info.usersInGroup[j].profilePic, name: info.usersInGroup[j].nickname, r: 45)
                                        }
                                    }
                                            
                                            let createdUsers = info.groups[helper.find(value:groupID, in: info.groups) ?? 0].createdUsers
                                            
                                            ForEach(createdUsers.keys.sorted(), id:\.self){id in
                                                
                                                if(id == sortedPayments[i].by){
                                                    
                                                 profilePicCreatedUsers(name: createdUsers[id]!, r: 45)
                                                }
                                                
                                                
                                            }
                                           
                                            VStack(alignment: .leading, spacing: 8, content: {
                                                HStack{
                                                    
                                                    Text("\(sortedPayments[i].name)").font(.title2)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(scheme == .dark ? Color.white : Color.black)
                                                    
                                                    Spacer()
                                                    
                                                    Text("\(sortedPayments[i].price)")   .foregroundColor(scheme == .dark ? Color.white : Color.black)
                                                        .font(.subheadline)
                                                        .fontWeight(.bold)
                                                }
                                                
                                                
                                                
                                                HStack{
                                                    if sortedPayments[i].by == info.userLog.id {
                                                        Text("You get back \(Text(helper.totalGivePerPayment(payments: info.payments, userID: info.userLog.id, paymentID: sortedPayments[i].id)).font(.subheadline))")
                                                                .foregroundColor(Color("Cgroup5").opacity(0.75))
                                                            .font(.caption2)
                                                            .fontWeight(.bold)
                                                        
                                                        
                                                        
                                                    }
                                                }
                                                    HStack{
                                                    
                                                    ForEach(sortedPayments[i].split.keys.sorted(), id: \.self) { key in
                                                        if(key == info.userLog.id){

                                                            if sortedPayments[i].by == info.userLog.id {
                                                                Text("Spent \(Text((Double(sortedPayments[i].split[key]!) ?? 0) .clean2).font(.subheadline))")
                                                                        .font(.caption2)
                                                                    .foregroundColor(Color("red"))
                                                                    .fontWeight(.bold)
                                                                
                                                            }
                                                            
                                                            else {
                                                                Text("You owe \(Text(sortedPayments[i].split[key]!.description).font(.subheadline))")
                                                                        .font(.caption2)
                                                                    .foregroundColor(Color("red"))
                                                                    .fontWeight(.bold)
                                                            }
                                                         

                                                        }
                                                    }
                                                    
                                                }
                                            }).frame(maxWidth: .infinity, alignment: .leading)
                                   
                                            
                            
                                    
                                            
                                    
                               
                               
                                    
                                    
                              

                                    
                                    
                                       
                              
                                    
                                    }
                                   .padding(.top,8)
                                   .padding(.bottom,8)
                                   .padding(.horizontal)
                                       .frame(width: (UIScreen.main.bounds.width - 50) , height: 80)
                                       
                                    
                                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(scheme == .dark ? sortedPayments[i].by == info.userLog.id ? Color.blue : Color.white : sortedPayments[i].by == info.userLog.id ? Color.blue : Color.black, lineWidth: 1))
                                       .cornerRadius(15)
                                       .padding(.top,3)
                                       .padding(.bottom,3)
                                   
                                    } 
                                
                            }
                         
                                
                               
                                
                                
                            }.sheet(isPresented: $showPayment){PaymentView(paymentID: paymentID) .environmentObject(info)
                                .environmentObject(helper)}
                            
                            
                            
                
                        
                        
                        
                        
                    }
                 
                    .padding()
                   
                   
                    
                    
                    
                    
                }
                
                
            }
                
            }
        }
    }
}


