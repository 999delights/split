//
//  profilePic.swift
//  split
//
//  Created by Andrei Giangu on 30.05.2021.
//

import SwiftUI
import SDWebImageSwiftUI




struct profilePicUSER: View {
    var image: String
    var name:String
    var r:CGFloat
    @Environment(\.colorScheme) var scheme
    @Binding var action:Bool
    
    var body: some View {
        Button(action:{ action.toggle() }, label:{
            
            
            if image != "" {
                Circle()

                    .fill(Color.gray.opacity(0.2))
                    .frame(width:r, height:r)
                    .overlay(
                
                    AnimatedImage(url: URL(string:image)!)
                    .resizable()
                    .aspectRatio(contentMode:.fill)
                    .clipShape(Circle())
                    .frame(width:r, height:r)
                )
               
            }
            else {
        Circle()

            .fill(Color.gray.opacity(0.2))
            .frame(width:r, height:r)
            .overlay(

                //first letter as image
                Text("\(String(name.first?.description ?? ""))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    .textCase(.uppercase) )
            
            }
           
        
    })
    }
}


struct profilePicCreatedUsers: View {
    var name:String
    var r:CGFloat
//    @Binding var action:Bool
    @Environment(\.colorScheme) var scheme
    var body: some View {
        
        
        Circle()

            .fill(Color.gray.opacity(0.2))
            .frame(width:r, height:r)
            .overlay(

                //first letter as image
                Text("\(String(name.first?.description ?? ""))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.purple)
                    .textCase(.uppercase) )
        
    }
    
    
    
    
}


struct profilePicUSERS: View {
    var image: String
    var name:String
    var r:CGFloat
//    @Binding var action:Bool
    @Environment(\.colorScheme) var scheme
    var body: some View {
   
            
            
            if image != "" {
                
        
                
                
                Circle()

                    .fill(Color.gray.opacity(0.2))
                    .frame(width:r, height:r)
                    .overlay(
                
                    AnimatedImage(url: URL(string:image)!)
                    .resizable()
                    .aspectRatio(contentMode:.fill)
                    .clipShape(Circle())
                    .frame(width:r, height:r)
                )
               
            }
            else {
        Circle()

            .fill(Color.gray.opacity(0.2))
            .frame(width:r, height:r)
            .overlay(

                //first letter as image
                Text("\(String(name.first?.description ?? ""))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    .textCase(.uppercase) )
            
            }
           
        
    
    }
}

struct plusButton: View {
    var r:CGFloat
    @Environment(\.colorScheme) var scheme
    var body: some View {
        
       
        Rectangle()

            .opacity(0)
            .frame(width:r, height:r)
            .cornerRadius(10)
            .overlay(
                Image(systemName:"plus")
                    .foregroundColor(Color.gray)
                    .frame(width:r, height:r)
                    .overlay(
                        RoundedRectangle(cornerRadius:10)
                                        .stroke(Color.gray, style: StrokeStyle(lineWidth:2, lineCap: .round, lineJoin:.round, dash: [10,10]))
                    )
            )
            
          
                
               
            
        
        
        
    }
}




struct profilePicGROUPS: View {
    var image: String
    var name:String
    var r:CGFloat
    var t: CGFloat
    var color: String
    @Environment(\.colorScheme) var scheme
    var body: some View {
        
     
            
            if image != "" {
                
                if image.count == 6 || image.count == 7 {
                ForEach(1...20,id: \.self){index in
                    if image == "group\(index)"{
                        
                        Rectangle()

                            .fill(Color.init( UIColor(named:"\(color)")!))
                            .frame(width:r, height:r)
                            .cornerRadius(10)
                            .overlay(
                        
                            Image("group\(index)")
                            .resizable()
                            .aspectRatio(contentMode:.fill)
                            .clipShape(Rectangle())
                            .frame(width:r, height:r)
                            .cornerRadius(10)
                        )
                                          
                    }
                }
                }
                else if image.count != 6 || image.count != 7{
                
                Rectangle()

                    .fill(Color.init( UIColor(named:color)!))
                    .frame(width:r, height:r)
                    .cornerRadius(10)
                    .overlay(
                
                    AnimatedImage(url: URL(string:image)!)
                    .resizable()
                    .aspectRatio(contentMode:.fill)
                    .clipShape(Rectangle())
                    .frame(width:r, height:r)
                    .cornerRadius(10)
                )
                
              
                }
            }
            else {
                ZStack{
                    
                    
        Rectangle()
            
            .fill(Color.init( UIColor(named:color)!))
            .frame(width:r, height:r)
            .cornerRadius(10)
            
            .overlay(

                //first letter as image
                Text("\(String(name.first?.description ?? ""))")
                    
                    .font(.system(size:t))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                    .textCase(.uppercase)
            )
                
            
            
            
        }
                
            }
        
   
    }
}



struct profilePicUserSettings: View {
    var name:String
    var r:CGFloat
    var r2:CGFloat
    var image: String
    @Binding var action:Bool
    @Binding var change:Bool
    @Environment(\.colorScheme) var scheme
    var body: some View {
        Button(action:{
          
           
                change = false
                self.endTextEditing()
            action.toggle()
            
        }, label:{
        
        
            
            
            
            ZStack(alignment: .bottomTrailing){
              
                
                if image != "" {
                    Circle()

                        .fill(Color.gray.opacity(0.2))
                        .frame(width:r, height:r)
                        .overlay(
                    
                        AnimatedImage(url: URL(string:image)!)
                        .resizable()
                        .aspectRatio(contentMode:.fill)
                        .clipShape(Circle())
                        .frame(width:r, height:r)
                    )
                   
                }
                
                else {
        Circle()

            .fill(Color.gray.opacity(0.2))
            .frame(width:r, height:r)
            .overlay(

                //first letter as image
                Text("\(String(name.first?.description ?? ""))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .textCase(.uppercase) )
            
            
                }
            Circle()
                .frame(width: r2 ,height: r2)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .overlay(Image(systemName: "camera.fill").foregroundColor(.white).font(.system(size:7)))
             
                    
            }
            
        
        
        })      
    }
}


struct profilePicUserActivity: View {
    var userName:String
    var r:CGFloat
    var r2:CGFloat
    var userImage: String
    var groupImage: String
    var groupName: String
    var t:CGFloat
    var color: String
    @Environment(\.colorScheme) var scheme
    var body: some View {
        Button(action:{
          
           
               
            
        }, label:{
        
        
            
            
            
            ZStack(alignment: .bottomTrailing){
              
                
                if userImage != "" {
                    Circle()

                        .fill(Color.gray.opacity(0.2))
                        .frame(width:r, height:r)
                        .overlay(
                    
                        AnimatedImage(url: URL(string:userImage)!)
                        .resizable()
                        .aspectRatio(contentMode:.fill)
                        .clipShape(Circle())
                        .frame(width:r, height:r)
                    )
                   
                }
                
                else {
        Circle()

            .fill(Color.gray.opacity(0.2))
            .frame(width:r, height:r)
            .overlay(

                //first letter as image
                Text("\(String(userName.first?.description ?? ""))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(scheme == .dark ?  Color.gray : Color.white)
                    .textCase(.uppercase) )
            
            
                }
                profilePicGROUPS(image: groupImage, name: groupName, r: r2, t:t, color:color)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 2))
            .offset(y:5)
            .offset(x:5)
                    
            }
            
        
        
        })
    }
}



struct profilePicToggled: View {
    var name:String
    var r:CGFloat
    var r2:CGFloat
    var image: String
    @Environment(\.colorScheme) var scheme
    @Binding var action:Bool?
    @Binding var number: Int
    @Binding var users: [String:Bool]
    @Binding var toggle1 : Bool
    @Binding var toggleToti: Bool
    @Binding var split: [String:String]
    @Binding var price: String
    @Binding var changed: [String:Bool]
    var body: some View {
        
        
        
        Button(action:{
          
           
                
           
            for (k,_) in changed {
               changed[k] = false
            }
            action?.toggle()
            var count: Int = 0
            for (key,_) in users {
                
                if users[key] == true {
                    count += 1
                    toggle1 = true
                    number = count
                }}
                
                if count == 0 {
                    toggle1 = false
                    toggleToti = false
                    number = 0
                }
                
                else if count == users.count {
                    toggle1 = true
                    toggleToti = true
                }
                
                else if count < users.count && count != 0{
                    toggle1 = true
                  toggleToti = false
                }
                
               
           
            for (key,_) in users {
                if(users[key] == true)
                {
                    for (key2,_) in split {
                        if key == key2{
                            split[key2] = String(Double( Double(price)!  / Double(number)).clean)
                                                 
                        }
                    }
                }
                
                else{
                    for(key2,_) in split{
                        if key == key2 {
                            split[key2] = ""
                        }
                        
                    }
                    
                }
                
            }
           
        }, label:{
        
        
            
            
            
            ZStack(alignment: .bottomTrailing){
              
                
                if image != "" {
                    Circle()

                        .fill(Color.gray.opacity(0.2))
                        .frame(width:r, height:r)
                        .overlay(
                    
                        AnimatedImage(url: URL(string:image)!)
                        .resizable()
                        .aspectRatio(contentMode:.fill)
                        .clipShape(Circle())
                        .frame(width:r, height:r)
                    )
                   
                }
                
                else {
        Circle()

            .fill(Color.gray.opacity(0.2))
            .frame(width:r, height:r)
            .overlay(

                //first letter as image
                Text("\(String(name.first?.description ?? ""))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(scheme == .dark ?  Color.gray : Color.white)
                    .textCase(.uppercase) )
            
            
                }
            Circle()
                .fill(action == true ? Color.blue : Color.gray)
                .frame(width: r2 ,height: r2)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .overlay(Image(systemName: "checkmark").foregroundColor(.white).font(.system(size: 10, weight: .heavy, design: .default)))
                    
                    
            }
            
        
        
        })
    }
}







public extension UIApplication {

    static func dismissKeyboard() {
        let keyWindow = shared.connectedScenes
                .filter({$0.activationState == .foregroundActive})
                .map({$0 as? UIWindowScene})
                .compactMap({$0})
                .first?.windows
                .filter({$0.isKeyWindow}).first
        keyWindow?.endEditing(true)
    }
}

// extending view to get random Colors
extension UIColor{
    static func random () -> UIColor{
        return UIColor(
            red: .random(in: 0.8...1),
            green: .random(in: 0.8...1),
            blue: .random(in: 0.8...1),
            alpha: 1.0
        )
        
    }
    
    
}
