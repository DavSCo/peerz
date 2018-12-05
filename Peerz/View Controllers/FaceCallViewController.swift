//
//  FaceCallViewController.swift
//  Peerz
//
//  Created by David Cohen on 26/11/2018.
//  Copyright © 2018 Peerz. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import AVFoundation
import VideoToolbox
import CoreData

class FaceCallViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVAudioRecorderDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var videoView: UIView!
    
   
    var captureSession = AVCaptureSession()
    var previewLayer = AVCaptureVideoPreviewLayer()
    var movieOutput = AVCaptureVideoDataOutput()
    var videoCaptureDevice : AVCaptureDevice?
    let sampleBufferQueue = DispatchQueue.global(qos: .userInteractive)
    
    //Audio
    var recordingSession = AVAudioSession()
    var audioRecorder = AVAudioRecorder.self
    var audioPlayer = AVAudioPlayer()
    var settings = [String : Int]()
    let audioSession = AVAudioSession.sharedInstance()
    var audioOutput = AVCaptureAudioDataOutput()
    
    
    //Session
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var stream: OutputStream!
    
    //Core Data
    var appDelegate = AppDelegate()
    var context = NSManagedObjectContext()
    var deviceId = ""
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DeviceID")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "name") as! String)
                deviceId = data.value(forKey: "name") as! String
            }
        } catch {
            print("Failed")
        }
        
        if deviceId == "" {
            peerID = MCPeerID(displayName: UIDevice.current.name)
        } else {
            peerID = MCPeerID(displayName: deviceId)
        }
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        
        setupCameraSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        previewLayer.session = self.captureSession
        previewLayer.bounds = CGRect(x: 0, y: 0, width: self.videoView.bounds.width, height: self.videoView.bounds.height)
        previewLayer.position = CGPoint(x: self.videoView.bounds.midX, y: self.videoView.bounds.midY)
        previewLayer.videoGravity = AVLayerVideoGravity.resize
        videoView.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
        
    }

    //Video
    func setupCameraSession() {
        captureSession.beginConfiguration()
        var defaultVideoDevice: AVCaptureDevice?
        
        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            defaultVideoDevice = videoDevice
        }
       
        guard let videoDevice = defaultVideoDevice else {
            print("Default video device is unavailable.")
            captureSession.commitConfiguration()
            return
        }
        
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession.canAddInput(videoDeviceInput)
            else { return }
        captureSession.addInput(videoDeviceInput)
        
        guard captureSession.canAddOutput(movieOutput) else { return }
        captureSession.sessionPreset = .medium
        captureSession.addOutput(movieOutput)
        captureSession.commitConfiguration()
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        movieOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
        //
        
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)

            if captureSession.canAddInput(audioDeviceInput) {
                captureSession.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }

        guard captureSession.canAddOutput(audioOutput) else { return }
        captureSession.addOutput(audioOutput)
        captureSession.commitConfiguration()
        audioOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        //Audio
//        var blockBuffer: CMBlockBuffer!
//        var audioBufferList = AudioBufferList()
//
//        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, bufferListSizeNeededOut: nil, bufferListOut: &audioBufferList, bufferListSize: MemoryLayout.size(ofValue: AudioBufferList.self), blockBufferAllocator: nil, blockBufferMemoryAllocator: nil, flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, blockBufferOut: &blockBuffer);
        
        var audioBufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: AudioBuffer(mNumberChannels: 0, mDataByteSize: 0, mData: nil))
        var blockBuffer: CMBlockBuffer!
        
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout.size(ofValue: audioBufferList),
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: UInt32(kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment),
            blockBufferOut: &blockBuffer
        )
        
        let audioBuffers = UnsafeBufferPointer<AudioBuffer>(start: &audioBufferList.mBuffers,
                                                           count: Int(audioBufferList.mNumberBuffers))
        
        for audioBuffer in audioBuffers {
//            if let x = audioBuffer.mData?.load(as: UnsafePointer<UInt8>.self) {
//                stream.write(x, maxLength: Int(audioBuffer.mDataByteSize))
//            }
        }

        //Video
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
      
        guard let imgBuf = imageBuffer else { return }
        var image: CGImage?
        VTCreateCGImageFromCVPixelBuffer(imgBuf, options: nil, imageOut: &image)
        
        guard let cgImg = image else { return }
        let img = UIImage(cgImage: cgImg, scale: 1.0, orientation: UIImage.Orientation.right)
        guard let jpgData = img.jpegData(compressionQuality: 0.5) else { return }
        
        if mcSession.connectedPeers.count > 0 {
            do {
                try mcSession.send(jpgData, toPeers: mcSession.connectedPeers, with: .reliable)
            } catch {
                print("error buffer")
            }
        }
    }
    
    @IBAction func startBarButtonAction(_ sender: Any) {
        let ac = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
        if mcSession.connectedPeers.count > 0 {
            ac.addAction(UIAlertAction(title: "Disconnect a session", style: .default, handler: disconnectSession))
        } else {
            ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        }
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    //Session / Hosting
    func startHosting(action: UIAlertAction!) {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "hws-kb", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }
    
    func joinSession(action: UIAlertAction!) {
        let mcBrowser = MCBrowserViewController(serviceType: "hws-kb", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    func disconnectSession(action: UIAlertAction!) {
        mcSession.disconnect()
    }
    @IBAction func endCallButtonAction(_ sender: Any) {
        mcSession.disconnect()
        captureSession.stopRunning()
//        navigationController?.popViewController(animated: true)
    }
    
    //Session
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
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            let image = UIImage(data: data)
            guard let img = image else { return }
            self.imageView.image = img
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        stream.open()
        print(stream)
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        self.stream = try?  mcSession.startStream(withName: "Audio", toPeer: mcSession.connectedPeers.first!)
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
}
