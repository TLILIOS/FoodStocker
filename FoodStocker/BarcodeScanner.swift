//
//  BarcodeScanner.swift
//  FoodStocker
//
//  Created by TLiLi Hamdi on 24/07/2025.
//

import SwiftUI
import VisionKit
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    let completion: (String) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scannerViewController = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        scannerViewController.delegate = context.coordinator
        
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Démarrer le scan si pas déjà en cours
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: BarcodeScannerView
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let value = barcode.payloadStringValue {
                    parent.scannedCode = value
                    parent.completion(value)
                }
            default:
                break
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            for item in addedItems {
                switch item {
                case .barcode(let barcode):
                    if let value = barcode.payloadStringValue {
                        parent.scannedCode = value
                        
                        // Feedback haptic
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        dataScanner.stopScanning()
                        parent.completion(value)
                        return
                    }
                default:
                    break
                }
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didFailWithError error: Error) {
            print("Erreur de scan: \(error.localizedDescription)")
            
            // Feedback haptic d'erreur
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
        
        func dataScannerDidZoom(_ dataScanner: DataScannerViewController) {
            // Optionnel : gérer le zoom
        }
    }
}

// Vue alternative pour les appareils qui ne supportent pas DataScanner
struct CameraScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    let completion: (String) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let scannerView = ScannerView(scannedCode: $scannedCode, completion: completion)
        let hostingController = UIHostingController(rootView: scannerView)
        
        viewController.addChild(hostingController)
        viewController.view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        hostingController.didMove(toParent: viewController)
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Pas besoin de mise à jour
    }
}

struct ScannerView: View {
    @Binding var scannedCode: String
    let completion: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Scanner non disponible")
                .font(.title)
                .padding()
            
            Text("Le scanner de codes-barres nécessite iOS 16.0 ou plus récent et un appareil compatible.")
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Fermer") {
                dismiss()
            }
            .padding()
        }
    }
}

// Wrapper pour gérer la disponibilité de DataScanner
struct BarcodeScannerWrapper: View {
    @Binding var scannedCode: String
    let completion: (String) -> Void
    @State private var showPermissionAlert = false
    
    var body: some View {
        if #available(iOS 16.0, *) {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                BarcodeScannerView(scannedCode: $scannedCode, completion: completion)
                    .ignoresSafeArea()
                    .onAppear {
                        checkCameraPermission()
                    }
            } else {
                CameraScannerView(scannedCode: $scannedCode, completion: completion)
            }
        } else {
            CameraScannerView(scannedCode: $scannedCode, completion: completion)
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    showPermissionAlert = true
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        case .authorized:
            break
        @unknown default:
            break
        }
    }
}