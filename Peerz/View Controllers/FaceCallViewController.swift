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

class FaceCallViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var videoView: UIView!
    
   
    var captureSession = AVCaptureSession()
    var previewLayer = AVCaptureVideoPreviewLayer()
    var movieOutput = AVCaptureVideoDataOutput()
    var videoCaptureDevice : AVCaptureDevice?
    let sampleBufferQueue = DispatchQueue.global(qos: .userInteractive)
    
    //Session
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(startBarButton))
        
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
        
//        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
//        guard
//            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
//            captureSession.canAddInput(videoDeviceInput)
//            else { return }
//        captureSession.addInput(videoDeviceInput)

        guard captureSession.canAddOutput(movieOutput) else { return }
        captureSession.sessionPreset = .medium
        captureSession.addOutput(movieOutput)
        captureSession.commitConfiguration()
        movieOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        
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
    
    @objc func startBarButton() {
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
    

}
