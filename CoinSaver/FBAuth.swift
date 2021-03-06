//
//  firebasefuncs.swift
//  CoinSaver
//
//  Created by administrator on 16/12/2020.
//

import Foundation
import Firebase

struct Goal{
    var name: String
    var categories: [String]
    var limit:Int
}
struct CoinUser: Codable{
    var balance: Int
    var categories: [String]
    var FundsHistory: [String:Int]
    var SpendingHistory: [String:Int]
    var CategoryHistory: [String:[String: Int]]
    var Goals: [String:[String:Int]]
}

extension Date {
   func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}

class FDatabase {
    var userdbref = Database.database().reference().child("users")
    var email = ""
    let datef = DateFormatter()
    var user: CoinUser?
    
    private static var INSTANCE: FDatabase! = nil
    
    static func getInstance() -> FDatabase {
        if (INSTANCE == nil) {
            INSTANCE = FDatabase(email: BasicUserSettings.userEmail)
        }
        return INSTANCE
    }
    
    init(email: String){
        self.email = email.replacingOccurrences(of: ".", with:"*")
        userdbref = userdbref.child(self.email)
        fetchData()
    }
    
    func fetchData() -> CoinUser?{
        guard let url = URL(string: "https://coinsaver-b197b.firebaseio.com/users/\(email).json") else
        {
            return nil
        }
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) -> Void in
            if error == nil && data != nil {
                do {
                    let json = try JSONDecoder().decode(CoinUser.self, from: data!)
                    self.user = json
                } catch {
                    print("\(error)")
                }
            }
            else if error != nil
            {
                print(error)
            }
            }).resume()
        return self.user
    }
    func getDateString() -> String{
        let date = Date()
        return date.getFormattedDate(format: "yyyy-MM")
    }
    func getDateString(drom date: Date)->String{
        datef.dateFormat = "yyyy-MM"
        return datef.string(from: date)
    }
    func setInfo(categories: [String], startBudget: Int){
        user = CoinUser(balance: 0, categories: categories, FundsHistory: [getDateString():0], SpendingHistory: [getDateString():0], CategoryHistory: [getDateString():[:]], Goals: ["Empty" : ["Empty" : 0]])
        user?.categories.forEach({ (ctg) in
            user?.CategoryHistory[getDateString()]?[ctg] = 0
     
        })
        userdbref.child("categories").setValue(categories)
        userdbref.child("balance").setValue(0)
        userdbref.child("FundsHistory").setValue(user?.FundsHistory)
        userdbref.child("SpendingHistory").setValue(user?.SpendingHistory)
        userdbref.child("CategoryHistory").setValue(user?.CategoryHistory)
        userdbref.child("Goals").setValue(user?.Goals)
        upBalance(sum: startBudget)
    }
    func setUsername(name: String){
        userdbref.child("login").setValue(name)
    }
    func upBalance(sum: Int){
        fetchData()
        let current = user?.balance ?? 0
        user?.balance = current+sum
        userdbref.child("balance").setValue(current+sum)
        let strdate = getDateString()
        user?.FundsHistory[strdate]! += sum
        userdbref.child("FundsHistory").setValue(user?.FundsHistory)
    }
    func setGoal(goal: Goal){
        user?.Goals[goal.name] = [goal.categories.joined(separator: " "):goal.limit]
        userdbref.child("Goals").setValue(user?.Goals)
    }
    func spend(category: String, sum: Int){
        fetchData()
        let curr = user?.balance ?? 0
        user?.balance = curr - sum
        userdbref.child("balance").setValue(user?.balance)
        let strdate = getDateString()
        user?.SpendingHistory[strdate]! += sum
        user?.CategoryHistory[strdate]![category]? += sum 
        userdbref.child("SpendingHistory").setValue(user?.SpendingHistory)
        userdbref.child("CategoryHistory").setValue(user?.CategoryHistory)
    }
    func getBalance() -> Int{
        return user?.balance ?? 0
    }
    func getTotalSpendings() -> Int{
        let strdate = getDateString()
        return user?.SpendingHistory[strdate] ?? 0
    }
    func getTotalFunds() -> Int{
        let strdate = getDateString()
        return user?.FundsHistory[strdate] ?? 0
    }
    func getTotalSpendings(date: String) -> Int{
        return user?.SpendingHistory[date] ?? 0
    }
    func getTotalFunds(date: String) -> Int{
        return user?.FundsHistory[date] ?? 0
    }
    func getSpendingRate() -> [String:Int]{
        fetchData()
        return user?.CategoryHistory[self.getDateString()] ?? [:]
    }
    func getOrderedSpendingRate(date: String) -> [String:Int]{ //return 3 top spendings
        fetchData()
        let categspendings = user?.CategoryHistory[date] ?? [:]
        var categs = Array(categspendings.keys)
        var topcategs = categs.sort(by: {(s1, s2) in
            if (categspendings[s1]! > categspendings[s2]!){
                return true
            }
            else{
                return false
            }
        })
        var toresult:[String:Int] = [:]
        var limit = 3
        categs.forEach({(item) in
            if (limit > 0){
                toresult[item] = categspendings[item]
                limit -= 1
            }
        })
        return toresult
    }
    func getGoals() -> [Goal]{
        fetchData()
        let goalsdb = user?.Goals
        var retvaluse: [Goal] = []
        goalsdb?.forEach({ (key: String, value: [String : Int]) in
            let cats = Array(value.keys)[0]
            retvaluse.append(Goal(name: key, categories: cats.split(separator: " ").map({t in String(t)}), limit: value[cats]!))
        })
        return retvaluse
    }
    func getCategories() -> [String]{
        fetchData()
        return user?.categories ?? []
    }
}
