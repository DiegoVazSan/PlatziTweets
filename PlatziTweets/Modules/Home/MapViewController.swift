//
//  MapViewController.swift
//  PlatziTweets
//
//  Created by Diego on 15/07/21.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    @IBOutlet weak var mapContainer : UIView!
    
    private var map : MKMapView?
     var post = [Post]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupMarkers()
    }
    private func setupMap(){
        map = MKMapView(frame: mapContainer.bounds)
        mapContainer.addSubview(map ?? view)
    }
    
    private func setupMarkers () {
        post.forEach { item in
            let marker = MKPointAnnotation()
            marker.coordinate = CLLocationCoordinate2D(latitude: item.location.latitude, longitude: item.location.longitude)
            marker.title = item.text
            marker.subtitle = item.author.names
            
            map?.addAnnotation(marker)
            
        }
    }
}
