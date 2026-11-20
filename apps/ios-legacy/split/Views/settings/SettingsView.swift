//
//  SettingsView.swift
//  split
//
//  Created by Andrei Giangu on 24.05.2021.
//

import SwiftUI
import Firebase
import GoogleSignIn
import UIKit
import FirebaseStorage

struct SettingsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("log_Status") var status = false
    @EnvironmentObject var userData: UserViewModel
    @EnvironmentObject var loginData : LoginViewModel
//    @EnvironmentObject var fetchedUser: FetchedUserModel
    @EnvironmentObject var info: AppDelegate
    @State var changeNickname = false
    @State var showImagePicker = false
    @State private var image: UIImage?
    @State var sourceType : UIImagePickerController.SourceType = .photoLibrary
    @State var showActionSheet = false
    @State var change = false
    @Environment(\.colorScheme) var scheme
    var body: some View {
        
        
      
       
        ZStack{
            
            scheme == .dark ? Color.black.ignoresSafeArea() :  Color.white.ignoresSafeArea()
            VStack{
                
                
                HStack(spacing:10){
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

            Spacer()
                }
                .padding()
                .padding(.top,getSafeArea().top)
               
                ScrollView(showsIndicators:false){
                
                HStack{
                    
                    
                  
                        
                        NavigationLink(
                            destination: split.changeNickname().environmentObject(userData).environmentObject(info)
                                        ,
                            isActive: $changeNickname){}
                    
                            Button(action:{changeNickname = true }, label:{
                            
                                Text("\(Text("@\(info.userLog.nickname)").font(.system(size:25))) \(Image(systemName: "pencil"))")
                                    .font(.system(size:19))
                                    .foregroundColor(Color.blue)
                                    
                        })
                        
                  
                    
                Spacer()
                    
                    profilePicUserSettings(name: info.userLog.nickname, r: 55, r2:17, image: info.userLog.profilePic, action: $showActionSheet,change:$change)
                    
      
                    
                }.padding(.horizontal)
               
                
       
                
                HStack{
                    
                    Text("Notifications")
                        .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        .fontWeight(.medium)
                    
                    Spacer()
                                
                }
                .padding(.horizontal)
                .padding(.top,15)
                .padding(.bottom,5)
                                
                VStack{
                                 
                    btnView(image: "", name: "Push notifications", action:
                                self.pushNotif
                                  )
                    
                    
                    btnView(image: "", name: "Email notifications", action:
                                self.emailNotif
                                  )
                                        
                    }
                .background(BlurView())
                .cornerRadius(15)
                .padding(.leading,20)
                .padding(.trailing,20)
                .shadow(color: Color.black.opacity(0.01),radius:1 , x:1 , y:1)
                .shadow(color: Color.black.opacity(0.01),radius:1 , x:-1 , y:-1)
                            
                HStack{
                    
                    Text("Appearance")
                        .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        .fontWeight(.medium)
                    
                    Spacer()
                
                }
                .padding(.horizontal)
                .padding(.top,15)
                .padding(.bottom,5)
                
                VStack{
                
                    btnView(image: "", name: "Theme", action:
                                
                                self.changeTheme )
                                        
                    }
                .background(BlurView())
                .cornerRadius(15)
                .padding(.leading,20)
                .padding(.trailing,20)
                .shadow(color: Color.black.opacity(0.01),radius:1 , x:1 , y:1)
                .shadow(color: Color.black.opacity(0.01),radius:1 , x:-1 , y:-1)
                
                HStack{
                    
                    Text("Make it better")
                        .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        .fontWeight(.medium)
                    
                    Spacer()
                  
                    
                }
                .padding(.horizontal)
                .padding(.top,15)
                .padding(.bottom,5)
                
                VStack{
                  
                    btnView(image: "", name: "Report a problem", action:
                                self.Report
                                  )
                    
              
                    }
                .background(BlurView())
                .cornerRadius(15)
                .padding(.leading,20)
                .padding(.trailing,20)
                .shadow(color: Color.black.opacity(0.01),radius:1 , x:1 , y:1)
                .shadow(color: Color.black.opacity(0.01),radius:1 , x:-1 , y:-1)
        
                VStack{
                  
                    btnView(image: "", name: "Log Out", action:
                                self.logOut
                                  )
                    }
                .background(BlurView())
                .cornerRadius(15)
                .padding(.bottom)
                .padding(.top,20)
                .padding(.leading,20)
                .padding(.trailing,20)
                .shadow(color: Color.black.opacity(0.01),radius:1 , x:1 , y:1)
                .shadow(color: Color.black.opacity(0.01),radius:1 , x:-1 , y:-1)
                
       
            }
                
                
        
                
             
                
            }
          
            
            .ignoresSafeArea()
            .background(scheme == .dark ? Color.black : Color.white)
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(true)
            
            
           
            
            ActionSheetCard(isShowing: $showActionSheet,
                            items: [
                                ActionSheetCardItem(sfSymbolName: "camera", label: "Camera") {
                                
                                    self.sourceType = .camera
                                        self.showImagePicker = true
                                },
                                ActionSheetCardItem(sfSymbolName: "photo", label: "Choose from gallery", foregrounColor: Color.blue) {
                                 
                                    self.sourceType = .photoLibrary
                                    
                                        self.showImagePicker = true
                                    }
                            ])
            
        
        }
      
        .sheet(isPresented: self.$showImagePicker, onDismiss: {
            if( image != nil) {
                
                loadUserImage(image: image)
            }
            
        }){
            
            if(sourceType == .camera){
                
                ImagePickerView(image: $image, sourceType:.camera )
                    .edgesIgnoringSafeArea(.all).ignoresSafeArea()
                   
            }
            
            if(sourceType == .photoLibrary){
                ImagePickerView(image: $image, sourceType:.photoLibrary )
                
            }
            }
  
    
        
        
    }
    
    func logOut() {
        withAnimation{
            status = false}
        try? Auth.auth().signOut()
    GIDSignIn.sharedInstance().signOut()
    info.userLog.nickname = ""
    info.userLog.id = ""
    loginData.email = ""
    loginData.password = ""
    loginData.newEmail = ""
    loginData.reEnterPassword = ""
    loginData.registerPassword = ""
    info.email = ""
    loginData.signupmail = false
    loginData.signinmail = false
    userData.user.nickname = ""
       
        
    }
    
    func changeTheme() {}
    
    func Report(){}
    
 
    func pushNotif(){}
    func emailNotif(){}
    
    
    }


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(UserViewModel())
    }
}









extension View{
    func getSafeArea()->UIEdgeInsets{
        return UIApplication.shared.windows.first?.safeAreaInsets ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    func getRect()->CGRect{
        return UIScreen.main.bounds
    }
}
