//
//  darkView.swift
//  split
//
//  Created by Andrei Giangu on 30.05.2021.
//


import SwiftUI

public struct GreyOutOfFocusView: View {
    let opacity: CGFloat
    let callback: (() -> ())?
    
    public init(
        opacity: CGFloat = 0.5,
        callback: (() -> ())? = nil
    ) {
        self.opacity = opacity
        self.callback = callback
    }
    
    var greyView: some View {
        Rectangle()
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .background(Color.gray)
            .opacity(0.2)
            .onTapGesture {
                callback?()
            }
            .ignoresSafeArea(.all)
    }
    
    public var body: some View {
        greyView
    }
}

struct GreyOutOfFocusView_Previews: PreviewProvider {
    static var previews: some View {
        GreyOutOfFocusView()
    }
}
