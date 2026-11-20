//
//  listGroupView.swift
//  split
//
//  Created by Andrei Giangu on 23.06.2021.
//

import SwiftUI

struct listGroupView: View {
    
    @Environment(\.colorScheme) var scheme
 
    var item: Event
    
    var body: some View {
        
        
        VStack{


            
            Text("\(item.name)").foregroundColor(scheme == .dark ?  Color.white : Color.black).font(.title2)
                .fontWeight(.bold)
                .foregroundColor(scheme == .dark ?  Color.white : Color.black)
            
            Text("\(item.users.count + item.createdUsers.count) users").foregroundColor(scheme == .dark ?  Color.white : Color.black)
            
            Text("\(item.paymentsId.count ) payments").foregroundColor(scheme == .dark ?  Color.white : Color.black)
            
            profilePicGROUPS(image: item.profilePic, name: item.name, r: 35,t:18,color: item.color)
          
        }
        
        .aspectRatio(contentMode: .fill)
        
        .frame(width: (UIScreen.main.bounds.width - 52) / 2, height: 180)
        
        .background(BlurView().opacity(0.5))
        .overlay(RoundedRectangle(cornerRadius: 15).stroke(scheme == .dark ? Color.white : Color.black, lineWidth: 1))
        .cornerRadius(15)
        
        
        
        
    }
}


