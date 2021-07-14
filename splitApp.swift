//
//  splitApp.swift
//  split
//
//  Created by Andrei Giangu on 23.05.2021.
//
import UserNotifications
import SwiftUI
import Firebase
import FirebaseDynamicLinks
import GoogleSignIn
import FirebaseFirestore
import CryptoKit
import AuthenticationServices
@main
struct splitApp: App {
//    let persistenceController = PersistenceController.shared
    
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {

            ContentView(info: self.delegate)
                .onOpenURL { url in
                  print("Incoming URL parameter is: \(url)")
                  // 2
                  let linkHandled = DynamicLinks.dynamicLinks()
                    .handleUniversalLink(url) { dynamicLink, error in
                    guard error == nil else {
                      fatalError("Error handling the incoming dynamic link.")
                    }
                    // 3
                    if let dynamicLink = dynamicLink {
                      // Handle Dynamic Link
                        
                        delegate.dynamic = dynamicLink
                     
                    }
                  }
                  // 4
                  if linkHandled {
                    print("Link Handled")
                  } else {
                    print("No Link Handled")
                  }
                }
            
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

// App delegate...


class AppDelegate: NSObject, UIApplicationDelegate, GIDSignInDelegate, ObservableObject {
    @AppStorage("log_Status") var status = false
    @Published var email = ""
    @Published var isLoading = false
    @Published var userLog: User = User(id: "", email: "", nickname: "", profilePic: "", groups:[])
    @Published var payments = [Payment]()
    @Published var paymentsInGroup = [Payment]()
    @Published var usersInGroup = [User]()
    @Published var groups = [Event]()
    @Published var users = [User]()
    @Published var dynamic : DynamicLink!
    @Published var nonce = ""

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //initializing firebase
        FirebaseApp.configure()
        
        //initializing google
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        registerForPushNotifications()
        return true
    }
    
    
    func registerForPushNotifications() {
      //1
        UNUserNotificationCenter.current()
          .requestAuthorization(
            options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self?.getNotificationSettings()
          }
    }
    
    func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        print("Notification settings: \(settings)")
        guard settings.authorizationStatus == .authorized else { return }
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }
    
    
    func handleIncomingDynamicLink(_ dynamicLink: DynamicLink){
        guard let url = dynamicLink.url else {
            print("dynamic link has no url")
            return
        }
        print("incoming link parameter is \(url.absoluteString)")
        guard (dynamicLink.matchType == .unique || dynamicLink.matchType == .default) else {
            
            print("not a strong enough match type to continue")
            return
        }
        
        //parse the link paramter
        
        guard let components = URLComponents(url:url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {return}
        if components.path == "/group" {
            if let groupIDQueryItem = queryItems.first(where: {$0.name == "groupID"}) {
                guard let groupID = groupIDQueryItem.value else {return}
                let Userid = Auth.auth().currentUser?.uid
                let db = Firestore.firestore()
                let docRef = db.collection("groups").document("\(groupID)")
            print("\(groupID)")
                docRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        
                       
                        
                        docRef.updateData(["users": FieldValue.arrayUnion(["\(Userid ?? "")"])])
                        
                        let docRef2 = db.collection("users").document("\(Userid ?? "")")
                        
                        docRef2.updateData(["groups": FieldValue.arrayUnion(["\(groupID)"])])
                        
                        
                    } else {
                        print("Document does not exist")
                    }
                }
                
                
                
                
                
            
            }
            
            
        }
    }
    
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!){
        
        
        guard let user = user else {
            
            print(error.localizedDescription)
            
            return}
        
        let credential = GoogleAuthProvider.credential(withIDToken: user.authentication.idToken, accessToken: user.authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { [self]
            (result, err) in
            
            if err != nil{
                print((err?.localizedDescription)!)
                return
            }
          
            
            
            withAnimation{isLoading = true}
            self.email = (result?.user.email)!
       
            
                let db = Firestore.firestore()
                let Userid = Auth.auth().currentUser?.uid
                let newDocument = db.collection("users").document("\(Userid ?? "")")
                newDocument.setData(["id" : "\(newDocument.documentID)", "email": "\(self.email)"], merge: true)
                            
        
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            fetchData()
            
            dispatchGroup.leave()
            
            dispatchGroup.notify(queue:.main){
            
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation{isLoading = false}
                self.status = true
                   
                }
            }
           
        }
   
    }
    
    
    func authenticate(credential: ASAuthorizationAppleIDCredential){
        
        // getting Token....
        guard let token = credential.identityToken else{
            print("error with firebase")
            
            return
        }
        
        // Token String...
        guard let tokenString = String(data: token, encoding: .utf8) else{
            print("error with Token")
            return
        }
        
        let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString,rawNonce: nonce)
        
        Auth.auth().signIn(with: firebaseCredential) { (result, err) in
            
            if let error = err{
                print(error.localizedDescription)
                return
            }
            
        
            
            withAnimation{self.isLoading = true}
            self.email = (result?.user.email) ?? ""
       
            
                let db = Firestore.firestore()
                let Userid = Auth.auth().currentUser?.uid
                let newDocument = db.collection("users").document("\(Userid ?? "")")
                newDocument.setData(["id" : "\(newDocument.documentID)", "email": "\(self.email)"], merge: true)
                            
        
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            self.fetchData()
            
            dispatchGroup.leave()
            
            dispatchGroup.notify(queue:.main){
            
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    withAnimation{self.isLoading = false}
                self.status = true
                   
                }
            }
            
            
        }
    }
    
    
    
    func fetchData(){
        let db = Firestore.firestore()
      
        
        if(Auth.auth().currentUser != nil)
        
        {
        
            
        db.collection("users").document( "\(Auth.auth().currentUser?.uid ?? "")").addSnapshotListener { [self]documentSnapshot, error in
            
            guard let document = documentSnapshot else {
                print("error fetching document: \(error)")
                return
            }
            
            do{
                
                if(document.data() != nil){
           try self.userLog  = document.data(as: User.self)!
               
            }
                else {
                    fetchData()
                }
            }
           
            catch _ {
                
                print("error")
            }
                      
            
            }
               
        }
    }
    
    
    
    func fetchGroups(){
        
        
        
        
        let db = Firestore.firestore()
        
        if(Auth.auth().currentUser != nil){
            let userID = Auth.auth().currentUser?.uid
            db.collection("groups")
                .whereField("users", arrayContains: "\(userID ?? "")").addSnapshotListener {(querrySnapshot, error) in
                    guard let documents = querrySnapshot?.documents else {
                        print ("no groups")
                        return
                    }
                    
                    self.groups = documents.compactMap { queryDocumentSnapshot in
                        try? queryDocumentSnapshot.data(as:Event.self)
                    }
                }
            
            
        }
    }
    


    
    
    func fetchUsers(groupID:String){
        
        let db = Firestore.firestore()
        
        
        if(Auth.auth().currentUser != nil){
            
          
          
            db.collection("users").whereField("groups",arrayContains: groupID).addSnapshotListener {(querrySnapshot, error) in
                guard let documents = querrySnapshot?.documents else {
                    
                    print ("no users")
                    return
                }
                self.usersInGroup = documents.compactMap { queryDocumentSnapshot in
                    try? queryDocumentSnapshot.data(as:User.self)
            }
           
        }
            
            
            
 }}
    
    
    func fetchPayments(groupID:String){
        
        let db = Firestore.firestore()
        
        
        if(Auth.auth().currentUser != nil){
            
          
          
            db.collection("payments").whereField("group",isEqualTo: groupID).addSnapshotListener {(querrySnapshot, error) in
                guard let documents = querrySnapshot?.documents else {
                    
                    print ("no users")
                    return
                }
                self.paymentsInGroup = documents.compactMap { queryDocumentSnapshot in
                    try? queryDocumentSnapshot.data(as:Payment.self)
            }
           
        }
 }}
    
    
    
    func fetchAllPayments(){

        let db = Firestore.firestore()
        var combined = [Payment]()
        
        let userID = Auth.auth().currentUser?.uid
        
        
        if(Auth.auth().currentUser != nil){
           
            for i in groups.indices{
            db.collection("payments")
                .whereField("group", isEqualTo: groups[i].id).addSnapshotListener {[self](querrySnapshot, error) in
                    guard let documents = querrySnapshot?.documents else {
                        print ("no payments")
                        return
                    }
                    
                   combined = documents.compactMap { queryDocumentSnapshot in
                        try? queryDocumentSnapshot.data(as:Payment.self)
                    }
                    
                    for i in combined{
                        for j in payments {
                            if i.id == j.id {
                                let itemIndex = self.payments.firstIndex(of:j)
                                payments.remove(at: itemIndex!)
                            }
                            
                        }
                    }
                    
                    payments.append(contentsOf: combined)
                    payments = Array(payments.uniqued())
                    
                }
            
            }
        }

    }
    
    func fetchAllUsers(){
        
        let db = Firestore.firestore()
 
        var combined = [User]()
        if(Auth.auth().currentUser != nil){
  
            
            for i in groups.indices{
          
                db.collection("users").whereField("groups",arrayContains: groups[i].id).addSnapshotListener { [self](querrySnapshot, error) in
                guard let documents = querrySnapshot?.documents else {
                    
                    print ("no users")
                    return
                }
               combined = documents.compactMap { queryDocumentSnapshot in
                    try? queryDocumentSnapshot.data(as:User.self)
            }
                    
                   
                    for i in combined{
                       for j in users {
                            if i.id == j.id {
                                let itemIndex = self.users.firstIndex(of: j)
                                users.remove(at: itemIndex!)
  
                            }
                        }
                        
                    }
                    users.append(contentsOf: combined)
                    users = Array(users.uniqued())
                    
                    
   }
       
}
           
            
 }}
    
    
    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
      let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
      let token = tokenParts.joined()
      print("Device Token: \(token)")
    }
    
    
    func application(
      _ application: UIApplication,
      didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
      print("Failed to register: \(error)")
    }
        
    }
    
    
    




//swipe back gesture

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}



extension Array {
    
    func chunked(by distance: Int) -> [[Element]] {
        let indicesSequence = stride(from: startIndex, to: endIndex, by: distance)
        let array: [[Element]] = indicesSequence.map {
            let newIndex = $0.advanced(by: distance) > endIndex ? endIndex : $0.advanced(by: distance)
            //let newIndex = self.index($0, offsetBy: distance, limitedBy: self.endIndex) ?? self.endIndex // also works
            return Array(self[$0 ..< newIndex])
        }
        return array
    }
    
}

func combine<T>(_ arrays: Array<T>?...) -> Set<T> {
    return arrays.compactMap{$0}.compactMap{Set($0)}.reduce(Set<T>()){$0.union($1)}
}


extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}


// helpers for Apple Login With Firebase...

 func sha256(_ input: String) -> String {
  let inputData = Data(input.utf8)
  let hashedData = SHA256.hash(data: inputData)
  let hashString = hashedData.compactMap {
    return String(format: "%02x", $0)
  }.joined()

  return hashString
}

 func randomNonceString(length: Int = 32) -> String {
  precondition(length > 0)
  let charset: Array<Character> =
      Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
  var result = ""
  var remainingLength = length

  while remainingLength > 0 {
    let randoms: [UInt8] = (0 ..< 16).map { _ in
      var random: UInt8 = 0
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
      if errorCode != errSecSuccess {
        fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
      }
      return random
    }

    randoms.forEach { random in
      if remainingLength == 0 {
        return
      }

      if random < charset.count {
        result.append(charset[Int(random)])
        remainingLength -= 1
      }
    }
  }

  return result
}


