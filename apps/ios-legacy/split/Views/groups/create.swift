//
//  createJoin.swift
//  split
//
//  Created by Andrei Giangu on 05.06.2021.
//

import SwiftUI
import Firebase
import FirebaseDynamicLinks
struct create: View {

    @Environment(\.presentationMode) var presentationMode
    @State var page = ""
    @State var showActionSheet = false
    @State var showImagePicker = false
    @EnvironmentObject var helper : Helper
    @ObservedObject var keyboardHeightHelper = KeyboardHeightHelper()
    @EnvironmentObject var info: AppDelegate
    var columns = Array(repeating: GridItem(.flexible(),spacing:6), count:5)
    @State var picked = ""
    @State var sourceType : UIImagePickerController.SourceType = .photoLibrary
    @StateObject var groups = GroupViewModel()
    
    @Environment(\.colorScheme) var scheme
    var body: some View {
        
      
            
        ZStack{
         
            scheme == .dark ? Color.black.ignoresSafeArea() :  Color.white.ignoresSafeArea()
           
                VStack{
                    
                    HStack{
                        
                        
                        
                        
                        
                        Button(action: {
                            page = "1"
                           
                            
                         }
                        ,label:{
                            Text("Back  ")
                                .opacity(page == "2" ? 1 : 0)
                                
                                .padding()
                                .foregroundColor(scheme == .dark ?  Color.gray : Color.white)
                        }).disabled(page == "2" ? false : true)
                            
                        
                        
                        
                
                        
                        Spacer()
                        
                        Text("new group")
                            .foregroundColor(scheme == .dark ? Color.white : Color.black)
                            .fontWeight(.heavy)
                        
                        
                        Spacer()
                    
                        
                        Button(action: {
                             presentationMode.wrappedValue.dismiss()
                         }
                        ,label:{
                            Text("Cancel")
                                
                                .padding()
                                .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                                .opacity(page == "" ? 1 : 0)
                        }).disabled(page == "" ? false : true)
                         
                        
                        
                    }
                    if(page == "") {
                    LazyVGrid(columns: columns,spacing: 12){
                        ForEach(1...20,id: \.self){index in
                            
                            Button(action:{
                                
                                
                                if picked == "group\(index)" {
                                    groups.groups.profilePic = ""
                            picked = ""
                                }
                                
                                else {
                                    groups.groups.profilePic = "group\(index)"
                            picked = "group\(index)"
                                }
                                
                            },label:{
                               
                                Image("group\(index)")
                                    
                                    .resizable()
                                    .imageScale(picked == "group\(index)" ? .small : .large)
                                    .aspectRatio(contentMode: .fit)
                                    
                                    .frame(width:40, height: 40 )
                                  
                                    .overlay(
                                        Rectangle().stroke(scheme == .dark ?  Color.white : Color.black,lineWidth: 2).opacity(picked == "group\(index)" ? 1 : 0) )
                            })
                           
                        }
                        
                        
                    }
                    }
                    
                    
                    if(page == "1") {
                    
                     
                        VStack{
                            
                            profilePicGROUPS(image: groups.groups.profilePic, name: groups.groups.name, r: 65, t: 30,color: groups.groups.color).padding(.top,20)
                            
                            Text("\(groups.groups.name)")
                                .fontWeight(.light)
                                .frame(width:65)
                                .foregroundColor(scheme == .dark ?  Color.gray : Color.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        
                        
                        }
                    }
                    Spacer()
                    
                    
                    
                    
                }.ignoresSafeArea(.keyboard)
            
            
            
            
            VStack{
                
            if page == ""{
                
         
                
                VStack{
                    
                    Spacer()
             
               
              
                    
            HStack{
                
            Text("What is the group name?")
                .font(.system(size:25))
                .foregroundColor(scheme == .dark ? Color.white : Color.black)
                .fontWeight(.heavy)
                .padding(.leading)
                .padding(.bottom,30)
         
                
                      Spacer()
            
            }
                
                    TextField("", text: $groups.groups.name).modifier(ClearButton(text: $groups.groups.name))
            .padding(.leading)
            .padding(.trailing)
            .keyboardType(.default)
            .font(.system(size: 25, weight: .medium, design: .default))
                        .onChange(of: self.groups.groups.name){ value in
                            if (groups.groups.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty){
                                groups.groups.name = groups.groups.name.trimmingCharacters(in: .whitespacesAndNewlines)
                }}
            .foregroundColor(Color.purple)
            
                .introspectTextField { textField in
                    textField.becomeFirstResponder()
                    
                    
                }
                
//                FirstResponderTextField(text: $paymentName, placeholder:  "a",color: UIColor.purple, size:26.0)
//                      .padding(.horizontal)
               
            
            Divider()
                .padding(.horizontal)
                .padding(.bottom,10)
        
        
           Button(action:{
                    
                    groups.createGroup()
                    
                    page = "1"}, label:{
               Text("Create")
                   .fontWeight(.semibold)
                   .foregroundColor(.white)
                   .padding(.vertical,15)
                   .frame(maxWidth:.infinity)
                   .background(Color.green)
                   .cornerRadius(12)
                   .padding(.leading,20)
                   .padding(.trailing,20)
                .keyboardAware()
                    }).disabled(groups.groups.name == "" )
            .opacity((groups.groups.name == "") ? 0.6  : 1)
                  
                    
                   
                    
                    
                    
                
                }
            }
          
           
            if page == "1" {
                
                VStack{
                    
                    
                    HStack{}.padding()
                    
                    
                    Spacer()
                    HStack{
                       
                        
                        Spacer()
                        
                        Text("Group Created")
                        .font(.system(size:35))
                        .foregroundColor(Color.purple.opacity(0.8))
                        .fontWeight(.heavy)
              
                      
                        Spacer()
                        
                    }.padding(.bottom,50)
                    
                    
                    HStack{
                        
                    Spacer()
                        
                        
                        Button(action:{
                            presentationMode.wrappedValue.dismiss()
                        
                            var components = URLComponents()
                            
                            components.scheme = "https"
                            components.host = "www.exemple.com"
                            components.path = "/group"
                            
                            
                            let groupIDQuerryItem = URLQueryItem(name: "groupID", value: groups.groups.id)
                            components.queryItems = [groupIDQuerryItem]
                            
                            guard let linkParameter = components.url else {return}
                            print("I am sharing \(linkParameter.absoluteString)")
                            
                            
                            
                            guard let shareLink = DynamicLinkComponents.init(link: linkParameter, domainURIPrefix: "https://splitpaper.page.link") else {
                                print("Couldn't create FDL components")
                                return
                            }
                            
                            if let myBundleId = Bundle.main.bundleIdentifier{
                                shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: myBundleId)
                            }
                            
                            shareLink.iOSParameters?.appStoreID = "962194608"
                            shareLink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
                            shareLink.socialMetaTagParameters?.title = "\(groups.groups.name)"
                            
                            guard let longURL = shareLink.url else {return}
                            
                            print("the long url is \(longURL)")
                            
                            shareLink.shorten {
                                 (url, warnings, error) in
                                
                                if let error = error {
                                    print ("error \(error)")
                                    return
                                }
                                if let warnings = warnings {
                                    for warning in warnings {
                                        print("FDL Warning \(warning)")
                                    }
                                }
                                
                                guard let url = url else {return}
                                print ("short URL \(url.absoluteString)")
                                
                                helper.showShareSheet(url: url)
                            }
                            
                        
                          
                            
                            
                           
                        },label:{
                            
                            
                            
                            Text("Share With Friends")
                            .font(.system(size:20))
                                .foregroundColor(Color.purple)
                            .fontWeight(.medium)
                            .font(.system(size:13))
                            .foregroundColor(.blue)

                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background( Color.blue.opacity(0.1)
                            .clipShape(Rectangle())
                            .cornerRadius(6))
                            .cornerRadius(9)
                            .buttonStyle(PlainButtonStyle())
                            
                        })
                   
                        
                        
                    
                        
                    Spacer()
                        
                    }
                    
                    
                    Spacer()
                    
           
                }
            }
                
                
            }.ignoresSafeArea(.keyboard, edges: .bottom)
            
         
            
            
        }
   
      
        
    }
}

struct createJoin_Previews: PreviewProvider {
    static var previews: some View {
        create()
    }
}


