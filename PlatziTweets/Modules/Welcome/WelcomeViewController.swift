//
//  WelcomeViewController.swift
//  PlatziTweets
//
//  Created by Diego on 04/07/21.
//

import UIKit

class WelcomeViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    private func setupUI() {
        loginButton.layer.cornerRadius = 25
    }
}
