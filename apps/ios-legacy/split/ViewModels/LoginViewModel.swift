//
//  LoginViewModel.swift
//  split
//
//  Created by Andrei Giangu on 23.05.2021.
//

import SwiftUI
import Firebase

class LoginViewModel: ObservableObject{
    @Published var signinmail = false
    @Published var signupmail = false
    @Published var login = false
    //Login Properties
    
    @Published var email = ""
    @Published var password = ""
    
    
    // Register Properties

    @Published var newEmail = ""
    @Published var registerPassword = ""
    @Published var reEnterPassword = ""
    
    
    // Loading Screen
    
    @Published var isLoading = false
    
     
    //error
    @Published var errorMsg = ""
    @Published var error = false
    
    @AppStorage("log_Status") var status  = false
    
    
    
    func resetPassword(){
        
        
        Auth.auth().sendPasswordReset(withEmail: email) {[self] (err) in
            if let error = err{
                
                errorMsg = error.localizedDescription
                self.error.toggle()
                return
            }
            
            errorMsg = "Reset link sent successfully"
            error.toggle()
        }
    }
    
    

}




