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

public struct ActionSheetPaid: View {

    @EnvironmentObject var helper : Helper

    @EnvironmentObject var info: AppDelegate
    @GestureState private var dragState = DragState.inactive
    @Binding var isShowing: Bool
    @Environment(\.colorScheme) var scheme
    var columns = Array(repeating: GridItem(.flexible(),spacing:6), count:5)

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
        isShowing: Binding<Bool>
       
    ) {
       
        _isShowing = isShowing
     
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
                
                
                Text("Payment has been made")
                    .font(.system(size:20))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                
                Spacer()
                
                
            }.padding()
            
            HStack{
                Spacer(minLength: 0)
                
                Text("\(Double(helper.sum).clean2)")
                    .font(.system(size:25))
                    .fontWeight(.bold)
                    .foregroundColor(helper.tofrom == "to" ? Color("red") : Color("Cgroup5") )
                
                Spacer(minLength: 0)
                if helper.tofrom == "to" {
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size:35,weight: .light))
                        .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        
                            .contentShape(Rectangle())
                            .frame(width:35,height:35)
                            .imageScale(.medium)
                    
                }
                
                else if helper.tofrom == "from"
                {
                    Image(systemName: "arrow.left")
                        .font(.system(size:35,weight: .light))
                        .foregroundColor(scheme == .dark ?  Color.white : Color.black)
                        
                            .contentShape(Rectangle())
                            .frame(width:35,height:35)
                            .imageScale(.medium)
                }
                
                Spacer(minLength: 0)
                VStack{
                    
                    ForEach(info.usersInGroup.indices, id:\.self){i in
                     
                        if info.usersInGroup[i].id == helper.to {
                            
                            profilePicUSERS(image: info.usersInGroup[i].profilePic, name: info.usersInGroup[i].nickname, r: 55).padding(.top)
                            
                            
                            Text("\(info.usersInGroup[i].nickname)").font(.system(size:18)).foregroundColor(scheme == .dark ?  Color.white : Color.black).fontWeight(.heavy)
                            
                        }
                    }
                    
                    
                }
                
                Spacer(minLength: 0)
             
            }.padding()
                
                
          
                
                
          

        Button(action:{
            

   
            
            
            isShowing = false
            debtPerPersonXperson()
           
            
        }, label:{
            
            Text("Confirm")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical,15)
                .frame(maxWidth:.infinity)
                .background(Color.green)
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
    
    
    func debtPerPersonXperson() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
           
            for i in info.groups {
                if(i.users.count != 0){
                    for k in i.users {
                        for j in i.users {
                           
                                            
                                            let glued = i.id + k + j
                      
                                helper.matrix["\(glued)"] = Double(0)
                            
                           
                                            
                                            for p in info.payments{
                                                if(p.group == i.id){
                                                    for (key,value) in p.split{
                                                        if key == k {
                                                            if(p.by == j){
                                                                
                                                                if(value != ""){
                                                                    
                                                                    let glued = i.id + k + j
                                                                 
                                                                    
                                                                    helper.matrix["\(glued)"]! += Double(value)!
                                                                    
                                                                    
                                                                   
                                                                    
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                            
                            
                        
               
                                            
                                        } }
                         
                    
                    
                }
            }
            
           
      
       subtractMirroringDebts()
     smartTransferDebts()
      
        }
    }
    
    
    func subtractMirroringDebts() {
         for group in info.groups {
             if(group.users.count != 0){
                 for i in group.users{
                     for j in group.users {
                         if(i != j) {
                            let glued = group.id + i + j
                            let glued2 = group.id + j + i
                             if(helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]!) {

                                 helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                                 helper.matrix["\(glued2)"]! = 0

                             }
                             else {

                                 helper.matrix["\(glued2)"]! -=   helper.matrix["\(glued)"]!
                                 helper.matrix["\(glued)"]! = 0

                             }



                         }


                     }

                 }
             }
         }
        
        
        for group in info.groups {
            if(group.users.count  != 0 ){
                for (key,value) in group.createdUsers{
                    for i in group.users {
                        let glued = group.id + i + key
                        let glued2 = group.id + key + i
                        if(helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]!) {

                            helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                            helper.matrix["\(glued2)"]! = 0

                        }
                        else {

                            helper.matrix["\(glued2)"]! -=   helper.matrix["\(glued)"]!
                            helper.matrix["\(glued)"]! = 0

                        }
                    }
                    
                    
                }
                
            }
        }
        

    
        for group in info.groups {
            if(group.users.count  != 0 ){
                for (key,value) in group.createdUsers{
                    for (key2,value2) in group.createdUsers {
                        let glued = group.id + key + key2
                        let glued2 = group.id + key2 + key
                        
                        if(helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]!) {

                            helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                            helper.matrix["\(glued2)"]! = 0

                        }
                        else {

                            helper.matrix["\(glued2)"]! -=   helper.matrix["\(glued)"]!
                            helper.matrix["\(glued)"]! = 0

                        }
                    }
                    
                    
                }
                
            }
        }
        
    
     }
    
    func smartTransferDebts(){
        
        for group in info.groups {
            if(group.users.count != 0){
                for i in group.users{
                    for j in group.users{
                        if j != i {
                            for k in group.users {
                                if(k != i && k != j){
                                    
                               
                                
                                let glued = group.id + i + j
                                let glued2 = group.id + j + k
                                let glued3 = group.id + i + k
                                
                                if helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]! {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued2)"]! = 0
                                    
                                }
                                    
                                else {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued2)"]! -= helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued)"]! = 0
                                    
                                }
                            }
                                
                                
                                
                                
                            }
                            
                            
                        }
                        
                        
                        
                    }
                }
                
            }
        }
        
        
        for group in info.groups {
            if(group.users.count != 0){
                for (i,value) in group.createdUsers{
                    for j in group.users{
                        if j != i {
                            for k in group.users {
                                if(k != i && k != j){
                                    
                               
                                
                                let glued = group.id + i + j
                                let glued2 = group.id + j + k
                                let glued3 = group.id + i + k
                                
                                if helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]! {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued2)"]! = 0
                                    
                                }
                                    
                                else {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued2)"]! -= helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued)"]! = 0
                                    
                                }
                            }
                                
                                
                                
                                
                            }
                            
                            
                        }
                        
                        
                        
                    }
                }
                
            }
        }
        for group in info.groups {
            if(group.users.count != 0){
                for (i,value) in group.createdUsers{
                    for j in group.users{
                        if j != i {
                            for (k,v) in group.createdUsers {
                                if(k != i && k != j){
                                    
                               
                                
                                let glued = group.id + i + j
                                let glued2 = group.id + j + k
                                let glued3 = group.id + i + k
                                
                                if helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]! {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued2)"]! = 0
                                    
                                }
                                    
                                else {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued2)"]! -= helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued)"]! = 0
                                    
                                }
                            }
                                
                                
                                
                                
                            }
                            
                            
                        }
                        
                        
                        
                    }
                }
                
            }
        }
        for group in info.groups {
            if(group.users.count != 0){
                for (i,value) in group.createdUsers{
                    for (j,value) in group.createdUsers{
                        if j != i {
                            for (k,v) in group.createdUsers {
                                if(k != i && k != j){
                                    
                               
                                
                                let glued = group.id + i + j
                                let glued2 = group.id + j + k
                                let glued3 = group.id + i + k
                                
                                if helper.matrix["\(glued)"]! > helper.matrix["\(glued2)"]! {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued)"]! -= helper.matrix["\(glued2)"]!
                                    
                                    helper.matrix["\(glued2)"]! = 0
                                    
                                }
                                    
                                else {
                                    
                                    helper.matrix["\(glued3)"]! += helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued2)"]! -= helper.matrix["\(glued)"]!
                                    
                                    helper.matrix["\(glued)"]! = 0
                                    
                                }
                            }
                                
                                
                                
                                
                            }
                            
                            
                        }
                        
                        
                        
                    }
                }
                
            }
        }
    }

}









