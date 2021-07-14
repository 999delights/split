//
//  ConfirmDeleteView.swift
//  split
//
//  Created by Andrei Giangu on 11.07.2021.
//

//
//  confirmPaidView.swift
//  split
//
//  Created by Andrei Giangu on 08.07.2021.
//
//
//  ActionSheetIcons.swift
//  split
//

//

import SwiftUI
import Combine
import Firebase

public struct ActionSheetDeleteGroup: View {
    @EnvironmentObject var helper: Helper
    @EnvironmentObject var info : AppDelegate
    @GestureState private var dragState = DragState.inactive
    let groupID : String
    @Binding var isShowing: Bool
    @Environment(\.colorScheme) var scheme
    var columns = Array(repeating: GridItem(.flexible(),spacing:6), count:5)
    @Environment(\.rootPresentationMode) private var rootPresentationMode:Binding<RootPresentationMode>
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
        isShowing : Binding<Bool>,
        groupID : String
    ) {
       
        _isShowing = isShowing
        self.groupID  = groupID
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
            
            HStack{
                
                
                Text("Delete Group")
                    .font(.system(size:20))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                
                Spacer()
                
                
            }.padding()
            
            HStack{
             
                Text("This will delete group for all users involved")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
            }.padding()
                
          
                
                
          

        Button(action:{
            

   
            
            
            isShowing = false
            self.rootPresentationMode.wrappedValue.dismiss()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                deleteGroup(groupID: "\(groupID)")
           
                
            }
           
            
        }, label:{
            
            Text("Ok")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical,15)
                .frame(maxWidth:.infinity)
                .background(Color.red)
                .cornerRadius(12)
                .padding(.leading,20)
                .padding(.trailing,20)
        })
                
            
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
    
    
    func deleteGroup(groupID: String){
        
         let db = Firestore.firestore()
        
        

        
        for user in info.usersInGroup {
            let id = user.id
            let deleteGroupFromUser = db.collection("users").document("\(id)")
            deleteGroupFromUser.updateData(["groups" : FieldValue.arrayRemove(["\(groupID)"])])
        }
        
        
        for (key,value) in info.groups[helper.find(value: groupID, in: info.groups)!].paymentsId {
            
    
                
                let id = value
                db.collection("payments").document("\(id)").delete() { err in
                    if let err = err {
                        print("Error removing document: \(err)")
                    } else {
                        print("Document successfully removed!")
                    }
                }
                
            
            
        }
        
        
        
        
        
        db.collection("groups").document("\(groupID)").delete() { err in
            if let err = err {
                print("Error removing document: \(err)")
            } else {
                print("Document successfully removed!")
            }
        }
        
        
    }

}









