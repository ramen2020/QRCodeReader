//
//  QRReader.swift
//  QRReader
//
//  Created by 宮本光直 on 2022/01/07.
//

import AVFoundation
import SwiftUI

public struct QRReader: UIViewControllerRepresentable {

    @Binding var canScan: Bool
    
    public var completion: (Result<String, QRError>) -> Void

    public enum QRError: Error {
        case inputError, outputError
    }
    
    init(
        canScan: Binding<Bool>,
        completion: @escaping (Result<String, QRError>) -> Void
    ) {
        self._canScan = canScan
        self.completion = completion
    }

    public class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRReader

        init(parent: QRReader) {
            self.parent = parent
        }

        public func found(code: String) {
            parent.canScan = false
            parent.completion(.success(code))
        }

        public func failed(reason: QRError) {
            parent.completion(.failure(reason))
        }
        
        public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                guard parent.canScan == true else { return }
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                found(code: stringValue)
            }
        }
    }

    public class ScannerViewController: UIViewController {
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var delegate: Coordinator?

        override public func viewDidLoad() {
            super.viewDidLoad()
            setCaptureSession()
        }

        override public func viewWillLayoutSubviews() {
            previewLayer?.frame = view.layer.bounds
        }

        override public func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            captureSession.startRunning()
        }

        override public func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            if captureSession?.isRunning == false {
                captureSessionStart()
            }
        }

        override public func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)

            if captureSession?.isRunning == true {
                captureSessionStop()
            }
        }
        
        // settings required to scan qr codes
        private func setCaptureSession() {
            captureSession = AVCaptureSession()

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                delegate?.failed(reason: .inputError)
                return
            }

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                delegate?.failed(reason: .inputError)
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()

            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                scanRange(metadataOutput: metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                delegate?.failed(reason: .outputError)
                return
            }
        }

        // capture start
        public func captureSessionStart() {
            captureSession.startRunning()
        }

        // capture stop
        public func captureSessionStop() {
            captureSession.stopRunning()
        }
        
        // Analysis range to scan a QR code
        public func scanRange(metadataOutput: AVCaptureMetadataOutput) {
            metadataOutput.rectOfInterest = CGRect(
                x: 0.3, y: 0.3, width: 0.5, height: 0.5
            )
        }

        override public var prefersStatusBarHidden: Bool {
            return true
        }

        override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .portrait
        }
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    public func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    public func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {

    }
}
