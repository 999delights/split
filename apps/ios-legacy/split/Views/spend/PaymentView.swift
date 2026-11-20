//
//  PaymentView.swift
//  split
//
//  Created by Andrei Giangu on 16.06.2021.
//

import SwiftUI

struct PaymentView: View {
  
    @EnvironmentObject var info : AppDelegate
    @EnvironmentObject var helper: Helper
    @EnvironmentObject var loginData: LoginViewModel
    @EnvironmentObject var userData: UserViewModel
    @StateObject var payments = PaymentViewModel()
    @State var paymentID : String
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()
    @State var idGroup = ""
    var columns = Array(repeating: GridItem(.flexible(),spacing: 20), count: 2)
    @State var showView = false
    @State var showEdit = false
    @Namespace var animation
    @State var number : Double = 0
    @Environment(\.colorScheme) var scheme
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        
        
        ZStack(alignment:.top){
            
            scheme == .dark ? Color.black.ignoresSafeArea() :  Color.white.ignoresSafeArea()
            
          
            
            
            if showEdit == false {
            VStack{
                
                
                HStack{
                    
                    
                    Text("\(helper.getShortDate(date:info.payments[helper.indexPayment ?? 0].date))")
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        
                    
   
//                    Button(action: {
//
//                presentationMode.wrappedValue.dismiss()
//
//            }) {
//
//                Image(systemName: "arrow.left")
//
//                    .font(.system(size:22,weight: .semibold))
//                    .foregroundColor(.gray)
//
//                        .contentShape(Rectangle())
//                        .frame(width:35,height:35)
//                        .imageScale(.medium)
//            }

                    Spacer()
                    

                    Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }
                    ,label:{
                        Text("Cancel")
                            
                            
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        
                    })
                     
                        
                
            
                    
                  
                    
                  
                }.padding(.top)
                .padding(.leading)
                .padding(.trailing)
                
                HStack{
                    
                      Text("@\(info.groups[helper.find(value: info.payments[helper.indexPayment ?? 0].group, in: info.groups)!].name)")
                          .font(.system(size: 15, weight: .medium, design: .default))
                          .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    
                    Spacer()
                }.padding(.leading)
                .padding(.top,3)
                .padding(.bottom, info.payments[helper.indexPayment ?? 0].by == info.userLog.id ? 0 : 15)
                
                
                
                if info.payments[helper.indexPayment ?? 0].by == info.userLog.id {
                    
                    
                    if showEdit == false {
                    
                    
                    HStack{
                        
                        
                      
                                Button(action:{
                                    
                                    for(index, value) in info.usersInGroup.enumerated(){
                                        if(value.id == info.userLog.id){
                                            
                                           
                                            info.usersInGroup.rearrange(from: index, to: 0)
                                            
                                        }
                                    }
                                    payments.numberToggled = 0
                                    payments.payments.price = info.payments[helper.indexPayment ?? 0].price
                                    
                                    for(index,_) in info.usersInGroup.enumerated(){
                                        
                                        payments.payments.isToggled["\(info.usersInGroup[index].id)"] = false
                                        payments.payments.split["\(info.usersInGroup[index].id)"] = ""
                                        payments.changed["\(info.usersInGroup[index].id)"] = false
                                        
                                    }
                                    
                                    let createdUsers = info.groups[helper.find(value:idGroup, in:info.groups) ?? 0].createdUsers
                                    
                                    for (key,value) in createdUsers {
                                        payments.payments.isToggled["\(key)"] = false
                                        payments.payments.split["\(key)"] = ""
                                        payments.changed["\(key)"] = false
                                        
                                    }
                                    
                                    
                                        for(index,_) in info.usersInGroup.enumerated(){
                                        for (key,value) in info.payments[helper.indexPayment ?? 0].split{
                                            
                                            if key == info.usersInGroup[index].id  {
                                                
                                                if value != "" {
                                                    payments.payments.isToggled["\(info.usersInGroup[index].id)"] = true
                                                    payments.payments.split["\(info.usersInGroup[index].id)"] = value
                                                    payments.changed["\(info.usersInGroup[index].id)"] = false
                                                    payments.numberToggled += 1
                                                    payments.toggle1 = true
                                                    payments.payments.part.append(info.usersInGroup[index].id)
                                                }
                                                

                                            }
                                            
                                    
                                            
                                        }

                                    }
                                    
                                    for(key2,value2) in createdUsers{
                                    for (key,value) in info.payments[helper.indexPayment ?? 0].split{
                                        
                                        if key == key2  {
                                            
                                            if value != "" {
                                                payments.payments.isToggled["\(key2)"] = true
                                                payments.payments.split["\(key2)"] = value
                                                payments.changed["\(key2)"] = false
                                                payments.numberToggled += 1
                                                payments.toggle1 = true
                                                payments.payments.part.append(key2)
                                            }
                                            

                                        }
                                        
                                
                                        
                                    }

                                }
                                    
                                    
                                    if payments.numberToggled == info.usersInGroup.count + createdUsers.count {
                                        payments.toggleToti = true
                                    }
                                    
                                    showEdit = true
                                }, label:{
                                
                                    Text("\(Text("Edit"))")
                                       
                                        
                            }) .font(.system(size:13))
                                .foregroundColor(.red)
                    //            .background(spent.isEmpty || SecondView.g_participants.count < 3 || Int(spent) == 0 ? Color.white.opacity(0.16): Color.blue)
                                .padding(.vertical, 13)
                                .padding(.horizontal, 22)
                                .background( Color.red.opacity(0.3)
                                                .clipShape(Rectangle())
                                                    .cornerRadius(6))
                                .cornerRadius(9)
                                .buttonStyle(PlainButtonStyle())
                        
                        
                               
                        
                        Spacer()
                        
                      
                            
                
                      
                      
                        
                    }.padding(.leading)
                    .padding(.trailing)
                    .padding(.top,2)
                    .padding(.bottom,15)
                    
                    }
                    
                   
                    
                }
              
                
                HStack{
                    
                    
                    Spacer()

                       
                    Text("\(Image(systemName: "tag")) \(Text("\(info.payments[helper.indexPayment ?? 0].name)").font(.system(size:25))) ")
                        .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        .fontWeight(.heavy)
                        .lineLimit(1)
                        .truncationMode(.tail)

                        
                  
                    
                    Spacer()
          

                    
                    
                }.padding(.top,5)
                .padding(.leading)
                .padding(.trailing)
                

                HStack{
            
                    Spacer()
                    
                        Text("\(Image(systemName: "banknote")) \( Text("\(info.payments[helper.indexPayment ?? 0].price) ").font(.system(size:20))) ")
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                            .fontWeight(.heavy)
                            
                    Spacer()
                    
                }.padding(.leading)
                .padding(.top,5)
              
                
                HStack{
            
                    
                    ForEach(info.usersInGroup.indices, id:\.self) { i in
                    
        
                        if(info.usersInGroup[i].id == info.payments[helper.indexPayment ?? 0].by){
                            
                            if (info.usersInGroup[i].id != info.userLog.id){
                            
                            Text("by ")
                                .foregroundColor(.blue)
                                .fontWeight(.heavy)
                                
                        +
                          
                            Text("\(info.usersInGroup[i].nickname)")
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                            .fontWeight(.heavy)
    
                            }
                            
                            else {
                                Text("by ")
                                    .foregroundColor(.blue)
                                    .fontWeight(.heavy)
                                    
                            +
                              
                                Text("me")
                                .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                                .fontWeight(.heavy)
                                
                                
                            }
                            
                            
                        }
                        
                    

                        
                        
                    }
                    
                     let createdUsers = info.groups[helper.find(value:idGroup, in:info.groups) ?? 0].createdUsers
                    
                    ForEach(createdUsers.keys.sorted(), id:\.self){user in
                        if(user == info.payments[helper.indexPayment ?? 0].by){
                           
                            
                            Text("by ")
                                .foregroundColor(.blue)
                                .fontWeight(.heavy)
                                
                        +
                          
                            Text("\(createdUsers[user]!)")
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                            .fontWeight(.heavy)
    
                            
                            
                      
                            
                        }
                    }
                    
                    Spacer()
                    
                    if( showEdit == false){
                        Text("with \(helper.getNumberToggled(isToggled: info.payments[helper.indexPayment ?? 0].isToggled))")
                                      .font(.system(size: 15, weight: .medium, design: .default))
                                      .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    }
                    
                    if( showEdit == true){
                        Text("with \(payments.numberToggled)")
                                      .font(.system(size: 15, weight: .medium, design: .default))
                                      .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    }
                 
                    
                }.padding(.leading)
                .padding(.trailing)
                .padding(.top,5)

            VStack{
                
                
                if showEdit == false {
                
          ScrollView{
                        
                        
                        ForEach(info.payments[helper.indexPayment ?? 0].split.sorted(by:>), id: \.key){
                            key,value in
                            
                      
                            
                            
                            ForEach(info.usersInGroup.indices, id:\.self) { i in
                                
                                if(key == info.usersInGroup[i].id) {
                                    if(value != "") {
                                        
                                        VStack{
                                            
                                            HStack{
                                                
                                                profilePicUSERS(image: info.usersInGroup[i].profilePic, name: info.usersInGroup[i].nickname, r: 30)
                                                
                                                
                                                if(info.usersInGroup[i].id == info.userLog.id){
                                                    
                                                    Text("Me")
                                                        
                                                        
                                                        .foregroundColor(info.usersInGroup[i].id == info.payments[helper.indexPayment ?? 0].by ? Color.blue : scheme == .dark ?  Color.white : Color.black)
                                                        .fontWeight(.medium)
                                                }
                                                else {
                                                
                                                Text("\(info.usersInGroup[i].nickname)")
                                                    
                                                    
                                                    .foregroundColor(info.usersInGroup[i].id == info.payments[helper.indexPayment ?? 0].by ? Color.blue : scheme == .dark ?  Color.white : Color.black)
                                                    .fontWeight(.medium)
                                                }
                                                
                                                Spacer()
                                                
                                                
                                                Text("\(value)")
                                                   
                                                    .foregroundColor(info.usersInGroup[i].id == info.userLog.id ? Color.red.opacity(0.5) : info.userLog.id == info.payments[helper.indexPayment ?? 0].by ?  Color.green : scheme == .dark ?  Color.white : Color.black )
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
                            let createdUsers = info.groups[helper.find(value:idGroup, in:info.groups) ?? 0].createdUsers
                            ForEach(createdUsers.keys.sorted(), id:\.self) { user in
                                
                                if(key == user) {
                                    if(value != "") {
                                        
                                        VStack{
                                            
                                            HStack{
                                                
                                                profilePicUSERS(image: "", name: createdUsers[user]!, r: 30)
                                                
                                                
                                               
                                                
                                                Text("\(createdUsers[user]!)")
                                                    
                                                    
                                                    .foregroundColor(user == info.payments[helper.indexPayment ?? 0].by ? Color.blue : scheme == .dark ?  Color.white : Color.black)
                                                    .fontWeight(.medium)
                                                
                                                
                                                Spacer()
                                                
                                                
                                                Text("\(value)")
                                                   
                                                    .foregroundColor(user == info.userLog.id ? Color.red.opacity(0.5) : info.userLog.id == info.payments[helper.indexPayment ?? 0].by ?  Color.green : scheme == .dark ?  Color.white : Color.black )
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
                  
            
            if(info.userLog.id == info.payments[helper.indexPayment ?? 0].by)
            {
            HStack{
                
             
                
               
               
                
                Rectangle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(height:0.5)
                    
                    Text("\(helper.totalGivePerPayment(payments: info.payments, userID: info.userLog.id, paymentID: paymentID))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.trailing,20)
                
            }.padding()
                
            }
          }.padding(.top)

                    
                
                }
                
                
                
                }
            
                
        
    }.navigationBarHidden(true)
      
        .onAppear{
            
            
          
            indexCalcandfetch(completionHandler: show)
            
                
        
            

        }
            
            }
           
        
            if showEdit == true {
                
                VStack{
                    
                    
                    HStack{
                        
                        
                     
                        
                        
                        

                        
                        Button(action: {
                         showEdit = false
                            }
                        ,label:{
                            Text("Back  ")
                               
                                .padding()
                                .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        })
                            
                        
                        
                        Spacer()
                        
                    
                        Text("\(info.payments[helper.indexPayment ?? 0].name)")
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                            .fontWeight(.heavy)
                        
                        

                            
                        
                        
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
                }
                .transition(.asymmetric(insertion: .move(edge:.top), removal: AnyTransition.opacity.animation(.easeInOut)))
                .ignoresSafeArea(.keyboard)
                .onTapGesture {
                        self.endTextEditing()
                    }
                
                VStack{
                    VStack{
                        
                       
                        
                        HStack{}.padding(.bottom,30).padding(.top,15)
                        
                        Spacer()
                        HStack{

                            Text("Splitting \(Text("\(payments.payments.price)").foregroundColor(Color.purple))\nwith")
                            .font(.system(size:25))
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                            .fontWeight(.heavy)
                            .padding(.leading,15)
                            .padding(.top,15)
                            
                            Spacer()
                            
                            
                            Toggle("",isOn: $payments.toggleToti).onChange(of:payments.toggleToti){
                                newValue in
                                
                                
                                for (k,_) in payments.changed {
                                    payments.changed[k] = false
                                }
                                
                                
                                
                                
                                if(!payments.toggleToti){
                                    
                             
                                
                                    var count: Int = 0
                                    for(key,_) in payments.payments.isToggled{
                                      if(payments.payments.isToggled[key] == true)
                                      {
                                        count += 1
                                      }
                                    }
                                        if(count == payments.payments.isToggled.count)
                                        {
                                            for(key,_) in payments.payments.isToggled{
                                                payments.payments.isToggled[key] = false
                                            }
                                                for(key2,_) in payments.payments.split{
                                                    
                                                        payments.payments.split[key2] = ""
                                                   
                                                    
                                                }
                                           
                                            
                                            payments.numberToggled = 0
                                            payments.toggle1 = false
                                        }
                                       
                                
                                    
                                    
                                    
                                    
                                }
                                
                                if payments.toggleToti == true {
                                    
                                    payments.toggle1 = true
                                    for(key,_) in payments.payments.isToggled{
                                        payments.payments.isToggled[key] = true
                                        payments.numberToggled = payments.payments.isToggled.count
                                    }
                                       
                                            for (key2,_) in payments.payments.split {
                                                
                                                    payments.payments.split[key2] = String(Double( Double(payments.payments.price)!  / Double(payments.numberToggled)).clean)
                                                                         
                                                
                                            }
                                        
                                        
                                    
                                }
                            }.padding()
                            
                        }
                        ScrollView(showsIndicators: false){
                          
                            VStack{
                                
                                LazyVGrid(columns: columns,spacing: 20){
                                    
                                  
                                    
                                    
                                    ForEach(info.usersInGroup.indices, id:\.self){i in
                                     
                                        ZStack{
                                            
                                            
                                            VStack{
                                                Spacer()
                                                
                                                
                                                
                                            HStack{
                                                Spacer()
                                                
                                                Text(".")
                                                    .fontWeight(.semibold)
                                                    .font(.system(size:30))
                                                    .foregroundColor(payments.changed[info.usersInGroup[i].id] == true ?  .red : .gray)
                                                    .padding(.trailing)
                                                    
                                            }.padding(.bottom,25)
                                                
                                             
                                            }
                                         
                                        VStack{
                                   
                                        
                                         
                                            
                                            
                                            profilePicToggled(name: info.usersInGroup[i].nickname, r: 65, r2: 25, image: info.usersInGroup[i].profilePic, action: $payments.payments.isToggled["\(info.usersInGroup[i].id)"], number: $payments.numberToggled,users: $payments.payments.isToggled, toggle1: $payments.toggle1, toggleToti: $payments.toggleToti, split:$payments.payments.split, price: $payments.payments.price, changed: $payments.changed )
                                                .disabled(keyboardHeightHelper.keyboardHeight == true)
                                            
                                            if(info.usersInGroup[i].id == info.userLog.id){
                                                
                                                Text("Me").font(.system(size:18)).foregroundColor(scheme == .dark ?  Color.white : Color.black).fontWeight(.medium)
                                         
                                            }
                                            
                                            else {
                                                Text("\(info.usersInGroup[i].nickname)").font(.system(size:18)).foregroundColor(scheme == .dark ?  Color.white : Color.black).fontWeight(.medium)
                                            }
                                     
                                            
                                          
                                            
                                  
                                         
                                            
                                            TextField("0", text: $payments.payments.split["\(info.usersInGroup[i].id)"].bound , onEditingChanged:{value in
                                                
                                                payments.changed["\(info.usersInGroup[i].id)"] = true
                                                
                                                payments.payments.split["\(info.usersInGroup[i].id)"] = String(Double(payments.payments.split["\(info.usersInGroup[i].id)"].bound.doubleValue).clean )
                                     
                                                
                                                
                                                for (key,_) in payments.payments.split {
                                                    if key != info.usersInGroup[i].id
                                                    {
                                                        if payments.payments.split[key] != ""{
                                                            if payments.changed[key] != true {
                                                            
                                                                var number : Double = 0
                                                                var nr : Double = 0
                                                                for (k,_) in payments.changed{
                                                                    
                                                                    
                                                                    if(payments.changed[k] == true ){
                                                                        number += Double(payments.payments.split[k].bound) ?? 0
                                                                        nr += 1
                                                                    }
                                                                }
                                                        
                                                            if(number != 0){
                                                        payments.payments.split[key] = String(
                                                                                              ((Double(payments.payments.price)! - number) / (Double(payments.numberToggled) - Double(nr))).clean)
                                                            
                                                            }
                                                                
                                                                
                                                            
                                                            
                                                            
                                                            if(number == 0){
                                                        payments.payments.split[key] = String(
                                                                                              ((Double(payments.payments.price)! - number) / (Double(payments.numberToggled) - Double(nr))).clean)
                                                            
                                                                payments.payments.split["\(info.usersInGroup[i].id)"] = "0"
                                                            }
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                
                                                for (k,v) in payments.payments.split{
                                                    if Double(v) == 0 {
                                                        
                                                        payments.payments.isToggled[k] = false
                                                        payments.payments.split[k] = ""
                                                    }
                                                }
                                                for (k,v) in payments.payments.split{
                                                    if Double(v) ?? 0 < 0 {
                                                        
                                                        payments.payments.isToggled[k] = false
                                                        payments.payments.split[k] = ""
                                                    }
                                                }
                                                
                                                
                                   
                                                
                                            
                                            } )
                                                .multilineTextAlignment(.center)
                                                .keyboardType(.decimalPad)
                                                .font(.system(size: 17, weight: .heavy, design: .default))
                                                .foregroundColor(.purple)
                                                .offset(y:+5)
                                                .disabled(payments.payments.isToggled["\(info.usersInGroup[i].id)"] != true)
                                                .onChange(of: payments.payments.split["\(info.usersInGroup[i].id)"], perform: {value in
                                                    
                                                 
                                                    number = 0
                                                  
                                                    for (key,_) in payments.payments.split {
                                                        if key != info.usersInGroup[i].id
                                                        {
                                                            if payments.payments.split[key] != ""{
                                                                if payments.changed[key] == true {
                                                                    
                                                                    
                                                                    number += Double(payments.payments.split[key]!) ?? 0
                                                            }
                                                          }
                                                        }
                                                    
                                                
                                                        
                                            }
                                                    if Double(value.bound) ?? 0 > (Double(payments.payments.price)! - Double(number)){
                                                        
                                                        payments.payments.split["\(info.usersInGroup[i].id)"] = String(Double(Double(payments.payments.price)! - Double(number)).clean)
                                                    }
                                                        
                                                        
                                                        
                                                    
                                           
                                                        
                                                    
                                           
                                                    
                                          
                                                    
                                                
                                                })
                                            Divider()
                                                .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                                            .padding(.leading,40)
                                                .padding(.trailing,40)
                                          
                                        }
                                        
                                        .aspectRatio(contentMode: .fill)
                                        
                                        .frame(width: (UIScreen.main.bounds.width - 50) / 2, height: 180)
                                        
                                        .overlay(
                                                   RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                               )
                                        .background(payments.payments.isToggled["\(info.usersInGroup[i].id)"] != true ? Color.white.opacity(0.15) : Color.blue.opacity(0.15))
                                        .cornerRadius(15)
                                        
                                        }
                                        
                                    }
                                    
                                    let createdUsers = info.groups[helper.find(value:idGroup, in: info.groups) ?? 0].createdUsers
                                    
                                    ForEach(createdUsers.keys.sorted(), id:\.self){id in
                                     
                                        ZStack{
                                            
                                            
                                            VStack{
                                                Spacer()
                                                
                                                
                                                
                                            HStack{
                                                Spacer()
                                                
                                                Text(".")
                                                    .fontWeight(.semibold)
                                                    .font(.system(size:30))
                                                    .foregroundColor(payments.changed[id] == true ?  .red : .gray)
                                                    .padding(.trailing)
                                                    
                                            }.padding(.bottom,25)
                                                
                                             
                                            }
                                         
                                        VStack{
                                   
                                        
                                         
                                            
                                            
                                            profilePicToggled(name: createdUsers[id]!, r: 65, r2: 25, image: "", action: $payments.payments.isToggled["\(id)"], number: $payments.numberToggled,users: $payments.payments.isToggled, toggle1: $payments.toggle1, toggleToti: $payments.toggleToti, split:$payments.payments.split, price: $payments.payments.price, changed: $payments.changed )
                                                .disabled(keyboardHeightHelper.keyboardHeight == true)
                                            
                                        
                                            
                                         
                                                Text("\(createdUsers[id]!)").font(.system(size:18)).foregroundColor(scheme == .dark ?  Color.white : Color.black).fontWeight(.medium)
                                          
                                     
                                            
                                          
                                            
                                  
                                         
                                            
                                            TextField("0", text: $payments.payments.split["\(id)"].bound , onEditingChanged:{value in
                                                
                                                payments.changed["\(id)"] = true
                                                
                                                payments.payments.split["\(id)"] = String(Double(payments.payments.split["\(id)"].bound.doubleValue).clean )
                                     
                                                
                                                
                                                for (key,_) in payments.payments.split {
                                                    if key != id
                                                    {
                                                        if payments.payments.split[key] != ""{
                                                            if payments.changed[key] != true {
                                                            
                                                                var number : Double = 0
                                                                var nr : Double = 0
                                                                for (k,_) in payments.changed{
                                                                    
                                                                    
                                                                    if(payments.changed[k] == true ){
                                                                        number += Double(payments.payments.split[k].bound) ?? 0
                                                                        nr += 1
                                                                    }
                                                                }
                                                        
                                                            if(number != 0){
                                                        payments.payments.split[key] = String(
                                                                                              ((Double(payments.payments.price)! - number) / (Double(payments.numberToggled) - Double(nr))).clean)
                                                            
                                                            }
                                                                
                                                                
                                                            
                                                            
                                                            
                                                            if(number == 0){
                                                        payments.payments.split[key] = String(
                                                                                              ((Double(payments.payments.price)! - number) / (Double(payments.numberToggled) - Double(nr))).clean)
                                                            
                                                                payments.payments.split["\(id)"] = "0"
                                                            }
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                
                                                for (k,v) in payments.payments.split{
                                                    if Double(v) == 0 {
                                                        
                                                        payments.payments.isToggled[k] = false
                                                        payments.payments.split[k] = ""
                                                    }
                                                }
                                                for (k,v) in payments.payments.split{
                                                    if Double(v) ?? 0 < 0 {
                                                        
                                                        payments.payments.isToggled[k] = false
                                                        payments.payments.split[k] = ""
                                                    }
                                                }
                                                
                                                
                                   
                                                
                                            
                                            } )
                                                .multilineTextAlignment(.center)
                                                .keyboardType(.decimalPad)
                                                .font(.system(size: 17, weight: .heavy, design: .default))
                                                .foregroundColor(.purple)
                                                .offset(y:+5)
                                                .disabled(payments.payments.isToggled["\(id)"] != true)
                                                .onChange(of: payments.payments.split["\(id)"], perform: {value in
                                                    
                                                 
                                                    number = 0
                                                  
                                                    for (key,_) in payments.payments.split {
                                                        if key != id
                                                        {
                                                            if payments.payments.split[key] != ""{
                                                                if payments.changed[key] == true {
                                                                    
                                                                    
                                                                    number += Double(payments.payments.split[key]!) ?? 0
                                                            }
                                                          }
                                                        }
                                                    
                                                
                                                        
                                            }
                                                    if Double(value.bound) ?? 0 > (Double(payments.payments.price)! - Double(number)){
                                                        
                                                        payments.payments.split["\(id)"] = String(Double(Double(payments.payments.price)! - Double(number)).clean)
                                                    }
                                                        
                                                        
                                                        
                                                    
                                           
                                                        
                                                    
                                           
                                                    
                                          
                                                    
                                                
                                                })
                                            Divider()
                                                .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                                            .padding(.leading,40)
                                                .padding(.trailing,40)
                                          
                                        }
                                        
                                        .aspectRatio(contentMode: .fill)
                                        
                                        .frame(width: (UIScreen.main.bounds.width - 50) / 2, height: 180)
                                        
                                        .overlay(
                                                   RoundedRectangle(cornerRadius: 15)
                                                    .stroke(Color.purple.opacity(0.4), lineWidth: 2)
                                               )
                                        .background(payments.payments.isToggled["\(id)"] != true ? Color.white.opacity(0.15) : Color.blue.opacity(0.15))
                                        .cornerRadius(15)
                                        
                                        }
                                        
                                    }
                                    
                                }.padding()
                                
                                
                               
                                
                                
                            }
                        
                            
                        }
                        .padding(.bottom)
                        .keyboardAware()
                        
                        Button(action:{
                            payments.payments.part.removeAll()
                            for (key,value) in payments.payments.isToggled{
                                if (value == true) {
                                    
                                    payments.payments.part.append(key)
                                }
                                
                            }
                            payments.updatePayment(paymentID: info.payments[helper.indexPayment ?? 0].id, group: info.groups[helper.find(value: info.payments[helper.indexPayment ?? 0].group, in: info.groups)!].id)
                            showEdit = false
                            
                       
                            debtPerPersonXperson()
                            
                            
                            
                            
                        }, label:{
                            
                         
                                
                                Text("Confirm")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.vertical,15)
                                    .frame(maxWidth:.infinity)
                                    .background(Color.green)
                                    .cornerRadius(12)
                                    .padding(.leading,20)
                                    .padding(.trailing,20)
                                
                            
                      
                            
                        }).disabled(payments.toggle1 == false)
                        .opacity((payments.toggle1 == false) ? 0.6  : 1)
                        .disabled(helper.getSplitSum(split: payments.payments.split) < (Double(payments.payments.price)! - Double(0.5)) )
                        .opacity(helper.getSplitSum(split: payments.payments.split) < (Double(payments.payments.price)! - Double(0.5)) ? 0.6  : 1)
                        .disabled(helper.getSplitSum(split: payments.payments.split) > (Double(payments.payments.price)!) + Double(0.5) )
                        .opacity(helper.getSplitSum(split: payments.payments.split) > (Double(payments.payments.price)! + Double(0.5) ) ? 0.6  : 1)
                        
                       
                        
                        
                    }
                    
                    
                .onTapGesture {
                        self.endTextEditing()
                    }
                    
                }.ignoresSafeArea(.keyboard, edges: .bottom)
                
            }
        
    }
       

    }
    func indexCalcandfetch(completionHandler: () -> Void) {
        
    
        idGroup = info.groups[helper.find(value: info.payments[helper.indexPayment ?? 0].group, in: info.groups)!].id
        info.fetchUsers(groupID: idGroup)
        completionHandler()
        
        
    }
    
    func show(){
        helper.showPayment = true
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


