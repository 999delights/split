//
//  helper.swift
//  split
//
//  Created by Andrei Giangu on 26.05.2021.
//

import Foundation
import SwiftUI
import UIKit

struct CustomTextField: View {
    
    
    @Binding var value: String
    var hint: String
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 6, content: {
            Text("\(hint)")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.leading,20)
                .padding(.trailing,20)
            ZStack{
                
                if hint == "User Name" {
            TextField("example@gmail.com", text: $value)
                
                }
                
                else {
            SecureField("********", text: $value)
             
                    
                }
            }.padding(.vertical, 15)
            .padding(.horizontal)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(10)
            .padding(.leading,20)
            .padding(.trailing,20)
          
        
            
            
        })
    }
}



struct CustomTextField2: View {
    var placeholder: Text
    @Binding var text: String
    var editingChanged: (Bool)->() = { _ in }
    var commit: ()->() = { }

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty { placeholder }
        
            TextField("", text: $text, onEditingChanged: editingChanged, onCommit: commit)
            
              
          
            }
        }
    
    }




//keyboard type- all

struct FirstResponderTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder : String
    var color: UIColor
    var size: CGFloat
    class Coordinator: NSObject, UITextFieldDelegate{
        
        @Binding var text: String
       
        var becameFirstResponder = false
        
        init(text: Binding<String>)
        {self._text = text }
        
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }
    }
    
    func makeCoordinator() -> Coordinator{
        return Coordinator(text: $text)
    }
    
    
 
    
    func makeUIView(context: Context) -> some UIView {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.textColor = color
        textField.font = UIFont.boldSystemFont(ofSize: size)
        textField.placeholder = placeholder

        return textField
        
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if !context.coordinator.becameFirstResponder {
            
            uiView.becomeFirstResponder()
            context.coordinator.becameFirstResponder = true
        }
    }
}



//keyboard type - numeric
struct FirstResponderTextField2: UIViewRepresentable {
    @Binding var text: String
    let placeholder : String
    class Coordinator: NSObject, UITextFieldDelegate{
        
        @Binding var text: String
       
        var becameFirstResponder = false
        
        init(text: Binding<String>)
        {self._text = text }
        
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
            
        }
    }
    
    func makeCoordinator() -> Coordinator{
        return Coordinator(text: $text)
    }
    
    
 
    
    func makeUIView(context: Context) -> some UIView {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.textColor = UIColor.purple
        textField.font = UIFont.boldSystemFont(ofSize: 26.0)
        textField.keyboardType = UIKeyboardType.decimalPad
       
     
       
          
        
        return textField
        
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if !context.coordinator.becameFirstResponder {
            
            uiView.becomeFirstResponder()
            context.coordinator.becameFirstResponder = true
        }
    }
}







//extension UITextField {
//
//    func underlined(){
//            let border = CALayer()
//        border.bounds = CGRect(x: 0, y: 0, width:  self.frame.size.width, height: self.frame.size.height)
//            let width = CGFloat(1.0)
//        border.borderColor = UIColor.black.cgColor
//            border.frame = CGRect(x: 0, y: self.frame.size.height - width, width:  self.frame.size.width, height: self.frame.size.height)
//            border.borderWidth = width
//            self.layer.addSublayer(border)
//            self.layer.masksToBounds = true
//        }
//}







//get the keyboard height

class KeyboardHeightHelper: ObservableObject{
    
    @Published var keyboardHeight: Bool = false
     
    init() {
        self.listenForKeyboardNotifications()
        
    }
    
    private func listenForKeyboardNotifications(){
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main ) { (notification) in
            
            
            self.keyboardHeight = true
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil, queue: .main) { (notification) in
            self.keyboardHeight = false
        }
    }
        
}






