//
//  changeNickname.swift
//  split
//
//  Created by Andrei Giangu on 29.05.2021.
//

import SwiftUI
import FirebaseStorage
import Introspect
import Firebase

struct changeNickname: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userData: UserViewModel
    @EnvironmentObject var info : AppDelegate
//    @EnvironmentObject var fetchedUser : FetchedUserModel
    @State var showActionSheet = false
    @State var showImagePicker = false
    @State var changedNickname = ""
    @State var change = false
    @State private var image: UIImage?
    @Environment(\.colorScheme) var scheme
    @State var sourceType : UIImagePickerController.SourceType = .photoLibrary
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
            .padding(.leading)
            .padding(.top)
            .padding(.trailing)
            .padding(.top,getSafeArea().top)
  
           
                
            
            profilePicUserSettings(name: info.userLog.nickname, r: 65,r2: 20, image: info.userLog.profilePic,action: $showActionSheet,change:$change).padding().onTapGesture {
                
                self.endTextEditing()
               
          }
            
                
            if( info.userLog.email.contains("@privaterelay.appleid.com")){
                
                Text("Apple Login")
                    .font(.system(size:15))
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                
            }
            
            else {
            Text("\(info.userLog.email)")
                .font(.system(size:15))
                .foregroundColor(scheme == .dark ?  Color.white : Color.black)
            }
            
            if(change == true){
                
                HStack{
                    
                 
                    
                    
            TextField("\(info.userLog.nickname)", text: $changedNickname)
                    
            }     .keyboardType(.default)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            
                
            .frame(height:40)
                .multilineTextAlignment(.center)
            
                .animation(.easeInOut)
            .foregroundColor(.gray)
            .background(Color.white)
            .font(.title)
            .cornerRadius(7)
                .onChange(of: self.changedNickname){ value in
                    if (changedNickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
                    changedNickname = changedNickname.trimmingCharacters(in: .whitespacesAndNewlines)
                    }}
                .padding(.top,10)
            .padding(.leading,100)
            .padding(.trailing,100)
                .introspectTextField { textField in
                    textField.becomeFirstResponder()
         
                }
                
                
                
                Button(action:{
                 let db = Firestore.firestore()
                    let Userid = Auth.auth().currentUser?.uid
                    let newDocument = db.collection("users").document("\(Userid ?? "")")
                    newDocument.setData(["nickname": changedNickname.trimmingCharacters(in: .whitespacesAndNewlines)], merge: true)
                    
                        change = false
                        changedNickname = ""
                    
                }, label:{
             
                    Text("Done").font(.system(size:20)).foregroundColor(Color.blue)
                }).padding()
                .disabled(changedNickname.isEmpty)
                .opacity(changedNickname.isEmpty  ? 0.6  : 1)
                .animation(.easeInOut)
                .transition(.asymmetric(insertion: .move(edge:.top), removal: AnyTransition.opacity.animation(.easeInOut)))
            }
            
            
            
            if change == false {
            Button(action:{change = true}, label:{
         
                Text("\(Text("@\(info.userLog.nickname)").font(.system(size:25))) \(Image(systemName: "pencil"))")
            }).padding()
            
            }


            ZStack{

            }.frame(maxHeight:.infinity)
            
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
                                },
                                ActionSheetCardItem(sfSymbolName: "trash.fill", label: "Remove", foregrounColor: Color.red) {
                                    let db = Firestore.firestore()
                                       let Userid = Auth.auth().currentUser?.uid
                                       let newDocument = db.collection("users").document("\(Userid ?? "")")
                                       newDocument.setData(["profilePic": ""], merge: true)
                                   
                                    
                                }
                            ])
            
        }
        .sheet(isPresented: self.$showImagePicker, onDismiss: {
                            if( image != nil) {
            
            loadUserImage(image: image)
        } }){
            
            if(sourceType == .camera){
                
                ImagePickerView(image: self.$image, sourceType:.camera )
                    .edgesIgnoringSafeArea(.all).ignoresSafeArea()
            }
            
            if(sourceType == .photoLibrary){
                ImagePickerView(image: self.$image, sourceType:.photoLibrary )
                
            }
            }

    }
}

struct changeNickname_Previews: PreviewProvider {
    static var previews: some View {
        changeNickname().environmentObject(UserViewModel())
    }
}




extension View {
  func endTextEditing() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
  }
}
