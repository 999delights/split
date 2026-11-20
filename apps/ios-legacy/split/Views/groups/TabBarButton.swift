//
//  TabBarButton.swift
//  split
//
//  Created by Andrei Giangu on 09.07.2021.
//

import SwiftUI


struct TabBarButton: View {
    
    var image: String
    // Since we're having asset Image...
    @Environment(\.colorScheme) var scheme
    var animation: Namespace.ID
    @Binding var selectedTab: String
    
    var body: some View{
        
    
            
            
        
        
        Button(action: {
            withAnimation(.easeInOut){
                selectedTab = image
            }
        }, label: {
            VStack(spacing: 12){
                
                (
                    Text(image)
                )
                .fontWeight(.bold)
                .foregroundColor(selectedTab == image ? scheme == .dark ? .white : .black : .gray)
                .frame( height: 28)
                .contentShape(Rectangle())
            
                
                ZStack{
                    
                    if selectedTab == image{
                        Rectangle()
                            .fill(Color.primary)
                            // For Smooth sliding effect...
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    }
                    else{
                        Rectangle()
                            .fill(Color.clear)
                    }
                }
                .frame(height: 1)
            }
        })
    }
}


