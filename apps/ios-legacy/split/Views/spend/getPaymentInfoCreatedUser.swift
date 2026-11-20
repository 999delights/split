//
//  SpendView.swift
//  split
//
//  Created by Andrei Giangu on 26.05.2021.
//

import SwiftUI


struct getPaymentInfoCreatedUser: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State var double:Double = 0
    @State var page = ""
    @EnvironmentObject var helper : Helper
    @EnvironmentObject var info : AppDelegate
    @StateObject var payments = PaymentViewModel()
    var columns = Array(repeating: GridItem(.flexible(),spacing: 20), count: 2)
    @State var userID : String
    @State var split = ""
    @State var keys : [String] = []
    @State var values : [Bool] = []
    @State var groupID: String
    @State var number : Double = 0
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()
    @State var totalgive = ""
    @Environment(\.colorScheme) var scheme
    var body: some View {
        
        
            
        ZStack{
            

            scheme == .dark ? Color.black.ignoresSafeArea() :  Color.white.ignoresSafeArea()
            
            
            VStack{
                
                
                HStack{
                    
                    
                    
                    
                    if(page == "2" || page == "")
                    {
                    Button(action: {
                        page = "1"
                        
                        for (k,_) in payments.payments.isToggled{
                            payments.payments.isToggled[k] = false
                        }
                        
                        for(k,_) in payments.payments.split{
                            payments.payments.split[k] = ""
                        }
                        
                        for(k,_) in payments.changed{
                            payments.changed[k] = false
                        }
 
                        payments.toggleToti = false
                        
                        }
                    ,label:{
                        Text("Back  ")
                            .opacity(page == "2" ? 1 : 0)
                            
                            .padding()
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    }).disabled(page == "2" ? false : true)
                        
                    }
                    
                    if(page == "3")
                    {
                    Button(action: {
                        page = "2"
                        }
                    ,label:{
                        Text("Back  ")
                            .opacity(page == "3" ? 1 : 0)
                            .padding()
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    }).disabled(page == "3" ? false : true)
                        
                    }
                    
                    
                    
                    if(page == "1")
                    {
                    Button(action: {
                        page = ""
                        }
                    ,label:{
                        Text("Back  ")
                            .opacity(page == "1" ? 1 : 0)
                            .padding()
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    }).disabled(page == "1" ? false : true)
                        
                    }
                    
                    Spacer()
                    
                    if(page == "" || page == "1" || page == "2"){
                    Text("split bill")
                        .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        .fontWeight(.heavy)
                    }
                    
                    else{
                        Text("split review")
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                            .fontWeight(.heavy)
                        }
                        
                    
                    
                    Spacer()
                
                    
                    Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }
                    ,label:{
                        Text("Cancel")
                            
                            .padding()
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                            .opacity(page == "1" || page == "2" || page == "" || page == "3" ? 1 : 0)
                    }).disabled(page == "1" || page == "2" || page == "" || page == "3" ? false : true)
                        
                    
                    
                }
                
              
            Spacer()
            }.ignoresSafeArea(.keyboard)
            .onTapGesture {
                    self.endTextEditing()
                }
            
            
          
            VStack{
                
            if page == ""{
                
         
                
                VStack{
                    
                
                   
            
                Spacer()
             
                    
            HStack{
                
            Text("What is this for?")
                .font(.system(size:25))
                .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                .fontWeight(.heavy)
                .padding(.leading)
                .padding(.bottom,30)
         
                
                      Spacer()
            
            }
                
                    TextField("ex.'Groceries' ", text: $payments.payments.name).modifier(ClearButton(text: $payments.payments.name))
            .padding(.leading)
            .padding(.trailing)
            .keyboardType(.default)
            .font(.system(size: 25, weight: .medium, design: .default))
                        .onChange(of: self.payments.payments.name){ value in
                if (payments.payments.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
                    payments.payments.name = payments.payments.name.trimmingCharacters(in: .whitespacesAndNewlines)
                }}
            .foregroundColor(Color.purple)
            
                .introspectTextField { textField in
                    textField.becomeFirstResponder()
                    
                    
                }
        
            
            Divider()
                .padding(.horizontal)
                .padding(.bottom,10)
             
        
           Button(action:{page = "1"}, label:{
               Text("Continue")
                   .fontWeight(.semibold)
                   .foregroundColor(.white)
                   .padding(.vertical,15)
                   .frame(maxWidth:.infinity)
                   .background(Color.green)
                   .cornerRadius(12)
                   .padding(.leading,20)
                   .padding(.trailing,20)
                .keyboardAware()
           }).disabled(payments.payments.name == "" )
           .opacity((payments.payments.name == "") ? 0.6  : 1)
                  
                    
                   
                    
                    
                    
                
                }
            }
                
            if page == "1" {
                
                VStack{
                
                    
                    Spacer()
                    
                HStack{
  
                    Text("How much was\n\(Text("\(payments.payments.name.trimmingCharacters(in: .whitespacesAndNewlines))").foregroundColor(Color.purple))?")
                    .font(.system(size:25))
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    .fontWeight(.heavy)
                    .padding(.leading,10)
                        .padding(.bottom,30)
                    Spacer()
                    
                }
                   
                    HStack{
          
                        TextField("0", text: $payments.payments.price)
                            
                           .font(.system(size: 30, weight: .heavy, design: .default))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.purple)
                            .keyboardType(.decimalPad)
                                .introspectTextField { textField in
                                    textField.becomeFirstResponder()
                            
                                    
                                }
                            .padding(.bottom)
                        
//
//                  FirstResponderTextField2(text: $paymentPrice, placeholder: "0.00")
//                    .padding(.horizontal)
             
                    }
               
                    Button(action:{page = "2"
                        payments.payments.price = String((payments.payments.price.doubleValue).clean)
               }, label:{
                   Text("Continue")
                       .fontWeight(.semibold)
                       .foregroundColor(.white)
                       .padding(.vertical,15)
                       .frame(maxWidth:.infinity)
                       .background(Color.green)
                       .cornerRadius(12)
                       .padding(.leading,20)
                       .padding(.trailing,20)
                    .keyboardAware()
                    .onChange(of: payments.payments.price, perform: { value in
                       
                        
                        if Double(payments.payments.price) == 0 {
                            payments.payments.price = ""
                        }
                    })
                        
                    
               }).disabled(payments.payments.price == "" )
                    .opacity((payments.payments.price == "") ? 0.6  : 1)
                  
                }        .onAppear(perform: {
                 
                    
                    
                    for(index,_) in info.usersInGroup.enumerated(){
                       
                        payments.payments.isToggled["\(info.usersInGroup[index].id)"] = false
                        payments.payments.split["\(info.usersInGroup[index].id)"] = ""
                        payments.changed["\(info.usersInGroup[index].id)"] = false
                    }
                    
                    let createdUsers = info.groups[helper.find(value:groupID, in: info.groups) ?? 0].createdUsers
                    for(key,value) in createdUsers{
                       
                        payments.payments.isToggled["\(key)"] = false
                        payments.payments.split["\(key)"] = ""
                        payments.changed["\(key)"] = false
                    }
                    
                })
                
            }
            
            if page == "2" {
                
             
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
                                
                                
                                
                                let createdUsers = info.groups[helper.find(value:groupID, in: info.groups) ?? 0].createdUsers
                                
                                ForEach(createdUsers.keys.sorted(), id:\.self){id in
                                    if id == userID {
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
                                        
                                    
                                        
                                     
                                            Text("Me").font(.system(size:18)).foregroundColor(scheme == .dark ?  Color.white : Color.black).fontWeight(.medium)
                                      
                                 
                                        
                                      
                                        
                              
                                     
                                        
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
                                }
                                
                                ForEach(createdUsers.keys.sorted(), id:\.self){id in
                                 
                                    if id != userID {
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
                                }
                                
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
                                        
                                       
                                        
                                     
                                            Text("\(info.usersInGroup[i].nickname)").font(.system(size:18)).foregroundColor(scheme == .dark ?  Color.white : Color.black).fontWeight(.medium)
                                        
                                 
                                        
                                      
                                        
                              
                                     
                                        
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
                                
                               
                                
                                
                                
                            }.padding()
                            
                            
                           
                            
                            
                        }
                    
                        
                    }
                    .padding(.bottom)
                    .keyboardAware()
                    
                    Button(action:{ page = "3"
                        
                   
                        
                        
                        
                        
                    }, label:{
                        
                        if helper.getNumberToggled(isToggled: payments.payments.isToggled) == 0 {
                            
                            Text("Split with ")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.vertical,15)
                                .frame(maxWidth:.infinity)
                                .background(Color.green)
                                .cornerRadius(12)
                                .padding(.leading,20)
                                .padding(.trailing,20)
                            
                        }
                        else {
                        Text("Split with \(helper.getNumberToggled(isToggled: payments.payments.isToggled))")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical,15)
                            .frame(maxWidth:.infinity)
                            .background(Color.green)
                            .cornerRadius(12)
                            .padding(.leading,20)
                            .padding(.trailing,20)
                        }
                        
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
                
            
                
            }
           
            if page == "3" {
                
                VStack{
                    
                    
                    HStack{}.padding(.bottom,30).padding(.top,15)
                    
                
                    
                    HStack{
                        
                        Spacer()
                        

                
                     
                      
                        
                    }.padding(.trailing)
                    
                    HStack{

                           
                        Text("\(Image(systemName: "tag")) \(Text("\(payments.payments.name)").font(.system(size:20))) ")
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                            .fontWeight(.heavy)
                            .lineLimit(1)
                            .truncationMode(.tail)

                            
                      
                        
                        Spacer()
              

                        
                        
                    }.padding(.top,3)
                    .padding(.leading)
                    .padding(.trailing)
                    
                    
                    HStack{
                
          
                        Text("\(Image(systemName: "banknote")) \( Text("\(payments.payments.price) ").font(.system(size:20))) ")
                                .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                                .fontWeight(.heavy)
                                
                        Spacer()
                        
                    }.padding(.leading)
                     .padding(.top,5)
                  
      
                    
                    HStack{
                        
                            Text("@\(info.groups[helper.find(value: groupID, in: info.groups)!].name)")
                                .font(.system(size: 20, weight: .medium, design: .default))
                                .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        Spacer()
                
                     
                        Text("with \(helper.getNumberToggled(isToggled: payments.payments.isToggled)) ")
                            .font(.system(size:15))
                            .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                            .fontWeight(.medium)
                            .padding(.top,7)
                            
                        
                    }.padding(.trailing)
                    .padding(.leading)
                    .padding(.top,5)
                    .padding(.bottom)
                    
                    
                    ScrollView(showsIndicators:false){
                        
                        VStack{
                            


                            PaymentListCreatedUser(groupID: groupID,userID: userID)
                                .environmentObject(info)
                                .environmentObject(helper)
                                .environmentObject(payments)
                          
                            
                            
                        
                        }
                        
                        
                        HStack{
                            
                         
                            
                           
                           
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(height:0.5)
                                
                                Text("\(totalgive)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                    .padding(.trailing,20)
                            
                        }.padding()
                    }.padding(.bottom)
                    
                    
                    Button(action:{
                        
                        
                        for(k,v) in payments.payments.split {
                            
                            if(v != ""){
                              
                                payments.payments.split[k] = String(Double(v)!.clean2)
                                
                            }
                        }
                        
                        
                        
                        presentationMode.wrappedValue.dismiss()
                    
                        payments.createPayment(group:groupID,by:userID)
                        
                       
                    
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
                    })
                }.onAppear(perform: {
                    var sum: Double = 0
                    
                    for (key,value) in payments.payments.split {
                        if key != userID {
                            if(value != ""){
                                sum += Double(value)!
                                
                                   }
                                }
                            }
                    
                    totalgive = String(Double(sum).clean2)
                    
                    
                    payments.payments.part.removeAll()
                    for (key,value) in payments.payments.isToggled{
                        if (value == true) {
                            
                            payments.payments.part.append(key)
                        }
                        
                    }
                    
               
                    keys = payments.payments.isToggled.map{$0.key}
                    values = payments.payments.isToggled.map {$0.value}
                })
            }
                
                
            }.ignoresSafeArea(.keyboard, edges: .bottom)
    
              
          
            
        }
        
       
        
        
    }
   
  


}





