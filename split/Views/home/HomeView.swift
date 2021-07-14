//
//  HomeView.swift
//  split
//
//  Created by Andrei Giangu on 23.05.2021.
//

import SwiftUI
import Firebase
import GoogleSignIn
import FirebaseStorage
import UIKit
import Introspect

struct HomeView: View {
    @EnvironmentObject var loginData : LoginViewModel
    @EnvironmentObject var helper : Helper
    @AppStorage("log_Status") var status = false
    @EnvironmentObject var info: AppDelegate
    @EnvironmentObject var userData: UserViewModel
    @State var groupID = ""
    @State var settings = false
    @Environment(\.colorScheme) var scheme
    @State private var isActive : Bool = false
    @State var createGroup = false
    @State var titleBarHeight: CGFloat = 0


    var columns = Array(repeating: GridItem(.flexible(),spacing:20), count:2)
    
    
  
    
    
   
    
    var body: some View {
      
        
        NavigationView{
            
                
     
        
            
        ZStack(alignment:.top){
           
            
            
            VStack{
                
                
            HStack{
            
              
                
                NavigationLink(
                    destination: GroupView( groupID: groupID)

                        .environmentObject(userData)
                        .environmentObject(loginData)
                        .environmentObject(info)
                       .environmentObject(helper),
                    isActive: self.$isActive){
                 
                   
                    
                    
                }
                .isDetailLink(false)
        
      
                NavigationLink(destination: EmptyView()) {
                    EmptyView()
                }
            
                
              
                NavigationLink(
                    destination: SettingsView().environmentObject(userData)
                        .environmentObject(loginData)
                        .environmentObject(info),
                    isActive: $settings){
                    profilePicUSER(image: info.userLog.profilePic, name: info.userLog.nickname, r: 35, action: $settings)
                }
            
               
                
                
                
                Spacer()
                Button(action:{
                    createGroup = true
                    
                },label:{
                    
                    
                   Image(systemName: "plus")
                    .font(.title)
                    .contentShape(Rectangle())
                    .frame(width:35,height:35)
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    
                }).sheet(isPresented: $createGroup) {
                    split.create().environmentObject(helper)  }
                .disabled(info.groups.count == 0)
                .opacity(info.groups.count == 0 ? 0 : 1)
            }
            .padding()
            
                
                    VStack{
                    
                        let inf = helper.getOWEorOWED(groups: info.groups, myID: info.userLog.id, users: info.users)
                        ForEach(inf.sorted(by: >), id: \.key) { key, value in
                        
                        HStack{
                            
                        Text("\(key)")
                            .font(.system(size:20))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                            .opacity(key == "we good" ? 0 : 1)

                        Spacer()
                        }

                        HStack{
                            Text("\(value)")
                                .font(.system(size:20))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(scheme == .dark ?  Color.white : Color.black)

                            Spacer()

                          
                    }
                        }
                    
                }
                    .padding(.leading)
                
                
            
            }
            .zIndex(1)
            .padding(.bottom,15)
            .background(
                    
                    
                BlurView().ignoresSafeArea()
                )
         
            .overlay(
            
                GeometryReader{reader -> Color in
                    
                    let height = reader.frame(in: .global).maxY
                    
                    DispatchQueue.main.async {
                        
                            titleBarHeight = height - (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
                        
                    }
                    
                    return Color.clear
                }
            )
            
            
            
            
          
            if info.groups.count != 0 {
        
            ScrollView(showsIndicators: false){
  
                VStack{

                    let sortedGroups = info.groups.sorted {
                    $0.date > $1.date
                }
                    
                    
                    HStack{
                        Spacer()
                        
                
                    }
                LazyVGrid(columns: columns,spacing: 20){

            

                    ForEach(sortedGroups, id:\.self){i in


                   
                        Button(action:{
                            groupID = i.id
                            isActive = true
                          
                            
                        },label:{
                            listGroupView(item:i)
                            
                        })
                            
                     
                            
                                
                                
                            
                            
                                
                        



                    }

                }

            



                }
                         
                .padding(.top,titleBarHeight)
                
            }
                
            .padding()
                
            }
            
            if info.groups.count == 0 {
                VStack{
                   Spacer()
                         VStack{
                         
                         ForEach(0...1,id: \.self){index in
                             if(index < 1){

                                 VStack{

                                 Button(action:{createGroup.toggle()}){

                                     plusButton(r:65)



                                 }.sheet(isPresented: $createGroup) {
                                     split.create().environmentObject(helper) }


                                    
                               }

                             }

                         }
                     }
                    Spacer()
                     
                 
                }
            }
            
        }
      
        .navigationBarHidden(true)
        .background(scheme == .dark ? Color.black.ignoresSafeArea(.all,edges:.all) : Color.white.ignoresSafeArea(.all,edges:.all) )
       
        .onChange(of: info.groups.count) { value in
            if(value != 0){
                    self.info.fetchAllUsers()
                self.info.fetchAllPayments()
                debtPerPersonXperson()
            }
        }
        .onAppear{
            
            
            func fetching(completionHandler: () -> Void) {
            
                self.info.fetchGroups()
           
           
            
            if info.dynamic != nil{
            if(status == true){
                
                info.handleIncomingDynamicLink(info.dynamic)
              }
            }
            
            self.info.fetchAllUsers()
            self.info.fetchAllPayments()
                completionHandler()
                
            }
            
          
           
            fetching(completionHandler: debtPerPersonXperson)
               
           
           
            
        }
       
        
        .onChange(of:info.payments.count){
            value in
            debtPerPersonXperson()
        }
        

      
        
        .onChange(of: info.dynamic){value in
            
            if info.dynamic != nil{
            if(status == true){
                
                info.handleIncomingDynamicLink(info.dynamic)
              }
            }
        }
        
      
        .ignoresSafeArea(.all,edges:.bottom)
     
            
        }   .navigationViewStyle(StackNavigationViewStyle())
        .environment(\.rootPresentationMode, self.$isActive)
         
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
    
    
 

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

