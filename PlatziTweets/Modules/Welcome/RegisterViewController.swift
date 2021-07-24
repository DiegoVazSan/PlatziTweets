//
//  RegisterViewController.swift
//  PlatziTweets
//
//  Created by Diego on 29/06/21.
//

import UIKit
import NotificationBannerSwift
import Simple_Networking
import SVProgressHUD

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var RegisterButton: UIButton!
    @IBOutlet weak var emailTextField : UITextField!
    @IBOutlet weak var passwordTextField : UITextField!
    @IBOutlet weak var nameTextField : UITextField!
    
    @IBAction func registerButton () {
        view.endEditing(true)
        performRegister()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI(){
        RegisterButton.layer.cornerRadius = 25
    }
    
    private func performRegister() {
        guard let email  = emailTextField.text, !email.isEmpty else {
            NotificationBanner(title: "Error", subtitle: "Debes Especificar un Correo", style: BannerStyle.warning).show()
            return
        }
                guard let password  = passwordTextField.text, !password.isEmpty else {
                    NotificationBanner(title: "Error", subtitle: "Debes Especificar una Contrasena", style: BannerStyle.warning).show()
                    return
            }
        guard let names  = nameTextField.text, !names.isEmpty else {
            NotificationBanner(title: "Error", subtitle: "Debes Especificar tu Nombre y Apellido", style: BannerStyle.warning).show()
            return
    }
        /*CREAR REQUEST*/
        let request = RegisterRequest(email: email, password: password, names: names)
    /*   INDICAR CARGA AL USUARIO   */
        SVProgressHUD.show()
        /*   LLAMAR AL SERVICIO   */
        SN.post(endpoint: EndPoints.register, model: request) { ( response: SNResultWithEntity<LoginResponse, ErrorResponse>) in
            /*   CERRAMOS LA CARGA AL USUARIO   */
            SVProgressHUD.dismiss()
                        switch response {
                        case .success(let user):
//          todo lo bueno
                            NotificationBanner( subtitle: "Bienvenido \(user.user.names)", style: BannerStyle.success).show()
                            self.performSegue(withIdentifier: "showHome", sender: nil)
                            SimpleNetworking.setAuthenticationHeader(prefix: "", token: user.token)
                        case .error(let error):
//           todo lo malo
                            NotificationBanner(title:error.localizedDescription, style: BannerStyle.danger).show()
                        return
                        case .errorResult(let entity):
//           error, pero no tan malo
                            NotificationBanner(title:"Error", subtitle: entity.error, style: BannerStyle.warning).show()
                        }
            }
       }
}
