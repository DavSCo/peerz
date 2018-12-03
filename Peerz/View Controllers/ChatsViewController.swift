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
import AVFoundation

class ChatsViewController: UIViewController ,MCSessionDelegate, MCBrowserViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate,UITextFieldDelegate,UIImagePickerControllerDelegate , UINavigationControllerDelegate, AVAudioRecorderDelegate {
/////////////////////////////////////////////////////////////////////////VARIABLE ///////////////////////////////////////////////////////////////
    @IBOutlet weak var sendVocalButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    //Variable peerID
    var peerID: MCPeerID!
    //variable mcSession
    var mcSession: MCSession!
    //variable Avertisseur
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    //choisir photo
    let imagePicker = UIImagePickerController()
    
    
    //variable du tap recognizer
    @IBOutlet var tapGestureView: UITapGestureRecognizer!
    //text field
    @IBOutlet weak var messageTextField: UITextField!
    //tabkeau de message
    var tabMember:  [Message] = []
      // vocal notes
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    
    
    // file
    var fileName = ""
    var fileExtension = ""
    var fileURL = ""
    
    
    var audioSend = false
  
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
    
///////////////////////////////////////////////////////STRUCTURES//////////////////////////////////////////////////////////////////////////////////

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
////////////////////////////////////////////////////////////FUNCTION///////////////////////////////////////////////////////////////////////////////
   
    



    override func viewDidLoad() {
        super.viewDidLoad()
        

        imagePicker.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
        
        
        collectionView.dataSource = self
        collectionView.delegate = self
        

        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in DispatchQueue.main.async {
                if allowed {
                    print("Recording allowed")
                } else {
                    print("Recording not allowed")
                }
                }
            }
        } catch {
            print("Failed to record!")
        }
    }
    //cacher le clavier
    @IBAction func hideKeyboardAction(_ sender: Any) {
        
        messageTextField.endEditing(true)
        
    }
    
    //bouger le clavier
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
    
    
    //ule du collection view
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
        }else if tabMember[indexPath.item].type == "audio"{
            cell.messageLabel.text = "▶️"
        }
        
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapCell(_:))))

        
        return cell
    }
    
    @objc func tapCell(_ sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: location)
        
        if let index = indexPath {
            let tempURL =  getTempDirectory().absoluteString + tabMember[index.row].text!
            print("Tapped with text")
            print(fileURL)
            playAudio(URLTo: tempURL.replacingOccurrences(of: "file://", with: ""))
        }
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
        
        if audioSend ==  true {
            DispatchQueue.main.async {
                do {
                    let tempName = "\(self.getDate())-received.m4a"
                    try  data.write(to: self.getTempDirectory().appendingPathComponent(tempName))
                    
                    let newMember = Member(name: peerID.displayName, color: .blue)
                    let temMessage = Message(member: newMember, text: tempName, image: nil, type: "audio")
                    
                    
                    self.tabMember.append(temMessage)
                    self.collectionView.reloadData()
                    
                    self.audioSend = false
                    
                } catch let error {
                    print(error)
                }
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

  
    func startPhoto(action: UIAlertAction!) {
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            print("Button capture")
            
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum;
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true, completion: nil)
        }
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
  
        

    @IBAction func sendVocal(_ sender: UIButton) {
        if audioRecorder == nil {
            self.sendVocalButton.setTitle("S", for: .normal)
            self.startRecording()
        } else {
            self.sendVocalButton.setTitle("R", for: .normal)
            self.finishRecording(success: true)
        }
    }

    
    func startRecording() {
        fileName =  "\(getDate())-recording"
        fileExtension = "m4a"
        
        let audioFileName = getTempDirectory().appendingPathComponent("\(fileName).\(fileExtension)")
        
        fileURL = audioFileName.path
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            audioRecorder = try AVAudioRecorder(url: audioFileName, settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ])
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
        } catch {
            finishRecording(success: false)
        }
        
        do {
            try audioSession.setActive(true)
            audioRecorder.record()
        } catch {
        }
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            print("Success")
            
            print(mcSession.connectedPeers.count)
            print(URL(fileURLWithPath: fileURL))
            print(mcSession.connectedPeers)
            
            
            if mcSession.connectedPeers.count > 0 {
                do {
                    try mcSession.send(Data(contentsOf: URL(fileURLWithPath: fileURL)), toPeers: mcSession.connectedPeers, with: .reliable)
                    
                    let newMember = Member(name: peerID.displayName, color: .blue)
                    let newMessage = Message(member: newMember, text: fileURL.components(separatedBy: "/").last!, image: nil, type: "audio")
                    
                    tabMember.append(newMessage)
                    collectionView.reloadData()
                    audioSend = true
                } catch let error {
                    print(error)
                }
                
            }
        } else {
            print("An error occured")
        }
    }
    

    func playAudio(URLTo: String) {
        do {
            print(URLTo)
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: URLTo))
            if audioPlayer != nil {
                audioPlayer.prepareToPlay()
                audioPlayer.play()
            }
        } catch {
            print("Error")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func getDate() -> String{
        let date = DateFormatter()
        date.dateFormat = "yyyyMMddhhmmss"
        let now = date.string(from: Date())
        
        return now
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func getTempDirectory() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }

}











