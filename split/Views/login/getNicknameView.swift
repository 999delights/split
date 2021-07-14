//
//  getNicknameView.swift
//  split
//
//  Created by Andrei Giangu on 24.05.2021.
//

import SwiftUI

struct getNicknameView: View {
    @EnvironmentObject var loginData : LoginViewModel
    @EnvironmentObject var info: AppDelegate
    @EnvironmentObject var userData : UserViewModel
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()
    
    
    var body: some View {
        
        ZStack{
            
            VStack{
                
                
        HStack{
            
            
          
            
         
        Text("just one more thing.")
            .font(.system(size:25))
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.gray)
            .padding(.top,10)
            .padding(.bottom,20)
            
        }.padding(.top,50)
                
             
        HStack{}.padding()
       
                
                VStack{
                    
                    Text("What should your nickname be?")
                        .foregroundColor(.gray)
                        .padding(.bottom)
                    
                    TextField("", text: $userData.user.nickname).padding(.top,10)
                        .keyboardType(.default)
                        .autocapitalization(.none)

                        .disableAutocorrection(true)
                        
                        .padding(.bottom,4)
                        .frame(height:35)
                        .border(Color(UIColor.separator))

                        .lineSpacing(15.0)
                        .foregroundColor(.gray)
                        .background(Color.white)
                        .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                        .cornerRadius(7)
                        .multilineTextAlignment(.center)
                        .padding(.top,15)
                        .padding(.leading,60)
                        .padding(.trailing,60)
                        .padding(.bottom,20)
                        .onChange(of: self.userData.user.nickname){ value in
                        if (userData.user.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
                            userData.user.nickname = userData.user.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                        }}
                        .introspectTextField { textField in
                            textField.becomeFirstResponder()
                 
                        }
              
                        
                    
                    
                    Divider().padding()
                    Button(action:{
                     
                        
                        userData.save()
                        
                    },label:{
                        
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical,10)
                            .frame(maxWidth:.infinity)
                            .background(Color.green)
                            .cornerRadius(8)
                            .padding(.leading,20)
                            .padding(.trailing,20)
                            .padding(.top,20)
                            
                    }).disabled(userData.user.nickname == "")
                    .opacity((userData.user.nickname == "") ? 0.6  : 1)
                    
                    
                  
                
                    
                }
                .padding()
                
                
                
                Spacer()
                
                
            }
     
            
      
       
        
            
       
        
        }.background(Color.white.opacity(0.04).ignoresSafeArea())
        
       
      
        
        
    }
}

struct getNicknameView_Previews: PreviewProvider {
    static var previews: some View {
        getNicknameView().environmentObject(UserViewModel())
    }
}
