//
//  helper.swift
//  split
//
//  Created by Andrei Giangu on 08.06.2021.
//

import Foundation
import SwiftUI
import FirebaseDynamicLinks

class Helper: ObservableObject{
    @Published var showPayment = false
    @Published var currentTab = "house"
    @Published var indexPayment : Int? = nil
    @Published var confirmPaid = false
    @Published var confirmPaid2 = false
    @Published var matrix =   [ String : Double ] ()
    @Published var to = ""
    @Published var tofrom = ""
    @Published var groupName = ""
    @Published var sum : Double = 0
    @Published var isLoading = false
    
    
    func getGiveOrTake(glued: String, glued2: String) -> [String:String] {
        var text : String = ""
        var double : String = ""
        let matrix = matrix
        var info  = [ text : double ]
        
       
            
            if matrix.count != 0 {
                
                
          
         if matrix["\(glued2)"]! > matrix["\(glued)"]! {
            text = "is owed"
            double = String(Double(Double(matrix["\(glued2)"]! - matrix["\(glued)"]!).clean2)!.clean2)
            if Double(double)! < 0.9 {
                text = "we good"
                double = ""
            }
            info  = ["\(text)": double]
        }
        
                if matrix["\(glued)"]! > matrix["\(glued2)"]! {
            text = "owes you"
                double = String(Double(Double(matrix["\(glued)"]! - matrix["\(glued2)"]!).clean2)!.clean2)
                if Double(double)! < 0.9 {
                    text = "we good"
                    double = ""
                }
            info  = ["\(text)": double ]
        }
        
         if matrix["\(glued)"] == matrix["\(glued2)"]
        {
            text = "we good"
            double = ""
             info  = ["\(text)": double]
        }
        
            }
    return info
    }
    
    
    func getOWEorOWEDperGroup(groupID: String, myID: String, usersInGroup:Event) -> [String:String]{
        var text = ""
        var double = ""
        var toShow = [text:double]
        var toGive : Double = 0
        var toTake : Double = 0
        
        for (key,value) in matrix {
            for userID in usersInGroup.users {
                let search1 = groupID + myID + userID
                let search2 = groupID + userID + myID
                if key == search1
                {
                    toGive += value
                }
                
                if key == search2 {
                    
                    toTake += value
                }
            }
            for (k,v) in usersInGroup.createdUsers {
                let search1 = groupID + myID + k
                let search2 = groupID + k + myID
                
                if key == search1
                {
                    toGive += value
                }
                
                if key == search2 {
                    
                    toTake += value
                }
            }
            
            
            
            
        }
        
        if toGive > toTake {
            double = String(Double(Double(toGive - toTake).clean2)!.clean2)
            text = "You owe"
            
            if Double(double)! < 0.5 {
                text = "we good"
                double = "settled"
            }
          
            toShow = [text:double]
        }
        
        if toTake > toGive {
            
            double = String(Double(Double(toTake - toGive).clean2)!.clean2)
            text = "You're owed"
            
            if Double(double)! < 0.5 {
                text = "we good"
                double = "settled"
            }
            toShow = [text:double]
            
        }
        
        if toTake == toGive {
            text = "we good"
            double = "settled"
            
            
            toShow = [text:double]
        }
        
        
        
        return toShow
    }
  
    func getTotalSpent(groupID:String, userID:String, payments: [Payment] ) -> String {
        var sum1 = ""
        var sum : Double = 0
        for payment in payments{
            
            for (key,value) in payment.split{
                if key == userID{
               if value != ""
               {
                    
                sum += Double(Double(payment.split[key]!)!.clean2)!
                    
               }
                }
                
            }
           
            
            
            
        }
        
        
            sum1 = String(Double(Double(sum).clean2)!.clean2)
       
        return sum1
    }

    func getOWEorOWED(groups:[Event], myID: String, users:[User]) -> [String:String]{
        var text = ""
        var double = ""
        var toShow = [text:double]
        var toGive : Double = 0
        var toTake : Double = 0
        
        
        for (key,value) in matrix {
            for group in groups {
                for user in users {
                    let search1 = group.id + myID + user.id
                    let search2 = group.id + user.id + myID
                    
                    if key == search1
                    {
                        toGive += value
                    }
                    
                    if key == search2 {
                        
                        toTake += value
                    }
                    
                }
                
                for (k,v) in group.createdUsers {
                    let search1 = group.id + myID + k
                    let search2 = group.id + k + myID
                    
                    if key == search1
                    {
                        toGive += value
                    }
                    
                    if key == search2 {
                        
                        toTake += value
                    }
                }
                
                
                
            }
            
            
            
            
            
            
        }
        
        if toGive > toTake {
            double = String(Double(Double(toGive - toTake).clean2)!.clean2)
            text = "You owe"
           
            
            if Double(double)! < 0.5 {
                text = "we good"
                double = "settled"
            }
            
            toShow = [text:double]
        }
        
        if toTake > toGive {
            
            double = String(Double(Double(toTake - toGive).clean2)!.clean2)
            text = "You're owed"
            
            
            if Double(double)! < 0.5 {
                text = "we good"
                double = "settled"
            }
            
            toShow = [text:double]
        }
        
        if toTake == toGive {
            text = "we good"
            double = "settled"
            toShow = [text:double]
        }
        
        
        
        return toShow
    }
    
    
    func getShortDate(date: Date) -> String {
        
        let formatter = DateFormatter()
         formatter.dateStyle = .short
         formatter.timeStyle = .short
        
        let datetime = formatter.string(from: date)
  
        return datetime
    }

    
    func getSplitSum(split: [String:String]) -> Double {
        var sum :Double = 0
        
        for (_,v) in split {
            if(v != "") {
                sum += Double(v) ?? 0
                
            }
            
        }
        return sum
    }
    
    func getNumberToggled(isToggled: [String:Bool]) -> Int {
        var number = 0
        for (_,v) in isToggled {
            if v == true {
                number += 1
            }
        }
        
        return number
    }
    
    
    func totalGivePerPayment(payments: [Payment],userID: String, paymentID: String) -> String{
        var sum : Double = 0
        var ret : String = "0"
        
        for index in payments.indices {
            if(payments[index].id == paymentID) {
                
                for (key,value) in payments[index].split {
                    if key != userID {
                        if(value != ""){
                            sum += Double(value)!
                            
                               }
                            }
                        }
                   }
            }
        
        ret = String(sum)
        ret = String(Double(ret.doubleValue).clean2)
        
        if(Double(ret) != 0){
            
            return ret
        }
        
        return "0"
        
        
    }
    
    
    

    
    
    
    
    
    
    func find(value searchValue: String, in array: [Event]) -> Int?
    {
        for (index, value) in array.enumerated()
        {
            if value.id == searchValue {
                return index
            }
        }

        return nil
    }
    
    
    func find3(value searchValue: String, in array: [User]) -> Int?
    {
        for (index, value) in array.enumerated()
        {
            if value.id == searchValue {
                return index
            }
        }

        return nil
    }
    
    
    func find2(value searchValue: String, in array: [Payment]) -> Int?
    {
        for (index, value) in array.enumerated()
        {
            if value.id == searchValue {
                return index
            }
        }

        return nil
    }

    
    
    func groupInvite(groupID: String,title:String) {
        var components = URLComponents()
        
        components.scheme = "https"
        components.host = "www.exemple.com"
        components.path = "/group"
        
        
        let groupIDQuerryItem = URLQueryItem(name: "groupID", value: groupID)
        components.queryItems = [groupIDQuerryItem]
        
        guard let linkParameter = components.url else {return}
        print("I am sharing \(linkParameter.absoluteString)")
        
        
        
        guard let shareLink = DynamicLinkComponents.init(link: linkParameter, domainURIPrefix: "https://splitpaper.page.link") else {
            print("Couldn't create FDL components")
            return
        }
        
        if let myBundleId = Bundle.main.bundleIdentifier{
            shareLink.iOSParameters = DynamicLinkIOSParameters(bundleID: myBundleId)
        }
        
        shareLink.iOSParameters?.appStoreID = "962194608"
        shareLink.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        shareLink.socialMetaTagParameters?.title = "\(title)"
        
        guard let longURL = shareLink.url else {return}
        
        print("the long url is \(longURL)")
        
        shareLink.shorten {
             (url, warnings, error) in
            
            if let error = error {
                print ("error \(error)")
                return
            }
            if let warnings = warnings {
                for warning in warnings {
                    print("FDL Warning \(warning)")
                }
            }
            
            guard let url = url else {return}
            print ("short URL \(url.absoluteString)")
            
            self.showShareSheet(url: url)
        }
    }
    
    
    
    func showShareSheet(url:URL){
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController!.present(activityController, animated: true, completion: nil)
    }
    
    
}








