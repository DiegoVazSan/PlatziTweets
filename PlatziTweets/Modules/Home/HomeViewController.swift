//
//  HomeViewController.swift
//  PlatziTweets
//
//  Created by Diego on 04/07/21.
//

import UIKit
import Simple_Networking
import SVProgressHUD
import NotificationBannerSwift
import AVFoundation
import MobileCoreServices
import AVKit


class HomeViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet weak var principalHomeTable : UITableView!
    @IBOutlet weak var newTweetButton : UIButton!
    // MARK: - Properties
    private let cellId = "TweetTableViewCell"
    private var dataSource = [Post]()
    let emailKey = "email-key"
    let storage = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        getPost()
        principalHomeTable.reloadData()
    }
    private func setupUI(){
        //1- Asignar Data Source
        //2- Registrar Celda
        principalHomeTable.dataSource = self
        principalHomeTable.delegate = self
        principalHomeTable.register(UINib(nibName: cellId, bundle: nil), forCellReuseIdentifier: cellId)
        newTweetButton.layer.cornerRadius = 7
    }
    private func getPost(){
        //1- Indicar carga al usuario
        SVProgressHUD.show()
        //2- Consumir el Servicio
        SN.get(endpoint: EndPoints.getPosts) {(response: SNResultWithEntity<[Post], ErrorResponse>) in
            SVProgressHUD.dismiss()
            switch response {
            case .success(let posts):
                self.dataSource = posts
                self.principalHomeTable.reloadData()
            case .error(let error):
                NotificationBanner(title: "Error",
                                   subtitle: error.localizedDescription,
                                   style: .danger).show()
                
            case .errorResult(let entity):
                NotificationBanner(title: "Error",
                                   subtitle: entity.error,
                                   style: .warning).show()
            }
        }
    }
    private func deletePostAt(indexPath: IndexPath){
        SVProgressHUD.show()
        //1- Obtener ID del post que vamos a borrar
        let postId = dataSource[indexPath.row].id
        //2- Preparamos el endpoint que vamos a borrar
        let endpoint = EndPoints.delete + postId
        //3- Consumir el servicio que vamos a borrar
        SN.delete(endpoint: endpoint) { ( response: SNResultWithEntity<GeneralResponse, ErrorResponse>) in
            SVProgressHUD.dismiss()
            switch response {
            case .success:
                //1- Borrar el post del datasource (nuestro arreglo)
                self.dataSource.remove(at: indexPath.row)
                //2- Borrar la celda de la tabla
                self.principalHomeTable.deleteRows(at: [indexPath], with: .fade)
            case .error(let error):
                NotificationBanner(title: "Error",
                                   subtitle: error.localizedDescription,
                                   style: .danger).show()
                
            case .errorResult(let entity):
                NotificationBanner(title: "Error",
                                   subtitle: entity.error,
                                   style: .warning).show()
            }
        }
    }
}
//MARK: -UITableViewDataSource
extension HomeViewController : UITableViewDataSource {
    //Numero total de celdas
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    // Configurar celda deseada
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = principalHomeTable.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        if let newCell = cell as? TweetTableViewCell {
            //         configurar la celda
            newCell.setupCellWith(post: dataSource[indexPath.row])
            
            newCell.needsToShowVideo = { url in 
                let avPlayer = AVPlayer(url: url)
                let avPlayerController = AVPlayerViewController()
                avPlayerController.player = avPlayer
                self.present(avPlayerController, animated: true) {
                    avPlayerController.player?.play()
                }
            }
        }
        cell.selectionStyle = .none
        return cell
    }
}
//MARK: -UITableViewDelegate

extension HomeViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Borrar") { (_, _) in
            self.deletePostAt(indexPath: indexPath)
        }
        return [deleteAction]
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let mailUser = UserDefaults.standard.object(forKey: "emailUser") else { return false }
        if mailUser as! String == dataSource[indexPath.row].author.email {
            return dataSource[indexPath.row].author.email == dataSource[indexPath.row].author.email
        } else {
            return false
        }
    }
}

extension HomeViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//      Validar que el segue sea el esperado
        if segue.identifier == "ShowMap", let mapViewController = segue.destination as? MapViewController {
            mapViewController.post = dataSource.filter { $0.hasLocation }
    }
  }
}
