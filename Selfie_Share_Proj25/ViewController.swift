//
//  ViewController.swift
//  Selfie_Share_Proj25
//
//  Created by Levit Kanner on 08/06/2020.
//  Copyright © 2020 Levit Kanner. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate{
    
    //MARK: - PROPERTIES
    var images = [UIImage]()
    var peerID = MCPeerID(displayName: UIDevice.current.name)
    var mcSession: MCSession?
    var advertiserAssistant: MCAdvertiserAssistant?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Selfie Share"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        
        let connectedbtn = UIBarButtonItem(title: "Devices", style: .plain, target: self, action: #selector(showConnectedDevices))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [spacer,connectedbtn, spacer]
        navigationController?.isToolbarHidden = false
        
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
    }
    
    
    //MARK: - DATA SOURCE
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageView", for: indexPath)
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.layer.cornerRadius = 145 / 2
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.image = images[indexPath.item]
        }
        return cell
    }
    
    
    
    //MARK: - METHODS
    @objc func importPicture() {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true, completion: nil)
        images.insert(selectedImage, at: 0)
        collectionView.reloadData()
        
        guard let session = mcSession else { return }
        guard session.connectedPeers.count > 0 else { return }
        guard let imageData = selectedImage.pngData() else {return}
        do {
            try session.send(imageData, toPeers: session.connectedPeers, with: .reliable)
        }catch{
            configureAlert(title: "Error", message: error.localizedDescription)
        }
    }
    
    
    @objc func showConnectionPrompt() {
        let alert = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Start a session", style: .default, handler: startHosting))
        alert.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        alert.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func startHosting(alertAction: UIAlertAction){
        guard let session = mcSession else { return }
        advertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-project25", discoveryInfo: nil, session: session)
        advertiserAssistant?.start()
        
    }
    
    func joinSession(alertAction: UIAlertAction){
        guard let session = mcSession else { return }
        let mcBrowser = MCBrowserViewController(serviceType: "hws-project25", session: session)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true, completion: nil)
        
    }
    
    func configureAlert(title: String! , message: String!){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    @objc func showConnectedDevices(){
        guard let devices = mcSession?.connectedPeers else {return}
        let names = devices.map {$0.displayName}
        configureAlert(title: "Connected Devices", message: devices.count > 0 ? ListFormatter().string(from: names) : "No devices connected")
    }
    
    
    
    //MARK: - MCSESSION DELEGATE METHODS
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected \(peerID.displayName)")
        case .connecting:
            print("Connecting \(peerID.displayName)")
        case .notConnected:
            configureAlert(title: "Device disconnected", message: "\(peerID.displayName) has been disconnected")
        @unknown default:
            print("Unknow state received \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {[weak self] in
            guard let image = UIImage(data: data) else { return }
            self?.images.insert(image, at: 0)
            self?.collectionView.reloadData()
        }
    }
    
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    
    
    //MARK: - MCBROWSER DELEGATE METHODS
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
}


/*
 Now, here's where it gets trickier. Multipeer connectivity requires four new classes:
 
 MCSession is the manager class that handles all multipeer connectivity for us.
 MCPeerID identifies each user uniquely in a session.
 MCAdvertiserAssistant is used when creating a session, telling others that we exist and handling invitations.
 MCBrowserViewController is used when looking for sessions, showing users who is nearby and letting them join.
 */
