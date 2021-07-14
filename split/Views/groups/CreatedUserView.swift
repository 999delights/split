//
//  CreatedUserView.swift
//  split
//
//  Created by Andrei Giangu on 12.07.2021.
//

import SwiftUI

struct CreatedUserView: View {
    @State var spend = false
    @EnvironmentObject var info : AppDelegate
    @EnvironmentObject var helper: Helper
    @State var selectedTab: String = "stats"
    @State var groupID : String
    @State var userID : String
    @State var paymentID = ""
    @Namespace var animation
    @State var showPayment = false
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var scheme
    var columns = Array(repeating: GridItem(.flexible(),spacing: 20), count: 2)
    @State var isViewDisplayed = false
    var body: some View {
        
        
        ZStack{
            scheme == .dark ? Color.black.ignoresSafeArea() :  Color.white.ignoresSafeArea()
            
            VStack{
                if isViewDisplayed == true {
            HStack{
                let createdUsers = info.groups[helper.find(value: groupID, in: info.groups)!].createdUsers
                
                Text("\(Text("\(createdUsers[userID] ?? "")").foregroundColor(Color.purple))'s stas")
                    .font(.system(size:25))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    .padding()
                
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
                
             
                
      
                
                    
            HStack{
                
                let inf = helper.getOWEorOWEDperGroup(groupID: groupID, myID: userID, usersInGroup: info.groups[helper.find(value: groupID, in: info.groups) ?? 0])


                    


                    ForEach(inf.sorted(by: >), id: \.key) { key, value in


                      
                        if key != "we good" {
                        
                        Text("\(key)")
                            .font(.system(size:20))

                            .fontWeight(.bold)
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        }
                            
                       
                        


                        if value == "settled"{
                          



                                Text("\(value)")
                                    .font(.system(size:20))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)

                             


                        
                        }
                        
                        else {
                       



                            Text("\(value)")
                                .font(.system(size:20))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(key == "You owe" ? Color("red") : Color("Cgroup5") )

                          


                    

                        }
                            
                        
                    
                    }


                
               
                Spacer(minLength: 0)
            }
            .  padding(.horizontal)
            .padding(.top)
            .padding(.bottom,3)
                    
                    
                    
                    HStack{
                        
                        
                        Text("Spent")
                            .font(.system(size:20))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        
                        Text("\(helper.getTotalSpent(groupID: groupID, userID: userID, payments: info.paymentsInGroup))")
                            .font(.system(size:20))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor( Color("red") )



                        
                       
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal)
                    .padding(.bottom,3)
                    
            HStack{



                Button(action:{

                    withAnimation{

                        spend.toggle()
                        }

                },label:{
                    Text("Spend")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.vertical,10)
                        .frame(maxWidth: .infinity)
                        .background(
                        
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray)
                        )
                }

                ).disabled(info.usersInGroup.count < 2 && info.groups[helper.find(value:groupID, in: info.groups)!].createdUsers.count == 0)
                .opacity(info.usersInGroup.count < 2 && info.groups[helper.find(value:groupID, in: info.groups)!].createdUsers.count == 0 ? 0.6  : 1)


                .fullScreenCover(isPresented: $spend) {


                    getPaymentInfoCreatedUser(userID:userID, groupID: groupID).environmentObject(info)
                        .environmentObject(helper)
                }
                
                



            }.padding(.horizontal)
            
            
            
                CreatedUserStatsView(groupID: groupID, userID: userID)
            
            
                }
        }
            
        }.onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isViewDisplayed = true
            }
        }
        .onDisappear{
            isViewDisplayed = false
        }
    
    }

}
