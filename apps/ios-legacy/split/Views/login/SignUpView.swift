//
//  SignUpView.swift
//  split
//
//  Created by Andrei Giangu on 23.05.2021.
//

import SwiftUI
import Firebase

struct SignUpView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var loginData: LoginViewModel
    @EnvironmentObject var userData: UserViewModel
 
    var body: some View {
        
        ZStack(alignment:.topLeading){
        VStack{
            
            HStack(spacing:10){
                Button(action: {

            presentationMode.wrappedValue.dismiss()
                    loginData.newEmail = ""
                    loginData.registerPassword = ""
                    loginData.reEnterPassword = ""
        }) {

            Image(systemName: "arrow.left")
              
                .font(.system(size:22,weight: .semibold))
                .foregroundColor(.gray)
                .contentShape(Rectangle())
                .frame(width:35,height:35)
                .imageScale(.medium)
        }

        Spacer()
            }
            .padding()
            .padding(.top,getSafeArea().top)
//
//        Text("split paper")
//            .font(.largeTitle)
//            .fontWeight(.heavy)
//            .foregroundColor(.gray)
//            .padding(.bottom,10)
        
        Text("Welcome.")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.gray)
            .padding(.bottom,10)
            
            
            
            CustomTextField(value: $loginData.newEmail, hint: "User Name")
            
            CustomTextField(value: $loginData.registerPassword, hint: "Password")
            
            CustomTextField(value: $loginData.reEnterPassword, hint: "Re-Enter Password")
            
             
            Button(action:registerUser, label:{
                Text("Create account")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical,10)
                    .frame(maxWidth:.infinity)
                    .background(Color.green)
                    .cornerRadius(8)
                    .padding(.leading,20)
                    .padding(.trailing,20)
                
            }).padding(.top)
            .disabled(loginData.newEmail == "" || loginData.registerPassword == "" || loginData.reEnterPassword == "" )
            .opacity((loginData.newEmail == "" || loginData.registerPassword == "" || loginData.reEnterPassword == "" ) ? 0.6 : 1)
            
            Spacer()
       
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()

        
       
        } .overlay(ZStack{if loginData.isLoading{LoadingScreenView()}})
        .alert(isPresented: $loginData.error, content: {
            Alert(title: Text("message"), message: Text(loginData.errorMsg), dismissButton: .destructive(Text("ok"),action:{
                withAnimation{loginData.isLoading = false
                    
                    if(loginData.errorMsg == "Account Created Succesfully"){
                        
                        loginData.status = true
                        
                        
                        
                    }
                   
                }
            }))
        })
    }
    
    
    func registerUser(){
      
        if loginData.reEnterPassword == loginData.registerPassword {
            
            withAnimation{loginData.isLoading = true}
            Auth.auth().createUser(withEmail: loginData.newEmail, password: loginData.reEnterPassword) { [self](result,err) in
                
                if let error = err {
                    loginData.errorMsg = error.localizedDescription
                    loginData.error.toggle()
                    return
                }
                
                guard let _ = result else {
                    loginData.errorMsg = "Please try again later"
                    loginData.error.toggle()
                return
                }
                
                print("success")
                
                userData.saveNewUser(email: loginData.newEmail)
               
                loginData.errorMsg = "Account Created Succesfully"
                loginData.error.toggle()
           
               
                
            }
        }
        else {
            loginData.errorMsg = "Password missmatch"
            loginData.error.toggle()
        }
    }
        
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView().environmentObject(LoginViewModel())
    }
}




