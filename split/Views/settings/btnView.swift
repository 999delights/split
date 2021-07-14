//
//  btnView.swift
//  split
//
//  Created by Andrei Giangu on 29.05.2021.
//

import SwiftUI

struct btnView: View{
    
    
    var image = ""
    var name = ""
    var action : () -> Void
    @Environment(\.colorScheme) var scheme
    var body: some View{
        
        
        Button(action: {self.action()},label:
            {
            
            
            HStack(spacing:10){
                
                Text(name) .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                
                Spacer(minLength:10)
                
                
                
            }.padding()
            .foregroundColor(Color.black.opacity(0.5))
        })
    }
}
