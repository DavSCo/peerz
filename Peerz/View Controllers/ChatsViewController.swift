//
//  FirstViewController.swift
//  Peerz
//
//  Created by David Cohen on 19/11/2018.
//  Copyright © 2018 Peerz. All rights reserved.
//-


import UIKit
import MultipeerConnectivity
import AVFoundation

class ChatsViewController: UIViewController ,MCSessionDelegate, MCBrowserViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate,UITextFieldDelegate, AVAudioRecorderDelegate {
    //// VARIABLE /////
    @IBOutlet weak var sendVocalButton: UIButton!
    
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
    
    // vocal notes
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    
    
    // file
    var fileName = ""
    var fileExtension = ""
    var fileURL = ""
    
    
    var audioSend = false
    
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
        let type: String
        
    }
    ////////////////////////

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
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
        
        cell.messageLabel.text = tabMember[indexPath.item].type == "text" ? tabMember[indexPath.item].text : "▶️"
        cell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapCell(_:))))
        
        return cell
    }
    
    @objc func tapCell(_ sender: UITapGestureRecognizer) {
        
        let location = sender.location(in: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: location)
        
        if let index = indexPath {
            let tempURL =  getTempDirectory().absoluteString + tabMember[index.row].text
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
    
    func sendMessage(text: String)
    {
        if mcSession.connectedPeers.count > 0 {
            if let messText = text.data(using: .utf8) {
                do {
                    
                    let newMember = Member(name: peerID.displayName, color: .blue)
                    
                    let newMessage=Message(member: newMember, text: text, type: "text")

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
            let temMessage = Message(member: newMember, text: message, type: "text")
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
        
        if audioSend ==  true {
            DispatchQueue.main.async {
                do {
                    let tempName = "\(self.getDate())-received.m4a"
                    try  data.write(to: self.getTempDirectory().appendingPathComponent(tempName))
                    
                    let newMember = Member(name: peerID.displayName, color: .blue)
                    let temMessage = Message(member: newMember, text: tempName, type: "audio")
                    
                    
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
                    let newMessage = Message(member: newMember, text: fileURL.components(separatedBy: "/").last!, type: "audio")
                    
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











