//
//  FirstViewController.swift
//  Peerz
//
//  Created by David Cohen on 19/11/2018.
//  Copyright © 2018 Peerz. All rights reserved.
//-


import UIKit
import Photos
import MultipeerConnectivity

class ChatsViewController: UIViewController ,MCSessionDelegate, MCBrowserViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate,UITextFieldDelegate ,UIImagePickerControllerDelegate , UINavigationControllerDelegate{
    //// VARIABLE /////
    
    
    //on stock les images
    
    var images = [UIImage]()
    
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    @IBOutlet weak var imgView: UIImageView!
    
    //choisir photo
    let imagePicker = UIImagePickerController()
    
    
    
    //variable du tap recognizer
    @IBOutlet var tapGestureView: UITapGestureRecognizer!
    
    @IBOutlet weak var messageTextField: UITextField!
    
    var tabMember:  [Message] = []
    
    @IBAction func hideKeyboardAction(_ sender: Any) {
        
        messageTextField.endEditing(true)
        
    }
    
    ///// STRUCTURES//////
    struct Member {
        let name: String
        let color: UIColor
    }
  
    
    struct Message {
        let member: Member
        let text: String?
        let image: UIImage?
        let type : String
        
    }
    ////////////////////////
    
    
    
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        imagePicker.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
        
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        moveTextField(textField, moveDistance: -200, up: true)
    }
    
    //fini d'ecrire
    func textFieldDidEndEditing(_ textField: UITextField) {
        moveTextField(textField, moveDistance: -200, up: false)
    }
    
    
    
    // on bouge le text fild
    func moveTextField(_ textField: UITextField, moveDistance: Int, up: Bool) {
        
        let moveDuration = 0.3
        
        let movement: CGFloat = CGFloat(up ? moveDistance : -moveDistance)
        
        UIView.beginAnimations("animateTextField", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(moveDuration)
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
    }
    
    
    
    
    
    
    
    
    
    //function return nombre de item dans collenction view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return tabMember.count
        
        
    }
    
    
    //cellule du collection view
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var identifier: String = ""
        
        
        if tabMember[indexPath.item].member.name == mcSession.myPeerID.displayName   {
            if tabMember[indexPath.item].type == "text"{
                identifier = "myCell"

            }else if tabMember[indexPath.item].type == "picture"{
                identifier = "myPicture"
            }
        } else  {
            
            if tabMember[indexPath.item].type == "text"{
                identifier = "theirCell"
                
            }else if tabMember[indexPath.item].type == "picture"{
                identifier = "theirPicture"
            }

        }
      
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! MessageBubbleCollectionViewCell
        
        if tabMember[indexPath.item].type == "text"{
            cell.messageLabel.text = tabMember[indexPath.item].text

        }else if tabMember[indexPath.item].type == "picture"{
            cell.bubbleImageView.image = tabMember[indexPath.item].image
        }
        
        
        
        
        
        
        
        return cell
        
        
    }
    
    //function qui utilise la fonction d'envoi de message
    @IBAction func ButtonSendMessage(_ sender: Any) {
        sendMessage(text: messageTextField.text!)
    }
    
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected: \(peerID.displayName)")
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
        }
    }
    
    
    
    
    ///////////////////////////////////FONCTION D'ENVOI////////////////////////////////////////

    
    func sendMessage(text: String)
    {
        if mcSession.connectedPeers.count > 0 {
            if let messText = text.data(using: .utf8) {
                do {
                    
                    let newMember = Member(name: peerID.displayName, color: .blue)
                    
                    let newMessage=Message(member: newMember, text: text, image: nil, type: "text")
                    
                    
                    // tabMessage.append(text)
                    if messageTextField.text != ""
                    {
                        tabMember.append(newMessage)
                    }
                    collectionView.reloadData()
                    
                    try mcSession.send(messText, toPeers: mcSession.connectedPeers, with: .reliable)
                    messageTextField.text=""
                    
                    
                } catch let error as NSError {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    
    func sendPicture(img:UIImage) {
        if mcSession.connectedPeers.count > 0 {
            if let imageData = img.pngData() {
                // 3
                do {
                    let newMember = Member(name: peerID.displayName, color: .blue)
                    let newMessage=Message(member: newMember, text: nil, image:img , type: "picture")
                    tabMember.append(newMessage)
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
        
    }
///////////////////////////////////////////////////////////////////////////
    
    
    
    
    
    //on recoit le message
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            let newMember = Member(name: peerID.displayName, color: .blue)
            let tempMessage = Message(member: newMember, text: message, image: nil, type: "text")
            DispatchQueue.main.async {
                self.tabMember.append(tempMessage)
                self.collectionView.reloadData()
            }
            
            
        }
        
        if let image = UIImage(data: data) {
            let newMember = Member(name: peerID.displayName, color: .blue)
            let tempMessage = Message(member: newMember, text: nil, image: image, type: "picture")
            DispatchQueue.main.async { [unowned self] in
                self.tabMember.append(tempMessage)
                self.collectionView?.reloadData()
            }
        }
        
        
    }
    
    // pour creer une session
    func startHosting(action: UIAlertAction!) {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-kb", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }
    //pour joindre une session
    func joinSession(action: UIAlertAction!) {
        let mcBrowser = MCBrowserViewController(serviceType: "hws-kb", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    
    
    //choix utilisateur (joindre ou creer session)
    
    @IBAction func ChoiceButton(_ sender: Any) {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
        
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    
    func importPicture(action: UIAlertAction!) {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }

    
    
 

    
    @IBAction func ChoiceSend(_ sender: Any) {
        
        let aChoice = UIAlertController(title: "Choice Send", message: nil, preferredStyle: .actionSheet)
        aChoice.addAction(UIAlertAction(title: "Envoyer Une photo", style: .default, handler: importPicture))
        aChoice.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(aChoice, animated: true)
        
        
        
        
    }
 
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        dismiss(animated: true)
        
        //images.insert(image, at: 0)
        sendPicture(img: image)
        collectionView?.reloadData()
    }
    
    func checkPermission() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized: 
            
            present(imagePicker, animated: true, completion: nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({
                (newStatus) in
                print("status is \(newStatus)")
                if newStatus ==  PHAuthorizationStatus.authorized {
                    /* do stuff here */
                    self.present(self.imagePicker, animated: true, completion: nil)
                    print("success")
                }
            })
            print("It is not determined until now")
        case .restricted:
            // same same
            print("User do not have access to photo album.")
        case .denied:
            // same same
            print("User has denied the permission.")
        }
    }
  
        
    
    
    
   
    
    
}























