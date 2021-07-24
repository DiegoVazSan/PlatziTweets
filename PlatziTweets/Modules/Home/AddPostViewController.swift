//
//  AddPostViewController.swift
//  PlatziTweets
//
//  Created by Diego on 05/07/21.
//

import UIKit
import Simple_Networking
import NotificationBannerSwift
import SVProgressHUD
import FirebaseStorage
import AVFoundation
import AVKit
import MobileCoreServices
import CoreLocation

class AddPostViewController: UIViewController {
    // MARK: -IBOutlets
    @IBOutlet weak var postView : UITextView!
    @IBOutlet weak var preView : UIImageView!
    @IBOutlet weak var videoButton: UIButton!
    
    // MARK: -IBActions
    @IBAction func openCameraAction(){
        let alert = UIAlertController(title: "camara",
                                      message: "selecciona una opcion",
                                      preferredStyle: UIAlertController.Style.actionSheet)
        alert.addAction(UIAlertAction(title: "Foto", style: .default, handler: { _ in
            self.openCamera()
        }))
        alert.addAction(UIAlertAction(title: "Video", style: .default, handler: { _ in
            self.openVideoCamera()
        }))
        alert.addAction(UIAlertAction(title: "Cancelar", style: .destructive, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func dismissAction(){
        dismiss(animated: true, completion: nil)
    }
    @IBAction func addPostAction(){
        if currentVideoURL != nil {
            uploadVideoToFirebase()
            return
        }
        if preView.image != nil {
            uploadPhotoToFirebase()
        }
        savePost(imageUrl: nil, videoUrl: nil)
    }
    @IBAction func openPreViewAction(_ sender: Any) {
        guard let recordedVideoUrl = currentVideoURL else { return }
        
        let avPlayer = AVPlayer(url: recordedVideoUrl)
        
        let avPlayerController = AVPlayerViewController()
        avPlayerController.player = avPlayer
        
        present(avPlayerController, animated: true) {
            avPlayerController.player?.play()
        }
    }
    // MARK: - PROPERTIES
    private var imagePicker:UIImagePickerController?
    private var currentVideoURL: URL?
    private var locationManager : CLLocationManager?
    private var userLocation : CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoButton.isHidden = true
        requestLocation()
    }
    
    private func requestLocation() {
//  validamos que el usuario tenga activado el gps
        guard CLLocationManager.locationServicesEnabled ( ) else {return}
        locationManager = CLLocationManager()
        locationManager?.delegate  = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
    private func openVideoCamera() {
        imagePicker = UIImagePickerController()
        imagePicker?.sourceType = .camera
        imagePicker?.mediaTypes = [kUTTypeMovie as String]
        imagePicker?.cameraFlashMode = .off
        imagePicker?.cameraCaptureMode = .video
        imagePicker?.videoQuality = .typeMedium
        imagePicker?.videoMaximumDuration = TimeInterval(5)
        imagePicker?.allowsEditing = true
        imagePicker?.delegate = self
        
        guard let imagePicker = imagePicker else { return }
        present(imagePicker, animated: true, completion: nil)
    }
    private func openCamera() {
        imagePicker = UIImagePickerController()
        imagePicker?.sourceType = .photoLibrary
        //        imagePicker?.cameraFlashMode = .off
        //        imagePicker?.cameraCaptureMode = .photo
        //        imagePicker?.allowsEditing = true
        imagePicker?.delegate = self
        
        guard let imagePicker = imagePicker else { return }
        present(imagePicker, animated: true, completion: nil)
    }
    // 1. Asegurarnos de que la foto exista
    // 2. Comprimir la imagen y convertirla en Data
    // 3. Configuración para guardar la foto en firebase
    // 4. Referencia al storage de firebase
    // 5. Crear nombre de la imagen a subir
    // 6. Referencia a la carpeta donde se va a guardar la foto
    // 7. Subir la foto a Firebase
    private func uploadPhotoToFirebase(){
        // 1,2.
        guard let imageSaved = preView.image,
              let imageSavedData : Data = imageSaved.jpegData(compressionQuality: 0.1)
        else { return }
        // 3.
        SVProgressHUD.show()
        let metaDataConfig = StorageMetadata()
        metaDataConfig.contentType = "image/jpg"
        // 4.
        let storage = Storage.storage()
        // 5.
        let imageName = Int.random(in: 100...100)
        // 6.
        let folderReference = storage.reference(withPath:"fotos-tweets/\(imageName).jpg")
        // 7.
        DispatchQueue.global(qos: .background).async {
            folderReference.putData(imageSavedData, metadata: metaDataConfig){
                (metaData: StorageMetadata?, error: Error?) in
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    if let error = error {
                        NotificationBanner(title: "Error",
                                           subtitle: error.localizedDescription,
                                           style: .warning).show()
                        
                        return
                    }
                    folderReference.downloadURL { (url: URL?, error: Error?) in
                        let downloadUrl = url?.absoluteString ?? ""
                        self.savePost(imageUrl: downloadUrl, videoUrl: nil)
                    }
                }
            }
        }
    }
    
    private func uploadVideoToFirebase(){
        // 1,2.
        guard let currentVideoSavedURL = currentVideoURL,
              let videoData : Data = try? Data(contentsOf: currentVideoSavedURL) else { return }
        // 3.
        SVProgressHUD.show()
        let metaDataConfig = StorageMetadata()
        metaDataConfig.contentType = "video/mp4"
        // 4.
        let storage = Storage.storage()
        // 5.
        let videoName = Int.random(in: 100...100)
        // 6.
        let folderReference = storage.reference(withPath:"videos-tweets/\(videoName).mp4")
        // 7.
        DispatchQueue.global(qos: .background).async {
            folderReference.putData(videoData, metadata: metaDataConfig) { (metaData: StorageMetadata?, error: Error?) in
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    if let error = error {
                        NotificationBanner(title: "Error",
                                           subtitle: error.localizedDescription,
                                           style: .warning).show()
                        
                        return
                    }
                    folderReference.downloadURL { (url: URL?, error: Error?) in
                        let downloadUrl = url?.absoluteString ?? ""
                        self.savePost(imageUrl: nil, videoUrl: downloadUrl)
                    }
                }
            }
        }
    }
    
    
    func savePost(imageUrl:String?, videoUrl: String?){
//        guard let userLatitud = userLocation?.coordinate.latitude else { return }
//        guard let userLongitude = userLocation?.coordinate.longitude else { return }
//        let postLocation = PostRequestLocation(latitude: userLatitud, longitude: userLongitude)
        var postLocation: PostRequestLocation?
        if let userLocation = userLocation {
            postLocation = PostRequestLocation(latitude:userLocation.coordinate.latitude,
                                longitude: userLocation.coordinate.longitude)
        }
        
        //        1- hacer request
        let postText : String = postView.text
        if postText.isEmpty {
            NotificationBanner(subtitle: "Tu campo de texto esta vacio", style: .warning).show()
        } else {
            let request = PostRequest(text: postText,
                                      imageUrl: imageUrl,
                                      videoUrl: videoUrl,
                                      location: postLocation)
            // indicar carga al usuario
            SVProgressHUD.show()
            SN.post(endpoint: EndPoints.post, model: request){(response: SNResultWithEntity<Post,ErrorResponse>) in
                // 4. Cerrar indicador de carga
                SVProgressHUD.dismiss()
                switch response {
                case .success:
                    self.dismiss(animated: true, completion: nil)
                    
                case .error(let error):
                    NotificationBanner(title: "Error",
                                       subtitle: error.localizedDescription,
                                       style: .danger).show()
                    print(error.localizedDescription)
                    
                case .errorResult(let entity):
                    NotificationBanner(title: "Error",
                                       subtitle: entity.error,
                                       style: .warning).show()
                }
            }
        }
    }
}
extension AddPostViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //  cerrar selector de fotos
        imagePicker?.dismiss(animated: true, completion: nil)
        if  info.keys.contains(.originalImage) {
            preView.isHidden = false
            //  Obtenemos la imagen tomada
            preView.image = info[.originalImage] as? UIImage
        }
        //  Aqui capturamos la URL del video
        if  info.keys.contains(.mediaURL) , let recordedVideoUrl = (info[.mediaURL] as? URL)?.absoluteURL {
            videoButton.isHidden = false
            currentVideoURL = recordedVideoUrl
        }
    }
}

extension AddPostViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let bestLocation = locations.last else { return }
        self.userLocation = bestLocation
    }
}
