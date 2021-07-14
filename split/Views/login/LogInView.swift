//
//  LogInView.swift
//  split
//
//  Created by Andrei Giangu on 23.05.2021.
//

import SwiftUI
import GoogleSignIn
import AuthenticationServices

struct LogInView: View {
    
    @EnvironmentObject var loginData : LoginViewModel
    @EnvironmentObject var info: AppDelegate
//    @EnvironmentObject var fetchedUser : FetchedUserModel
    @EnvironmentObject var userData : UserViewModel
  
    
    var body: some View{
        
        
        NavigationView{
            
     
           
                
            
        VStack{
            
            Image("pic1")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal,10)
                .frame(alignment: .center)
            
            Text("split paper")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(.gray)
             
            
            
            Text("Split expenses with any group.")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.top,10)
                .padding(.bottom,35)
            
           
           
           
            
            // Login Buttons....
            
            
            if loginData.login == false {
            
                
               
                
            VStack(spacing: 15){
               
                SignInWithAppleButton(.signUp,onRequest:{(request) in
                    
                    info.nonce = randomNonceString()
                    request.requestedScopes = [.email,.fullName]
                    info.nonce = sha256(info.nonce)
                    
                },onCompletion: {
                    (result) in
                    
                    switch result{
                    case .success(let user):
                        print("success")
                        guard let credential = user.credential as? ASAuthorizationAppleIDCredential else{
                            print("error with firebase")
                            return
                        }
                        info.authenticate(credential: credential)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }).signInWithAppleButtonStyle(.black)
                .frame(height:50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
       
                
                
                

                Button(action: {
                    
                    // log in user
                    
                    GIDSignIn.sharedInstance()?.presentingViewController = UIApplication.shared.windows.first?.rootViewController
                    GIDSignIn.sharedInstance()?.signIn()
                    
                }, label: {
                    
                    HStack{
                        
                        Image("google")
                            // since were having images from assests...
                            // to maintain same size were using custom size rather then font...
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                        
                        Text("Sign up with Google")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical,13)
                    .padding(.horizontal)
                    .background(
                    
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay(
                            
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black,lineWidth: 1.5)
                            )
                    )
                })
                
                NavigationLink(
                    destination: SignUpView().environmentObject(loginData)
//                        .environmentObject(fetchedUser)
                        .environmentObject(info)
                        .environmentObject(userData),
                    isActive: $loginData.signupmail){
                    
                Button(action: {
                    
                    loginData.signupmail = true
                }, label: {
                    
                    HStack{
                        
                        Image("email")
                            // since were having images from assests...
                            // to maintain same size were using custom size rather then font...
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                        
                        Text("Sign up with Email    ")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical,13)
                    .padding(.horizontal)
                    .background(
                    
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay(
                            
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black,lineWidth: 1.5)
                            )
                    )
                })}
                
                HStack{
                    
                    Text("Already have an account?")
                        .foregroundColor(.black)
                    
                    Button(action: {
                        loginData.login.toggle()
                    }, label: {
                        Text("Sign in.")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .underline(true, color: Color.white)
                    })
                }
                .padding(.top,30)
            }
            .padding()
            }
            
            
           else {
            
           
            
            
            VStack(spacing: 15){
                
                    
                
                SignInWithAppleButton(.signIn,onRequest:{(request) in
                    
                    info.nonce = randomNonceString()
                    request.requestedScopes = [.email,.fullName]
                    info.nonce = sha256(info.nonce)
                    
                },onCompletion: {
                    (result) in
                    
                    switch result{
                    case .success(let user):
                        print("success")
                        guard let credential = user.credential as? ASAuthorizationAppleIDCredential else{
                            print("error with firebase")
                            return
                        }
                        info.authenticate(credential: credential)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }).signInWithAppleButtonStyle(.black)
                .frame(height:50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
             
                Button(action: {
                    
                    GIDSignIn.sharedInstance()?.presentingViewController = UIApplication.shared.windows.first?.rootViewController
                    GIDSignIn.sharedInstance()?.signIn()
                    
                }, label: {
                    
                    HStack{
                        
                        Image("google")
                            // since were having images from assests...
                            // to maintain same size were using custom size rather then font...
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                        
                        Text("Sign in with Google")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical,13)
                    .padding(.horizontal)
                    .background(
                    
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay(
                            
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black,lineWidth: 1.5)
                            )
                    )
                })
                
                
                NavigationLink(
                    destination: SignInView().environmentObject(loginData)
                        .environmentObject(info),
//                        .environmentObject(fetchedUser),
                    isActive: $loginData.signinmail){
                Button(action: {
                    
                    loginData.signinmail = true
                }, label: {
                    
                    HStack{
                        
                        Image("email")
                            // since were having images from assests...
                            // to maintain same size were using custom size rather then font...
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                        
                        Text("Sign in with Email    ")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.vertical,13)
                    .padding(.horizontal)
                    .background(
                    
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay(
                            
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black,lineWidth: 1.5)
                            )
                    )
                })}
                
                HStack{
                    
                    Text("Don't have an account?")
                        .foregroundColor(.black)
                    
                    Button(action: {
                        
                        loginData.login.toggle()
                    }, label: {
                        Text("Sign up.")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                            .underline(true, color: Color.white)
                    })
                }
                .padding(.top,30)
            }
            .padding()
            }
            
        }
  
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("bg").ignoresSafeArea())
        .ignoresSafeArea()
        .overlay(ZStack{if info.isLoading{LoadingScreenView()}})
        }
     
        .navigationBarHidden(true)
       
    }
}









