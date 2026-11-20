//
//  ActionSheetCardView.swift
//  split
//
//  Created by Andrei Giangu on 30.05.2021.
//

import SwiftUI
import Combine

public struct ActionSheetCard: View {

   
    @GestureState private var dragState = DragState.inactive
    @Binding var isShowing: Bool
    let items: [ActionSheetCardItem]
    @State var button = false
    let cellHeight: CGFloat = 60
  
    var modalHeight:CGFloat = 400
    private func onDragEnded(drag: DragGesture.Value) {
        let dragThreshold = cellHeight * (2)
        if drag.predictedEndTranslation.height > dragThreshold || drag.translation.height > dragThreshold{
            isShowing = false
        }
    }
    
    public init(
        isShowing: Binding<Bool>,
        items: [ActionSheetCardItem]
        
    ) {
       
        _isShowing = isShowing
        self.items = items
        
    }
    
    
    
    
    enum DragState {
        case inactive
        case dragging(translation: CGSize)
        
        var translation: CGSize{
            switch self{
            case .inactive:
                return .zero
                
            case .dragging(let translation):
                return translation
            }
        }
        
        var isDragging: Bool {
            switch self {
            case .inactive:
                return false
            case .dragging:
                return true
            }
        }
        
    }
    
    

        
    var topHalfMiddleBar: some View {
        Capsule()
            .frame(width: 70, height: 5)
            .foregroundColor(Color.gray.opacity(0.5))
            .padding(.top, 20)
            .onTapGesture {
              isShowing = false
            }
    }
    
    var itemsView: some View {
        VStack {
            ForEach(0..<items.count) { index in
                if index > 0 {
                  
                }
                items[index]
                    .frame(height: cellHeight)
            }
        }
        .padding()
    }
    
    

    
    var outOfFocusArea: some View {
        Group {
            if isShowing {
                withAnimation{
                GreyOutOfFocusView {
                    self.isShowing = false
                }}
            }
        }
    }
    
    
    
    
    
    var sheetView: some View {
        
        
        
        let drag = DragGesture()
            .updating($dragState) { drag, state, transaction in
                state = .dragging(translation: drag.translation)
        }
        .onEnded(onDragEnded)
        
        return Group {   VStack {
            Spacer()
            
            VStack {
                topHalfMiddleBar
                itemsView
                Text("").frame(height: 20) // empty space
            }
            .background(BlurView())
            .cornerRadius(21)
            .offset(y: isShowing ? ((self.dragState.isDragging && dragState.translation.height >= 1) ? dragState.translation.height : 0) : modalHeight)
            .animation(.interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0))
            .gesture(drag)
        
         
        }
    }
    }
    
    
    
    
    
    
    
    
    var bodyContent: some View {
        ZStack {
            outOfFocusArea
            sheetView
        }
    }
    
    

    public var body: some View {
        
        
        
        Group {
         
                bodyContent
               
            
        }
        .animation(.default)
    
       
      
    }
}



struct ActionSheetCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            ActionSheetCard(isShowing: .constant(true),
                            items: [
                                ActionSheetCardItem(sfSymbolName: "play", label: "Play") {
                                    //
                                },
                                ActionSheetCardItem(sfSymbolName: "stop", label: "Stop") {
                                    //
                                },
                                ActionSheetCardItem(sfSymbolName: "record.circle", label: "Record")
                            ])
        }
    }
}





