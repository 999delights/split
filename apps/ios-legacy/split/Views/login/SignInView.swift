//
//  SignInView.swift
//  split
//
//  Created by Andrei Giangu on 23.05.2021.
//

import SwiftUI
import Firebase

struct SignInView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var loginData: LoginViewModel
    @EnvironmentObject var userData: UserViewModel
    @EnvironmentObject var info : AppDelegate
//    @EnvironmentObject var fetchedUser: FetchedUserModel
    var body: some View {
        
        ZStack(alignment:.topLeading){
            
        VStack{
            HStack(spacing:10){
                Button(action: {

            presentationMode.wrappedValue.dismiss()
                    loginData.email = ""
                    loginData.password = ""
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
//
//        Text("split paper")
//            .font(.largeTitle)
//            .fontWeight(.heavy)
//            .foregroundColor(.gray)
//            .padding(.bottom,10)
        
        Text("Welcome back.")
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.gray)
            .padding(.bottom,10)
            
            
            
            CustomTextField(value: $loginData.email, hint: "User Name")
            
            CustomTextField(value: $loginData.password, hint: "Password")
            
            
            HStack{
          Spacer()
                
                Button(action: loginData.resetPassword
                ,label: {
                    
                    Text("Forget password")
                        .fontWeight(.medium)
                        .foregroundColor(Color.gray.opacity(0.8))
                })
                .disabled(loginData.email == "" )
                .opacity(loginData.email == "" ? 0.8 : 1)
                
                
            }.padding(.trailing,20)
            .padding(.top,5)
            
            
            Button(action:loginUser, label:{
                Text("Log in")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical,10)
                    .frame(maxWidth:.infinity)
                    .background(Color.green)
                    .cornerRadius(8)
                    .padding(.leading,20)
                    .padding(.trailing,20)
                
            }).padding(.top)
            .disabled(loginData.email == "" || loginData.password == "" )
            .opacity((loginData.email == "" || loginData.password == "") ? 0.6  : 1)
            
            ZStack{

            }.frame(maxHeight:.infinity)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        
        }.overlay(ZStack{if loginData.isLoading{LoadingScreenView()}})
        .alert(isPresented: $loginData.error, content: {
            Alert(title: Text("message"), message: Text(loginData.errorMsg), dismissButton: .destructive(Text("ok"),action:{
                withAnimation{loginData.isLoading = false}
            }))
        })
    }
    
    
    func loginUser(){
        
        //Loading Screen..
        
        withAnimation{loginData.isLoading = true }
        
        //loggin in user
        
        Auth.auth().signIn(withEmail: loginData.email, password: loginData.password) { [self] (result,err) in
            
            if let error = err {
                loginData.errorMsg = error.localizedDescription
                loginData.error.toggle()
                return
                
            }
            
            
            guard let _ = result else{
                loginData.errorMsg = "Please try again later"
                loginData.error.toggle()
                return
                
            }
            
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            info.fetchData()
            
            dispatchGroup.leave()
            
            dispatchGroup.notify(queue:.main){
                
                print("success")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                withAnimation{loginData.status = true}
                withAnimation{loginData.isLoading = false }
                }
            }
         
        }
    }

        
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView().environmentObject(LoginViewModel())
    }
}



