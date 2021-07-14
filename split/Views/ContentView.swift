//
//  ContentView.swift
//  split
//
//  Created by Andrei Giangu on 23.05.2021.
//

import SwiftUI
import CoreData
import Firebase
import FirebaseDynamicLinks
struct ContentView: View {
    
    @State var animate = false
    @State var endSplash = false

//    @StateObject var fetchedUser = FetchedUserModel()
    @StateObject var loginData = LoginViewModel()
    @StateObject var userData = UserViewModel()
    @StateObject var helper = Helper()
    @State var done = false
    @StateObject var info: AppDelegate
    @Environment(\.colorScheme) var scheme
    
@AppStorage("log_Status") var status = false

    var body: some View {
        
        
        
     
        
        ZStack{
            
            
            if !status && endSplash
            {
                LogInView().environmentObject(loginData)
                    .environmentObject(userData)
                    .environmentObject(info)
                   
                    
            }

            
       
            if status {
                
          
      
                
                if info.userLog.nickname == "" && endSplash { getNicknameView()
                            .environmentObject(userData)
                            .environmentObject(loginData)
                            .environmentObject(info)
                    }
           
                
                
            
            
           if    info.userLog.nickname != "" && endSplash{
         
                HomeView()
                
                .environmentObject(helper)
                .environmentObject(userData)
                .environmentObject(loginData)
                .environmentObject(info)
       
                        
          
            
            
           }}
          
            
                  ZStack{
                    
                    scheme == .dark ? Color.black.ignoresSafeArea() :  Color.white.ignoresSafeArea()
                    
                          
                           Text("split paper")
                               .font(.system(size:30))
                               .fontWeight(.heavy)
                               .foregroundColor(.gray)
                               .aspectRatio(contentMode: animate ? .fill : .fit)
                             
                               .frame(width: UIScreen.main.bounds.width)
                            
                       }
                  
                       .ignoresSafeArea(.all, edges: .all)
                       .onAppear(perform: animateSplash)
                       .opacity(endSplash ? 0 : 1 )

        }
        .onChange(of: status){ value in
            
           
            if status == true {
                self.info.fetchData()
   
            }
        
        }
        .onAppear{
            
            
            if status == true {
            self.info.fetchData()
            
          
        }}

    }
    
    
    
    
    
    func animateSplash(){
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
            
            
            
            withAnimation(Animation.easeOut(duration:0.45)){
                
                                    
               
                endSplash.toggle()
                
            }
        }
    }
    
    
    

    
    
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(info: )
//
//    }
//}



