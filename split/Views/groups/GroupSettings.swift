//
//  GroupSettings.swift
//  split
//
//  Created by Andrei Giangu on 20.06.2021.
//

import SwiftUI
import Firebase

struct GroupSettings: View {
    @EnvironmentObject var info : AppDelegate
    @EnvironmentObject var helper: Helper
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    @Environment(\.rootPresentationMode) private var rootPresentationMode: Binding<RootPresentationMode>
    @State var groupID : String
    @State var showActionSheet = false
    @State var sourceType : UIImagePickerController.SourceType = .photoLibrary
    @State var showImagePicker = false
    @State var icons = false
    @State private var image: UIImage?
    @Environment(\.colorScheme) var scheme
    @State var deleteGroupShow = false
    @State var createUserShow = false
    var columns = Array(repeating: GridItem(.flexible(),spacing:6), count:5)
    @State var picked = ""
    
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
                .foregroundColor(scheme == .dark ?  Color.white: Color.black)
                
                    .contentShape(Rectangle())
                    .frame(width:35,height:35)
                    .imageScale(.medium)
        }

                Spacer()
                
                
                Text("\(helper.getShortDate(date: info.groups[helper.find(value: groupID, in: info.groups) ?? 0].date))")
                    .font(.system(size: 15, weight: .medium, design: .default))
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                
                
                
            } .padding(.leading)
            .padding(.top)
            .padding(.trailing)
            .padding(.top,getSafeArea().top)
            
            HStack{
                
                Spacer()
                
               
                Text("\(info.groups[helper.find(value: groupID, in: info.groups) ?? 0].paymentsId.count) payments ")
                    .font(.system(size: 15, weight: .medium, design: .default))
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
            }.padding(.trailing)
           
          
            HStack{
                
                Spacer()
                
               

                    Text("\(info.groups[helper.find(value: groupID, in: info.groups) ?? 0].users.count + info.groups[helper.find(value: groupID, in: info.groups)!].createdUsers.count) users ")
                        .font(.system(size: 15, weight: .medium, design: .default))
                        .foregroundColor(scheme == .dark ?  Color.white : Color.black)
            }.padding(.trailing)
            
      
            
         
                
                VStack{
                    
                Button(action:{
                    
                    showActionSheet = true
                },label:{
                        
                    profilePicGROUPS(image: "\(info.groups[helper.find(value: groupID, in: info.groups) ?? 0].profilePic)", name: "\(info.groups[helper.find(value: groupID, in: info.groups) ?? 0].name)", r: 55,t:25, color: info.groups[helper.find(value: groupID, in: info.groups) ?? 0].color)
                    })
                    
                    
             Text("\(info.groups[helper.find(value: groupID, in: info.groups) ?? 0].name)")
                    .fontWeight(.light)
                    .frame(width:55)
                .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    .lineLimit(1)
                    .truncationMode(.tail)
              
                
          
                    
                    
                    
                }.padding()
                
                
                
                
            
                
                
                VStack{
                    
            
                                    
                    VStack{
                                     
                        btnView(image: "", name: "Push notifications", action:
                                    self.pushNotif
                                      )

                                            
                        }
                    .background(BlurView())
                    .cornerRadius(15)
                    .padding(.leading,20)
                    .padding(.trailing,20)
                    .shadow(color: Color.black.opacity(0.01),radius:1 , x:1 , y:1)
                    .shadow(color: Color.black.opacity(0.01),radius:1 , x:-1 , y:-1)
                                
                    
                    
                    
                    
                    
                }
                
                
               HStack{
                    
                   
                    Button(action:{   helper.groupInvite(groupID: groupID, title: info.groups[helper.find(value: groupID, in: info.groups) ?? 0].name)
                    }, label:{
                    
                        Text("\(Text("Invite")) \(Image(systemName: "paperplane"))")
                            .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.vertical,10)
                                .frame(maxWidth: .infinity)
                                .background(
                                
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray)
                                )
                            
                }).padding(.leading)
                   
                    
                    

                    
                    Button(action:{
                        createUserShow = true
                    }, label:{
                    
                        Text("\(Text("Create")) \(Image(systemName: "plus"))")
                            .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.vertical,10)
                                .frame(maxWidth: .infinity)
                                .background(
                                
                                RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray)
                                )
                            
                }).padding(.trailing)
                    .fullScreenCover(isPresented: $createUserShow){
                        createUserView(groupID: groupID)
                    }
                    
                    
                }.padding(.top,40)
            
            
            Button(action:{
                
              
                deleteGroupShow = true
            }, label:{
            
                Text("\(Text("Delete group"))")
                   
                    
        }) .font(.system(size:13))
            .foregroundColor(.red)
//            .background(spent.isEmpty || SecondView.g_participants.count < 3 || Int(spent) == 0 ? Color.white.opacity(0.16): Color.blue)
            .padding(.vertical, 13)
            .padding(.horizontal, 22)
            .background( Color.red.opacity(0.1)
                            .clipShape(Rectangle())
                                .cornerRadius(6))
            .cornerRadius(9)
            .buttonStyle(PlainButtonStyle())
            .padding(.top,40)
            
                Spacer()
            
            
            } .ignoresSafeArea()

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
                                
                                ActionSheetCardItem(sfSymbolName: "case", label: "Choose from our icons", foregrounColor: Color.purple) {

                                        self.icons = true
                                },
                                ActionSheetCardItem(sfSymbolName: "trash.fill", label: "Remove", foregrounColor: Color.red) {
                                    let db = Firestore.firestore()
                                       let newDocument = db.collection("groups").document("\(groupID)")
                                       newDocument.setData(["profilePic": ""], merge: true)
                                   
                                    
                                }
                            ])
            
            ActionSheetIcons(isShowing: $icons,groupID: groupID
  
            )
            
            ActionSheetDeleteGroup(isShowing: $deleteGroupShow, groupID: groupID)
        
         
        
        }     .sheet(isPresented: self.$showImagePicker, onDismiss: {
                        if( image != nil) {
        
        loadGroupImage(image: image, groupID: groupID)
    } } ){
        
        if(sourceType == .camera){
            
            ImagePickerView(image: self.$image, sourceType:.camera )
                .edgesIgnoringSafeArea(.all).ignoresSafeArea()
        }
        
        if(sourceType == .photoLibrary){
            ImagePickerView(image: self.$image, sourceType:.photoLibrary )
            
        }
        }
        
    }
    

    
    
    func pushNotif(){}
    func emailNotif(){}
}

