//
//  LoadingScreenView.swift
//  split
//
//  Created by Andrei Giangu on 23.05.2021.
//

import SwiftUI

struct LoadingScreenView: View {
    var body: some View {
        ZStack{
            
            Color.black.opacity(0.23)
            
            
            ProgressView()
                .frame(width:70, height:70)
                .background(Color.white)
                .cornerRadius(10)
            
            //color scheme to light for indicator visibiltiy
                .colorScheme(.light)
        }
        .ignoresSafeArea()
    }
}

struct LoadingScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingScreenView()
    }
}
