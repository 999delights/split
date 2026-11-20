//
//  GroupView.swift
//  split
//
//  Created by Andrei Giangu on 11.06.2021.
//

import SwiftUI
import Firebase
import FirebaseDynamicLinks
struct GroupView: View {
    
  
    @EnvironmentObject var info : AppDelegate
    @EnvironmentObject var helper: Helper

    @State var groupID : String
    @State var spend = false
    @State var isViewDisplayed = false
    @State var selectedTab: String = "stats"
    // For Segment Tab Slide....
    @State private var isActive : Bool = false
    @Namespace var animation
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @Environment(\.rootPresentationMode) private var rootPresentationMode: Binding<RootPresentationMode>
    @Environment(\.colorScheme) var scheme

    @State var showView = false
    var columns = Array(repeating: GridItem(.flexible(),spacing: 20), count: 2)
    @State var showPayment = false
    @State var paymentID = ""
    var body: some View {
  
        
            
            
            
        ZStack(alignment:.top){
            
            
            scheme == .dark ? Color.black.ignoresSafeArea() :  Color.white.ignoresSafeArea()
            
            
            VStack{
               
                HStack{
                  Button(action: {

                presentationMode.wrappedValue.dismiss()

            }) {

                Image(systemName: "chevron.left")
                  
                    .font(.system(size:25,weight: .light))
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    
                        .contentShape(Rectangle())
                        .frame(width:35,height:35)
                        .imageScale(.medium)
            }

               
                    
                
                        
                      
                   
                        
                    Text("\(Text("\(info.groups[helper.find(value: groupID, in: info.groups) ?? 0].name)").font(.system(size:25,weight:.semibold)))")
                    
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                   
                    
      
                    Spacer()
                    
                    NavigationLink(
                        destination: GroupSettings(groupID: groupID)
                            .environmentObject(info)
                            .environmentObject(helper)
                        ,isActive: $isActive){
                        
                      
                            
                            profilePicGROUPS(image: "\(info.groups[helper.find(value: groupID, in: info.groups) ?? 0].profilePic)", name: "\(info.groups[helper.find(value: groupID, in: info.groups) ?? 0].name)", r: 35,t:20, color:info.groups[helper.find(value: groupID, in: info.groups) ?? 0].color )
                        
                      
                    
                        
                    } .isDetailLink(false)
                    
                }.padding()
                .padding(.top,getSafeArea().top)
                
                HStack{
                    
                  


                        let inf = helper.getOWEorOWEDperGroup(groupID: groupID, myID: info.userLog.id, usersInGroup: info.groups[helper.find(value: groupID, in: info.groups) ?? 0])


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
                }   .padding(.horizontal)
                .padding(.top)
                .padding(.bottom,3)
                
                HStack{
                    
                    
                    Text("Spent")
                        .font(.system(size:20))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    
                    Text("\(helper.getTotalSpent(groupID: groupID, userID: info.userLog.id, payments: info.paymentsInGroup))")
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


                        getPaymentInfo(groupID: groupID).environmentObject(info)
                            .environmentObject(helper)
                    }



                }.padding(.horizontal)
                
                HStack(spacing: 0){
                    
                    TabBarButton(image: tabs2[0], animation: animation, selectedTab: $selectedTab)
                    
                    
                    TabBarButton(image: tabs2[1], animation: animation, selectedTab: $selectedTab)
                    
                    
                    
                }
                // Max Frame....
                // Conisered as padding....
                .frame(height: 70,alignment: .bottom)
                .background(scheme == .dark ? Color.black : Color.white)
               
              
        
                TabView(selection: $selectedTab) {
                    StatsView(groupID: groupID, isViewDisplayed: $isViewDisplayed)
                        .tag(tabs2[0])
                        .environmentObject(info)
                        .environmentObject(helper)
                    ActivityView2(groupID: groupID, paymentID: paymentID, showPayment: $showPayment, isViewDisplayed: $isViewDisplayed, spend: $spend)       .tag(tabs2[1])
                        .environmentObject(info)
                        .environmentObject(helper)
                   
                       
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                
         
                
             
                
            }
            .ignoresSafeArea()
            .background(scheme == .dark ? Color.black : Color.white)
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
           
          
            
            

          
            
            
            
       
        }
        .overlay(ZStack{if showView == false{LoadingScreenView()}})
        .onAppear {
                  self.isViewDisplayed = true
              }
              .onDisappear {
                  self.isViewDisplayed = false
              }
        .onAppear(perform:{
            
            
            
            fetch(completionHandler: completion)
            

            
            
        })

         
        
        
       
    }
    
    
    func fetch(completionHandler: () ->Void ) {
        
        if(groupID != ""){
            
        info.usersInGroup.removeAll()
        info.fetchUsers(groupID: groupID)
        info.fetchPayments(groupID: groupID)
       

      
        completionHandler()
        }
    }
    
    
    func completion(){
        showView = true
    }
    
    
    func debtPerPersonXperson() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
           
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
                for (i,value) in group.createdUsers{
                    for j in group.users{
                        if j != i {
                            for (k,v) in group.createdUsers {
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
                            for (k,v) in group.createdUsers {
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





var tabs2 = ["stats","activity"]
