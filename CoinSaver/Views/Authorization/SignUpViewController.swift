//
//  SignUpViewController.swift
//  CoinSaver
//
//  Created by fiskirton on 13.11.2020.
//

import UIKit
import Firebase


class SignUpViewController: UIViewController {

    @IBOutlet weak var usernameInput: UITextField!
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var passwordInput: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign Up"
        usernameInput.delegate = self
        emailInput.delegate = self
        passwordInput.delegate = self
        
    }
    
    func showAlert(errorMessage: String){
        let alert = UIAlertController(title: "Ошибка", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: false, completion: nil)
    }
    
    func signingUp () -> Bool{
        let username = usernameInput.text!
        let email = emailInput.text!
        let password = passwordInput.text!
        //registration if all filelds are not empty
        if (!username.isEmpty && !email.isEmpty && !password.isEmpty){
            Auth.auth().createUser(withEmail: email, password: password, completion: { (result, error) in
                if error == nil{
                    if let result = result{
                        // if registration was OK
                        print (result.user.uid)
                        // append user to database
                        let dbref = Database.database().reference().child("user")
                        dbref.child(result.user.uid).updateChildValues(["login":username, "email":email])
                        BasicUserSettings.userEmail = email
                    }
                }else{
                    print ("error")
                    self.showAlert(errorMessage: "Проверьте подключение к интернету")
                    
                }
            })
        }else{
            showAlert(errorMessage: "Заполните все поля!")
        }
        return true
    }
    
    @IBAction func signUpAction(_ sender: Any) { 
        if signingUp() {
                self.performSegue(withIdentifier: "fromSignUp", sender: nil)
        }
    }

}

extension SignUpViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}
