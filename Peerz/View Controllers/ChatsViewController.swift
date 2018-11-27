//
//  FirstViewController.swift
//  Peerz
//
//  Created by David Cohen on 19/11/2018.
//  Copyright © 2018 Peerz. All rights reserved.
//-


import UIKit
import MultipeerConnectivity

class ChatsViewController: UIViewController ,MCSessionDelegate, MCBrowserViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate,UITextFieldDelegate {
    //// VARIABLE /////
    
    
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    //choisir photo
    var imagePicker = UIImagePickerController()

    @IBOutlet weak var imgView: UIImageView!
    
    //variable du tap recognizer
    @IBOutlet var tapGestureView: UITapGestureRecognizer!
    
    @IBOutlet weak var messageTextField: UITextField!
    
    // var tabMessage: [String] = []
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
        let text: String
        
    }
    ////////////////////////
    
    
    
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
        
        
        
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
        
        let identifier: String
        
        if tabMember[indexPath.item].member.name == mcSession.myPeerID.displayName   {
            identifier = "myCell"
        } else {
            identifier = "theirCell"
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! MessageBubbleCollectionViewCell
        
        
        cell.messageLabel.text = tabMember[indexPath.item].text
        
        
        
        
        
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
    
    
    
    
    
    
    func sendMessage(text: String)
    {
        if mcSession.connectedPeers.count > 0 {
            if let messText = text.data(using: .utf8) {
                do {
                    
                    let newMember = Member(name: peerID.displayName, color: .blue)
                    
                    let newMessage=Message(member: newMember, text: text)
                    
                    
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
    
    
    
    
    
    //on recoit le message
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            let newMember = Member(name: peerID.displayName, color: .blue)
            let temMessage = Message(member: newMember, text: message)
            DispatchQueue.main.async {
                self.tabMember.append(temMessage)
                self.collectionView.reloadData()
            }
            
            
        }
        
        if let image = UIImage(data: data) {
            DispatchQueue.main.async { [unowned self] in
                self.sendPicture(img: image)
                print(image)
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
    
    
    func sendPicture(img:UIImage) {
        if mcSession.connectedPeers.count > 0 {
            if let imageData = img.pngData() {
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch let error as NSError {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
        
    }
    
    ////////////////////////////////////////////////////////////////////////////////////
    func startPhoto(action: UIAlertAction!) {
     
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            print("Button capture")
            
            imagePicker.delegate = self as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
            imagePicker.sourceType = .savedPhotosAlbum;
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func ChoiceSend(_ sender: Any) {
        
        let aChoice = UIAlertController(title: "Choice Send", message: nil, preferredStyle: .actionSheet)
        aChoice.addAction(UIAlertAction(title: "Envoyer Une photo", style: .default, handler: startPhoto))
        aChoice.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(aChoice, animated: true)
        
        
   
        
    }
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!){
        self.dismiss(animated: true, completion: { () -> Void in
            
        })
        
        imgView.image = image
    }
    
    
    
    
    
    
    
    
    
    
    
    
}









