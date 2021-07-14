//
//  ActionSheetIcons.swift
//  split
//
//  Created by Andrei Giangu on 20.06.2021.
//

import SwiftUI
import Combine
import Firebase

public struct ActionSheetIcons: View {

   
    @GestureState private var dragState = DragState.inactive
    @Binding var isShowing: Bool
    @State var groupID : String
    var columns = Array(repeating: GridItem(.flexible(),spacing:6), count:5)
    @State var picked = ""
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
        groupID: String
        
    ) {
       
        _isShowing = isShowing
        self.groupID = groupID
        
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
            
            LazyVGrid(columns: columns,spacing: 12){
            ForEach(1...20,id: \.self){index in
                
                Button(action:{
                    
                    
                    if picked == "group\(index)" {
                       
                picked = ""
                    }
                    
                    else {
                     
                picked = "group\(index)"
                    }
                    
                },label:{
                   
                    Image("group\(index)")
                        
                        .resizable()
                        .imageScale(picked == "group\(index)" ? .small : .large)
                        .aspectRatio(contentMode: .fit)
                        
                        .frame(width:40, height: 40 )
                      
                        .overlay(
                            Rectangle().stroke(Color.gray,lineWidth: 2).opacity(picked == "group\(index)" ? 1 : 0) )
                })
               
            }
            
            
            }.padding(.bottom)

        Button(action:{
            
            let db = Firestore.firestore()
            
            db.collection("groups").document("\(groupID)").setData(["profilePic": "\(picked)"],merge:true)
            
        
            
            isShowing = false
            
        }, label:{
            
            Text("Done")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical,15)
                .frame(maxWidth:.infinity)
                .background(Color.green)
                .cornerRadius(12)
                .padding(.leading,20)
                .padding(.trailing,20)
        }).disabled(picked == "" )
        .opacity((picked == "") ? 0.6  : 1)
                
            
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









