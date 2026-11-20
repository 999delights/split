//
//  ImagePicker.swift
//  split
//
//  Created by Andrei Giangu on 31.05.2021.
//

import UIKit
import SwiftUI
import FirebaseStorage
import Firebase


struct ImagePickerView: UIViewControllerRepresentable {

   
//    @Binding var selectedImage: Data
    @Environment(\.presentationMode) var isPresented
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
        
    func makeUIViewController(context: Context) -> UIImagePickerController {
        
        
        let imagePicker = UIImagePickerController()
 
        imagePicker.sourceType = self.sourceType
        if(imagePicker.sourceType == .camera){
            imagePicker.cameraDevice = .front}
        
        imagePicker.delegate = context.coordinator // confirming the delegate
        return imagePicker
        
        
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {

    }

    // Connecting the Coordinator class with this struct
    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self)
    }
    
    
    }

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var picker: ImagePickerView
    init(picker: ImagePickerView) {
        self.picker = picker
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
     
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
//        self.picker.selectedImage = selectedImage.jpegData(compressionQuality: 0.35)
        
        self.picker.image = selectedImage
        self.picker.isPresented.wrappedValue.dismiss()
        
        

    }
    
}

func loadUserImage(image:UIImage?){
    
    if(Auth.auth().currentUser != nil)
    {
        
        if image != nil {
    let id = Auth.auth().currentUser?.uid
    
    let storage = Storage.storage().reference()
            storage.child("\(id ?? "")").putData(image!.jpegData(compressionQuality: 0.35)!, metadata: nil){
        (_, err) in
        
        if err != nil {
            print((err?.localizedDescription)!)
            return
        }
        
        storage.child("\(id ?? "")").downloadURL{
            (url,err) in
            
            if err != nil {
                print((err?.localizedDescription)!)
                return
            }
            
            let db = Firestore.firestore()
            
            db.collection("users").document("\(id ?? "")").setData(["profilePic": "\(url!)"],merge:true)
        }
       
    }
        }
    }
}

func loadGroupImage(image:UIImage?, groupID: String){
    
    
    if(Auth.auth().currentUser != nil)
    {
        
        if image != nil {
  
    
    let storage = Storage.storage().reference()
            storage.child("\(groupID)").putData(image!.jpegData(compressionQuality: 0.35)!, metadata: nil){
        (_, err) in
        
        if err != nil {
            print((err?.localizedDescription)!)
            return
        }
        
        storage.child("\(groupID)").downloadURL{
            (url,err) in
            
            if err != nil {
                print((err?.localizedDescription)!)
                return
            }
            
            let db = Firestore.firestore()
            
            db.collection("groups").document("\(groupID)").setData(["profilePic": "\(url!)"],merge:true)
        }
       
    }
        }
    }
    
}

