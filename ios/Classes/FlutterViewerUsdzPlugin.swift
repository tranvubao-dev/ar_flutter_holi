import Flutter
import UIKit
import QuickLook

public class FlutterViewerUsdzPlugin: NSObject, FlutterPlugin, QLPreviewControllerDataSource {
    private var previewController: QLPreviewController?
    private var fileURL: URL?
    private var tempFileURL: URL?
    private var registrar: FlutterPluginRegistrar?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ar_flutter_holi_plus", binaryMessenger: registrar.messenger())
        let instance = FlutterViewerUsdzPlugin()
        instance.registrar = registrar
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadUSDZFile":
            handleLoadUSDZ(call, result: result)
        case "dispose":
            handleDispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleLoadUSDZ(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              let isUrl = args["isUrl"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }

        print("📱 Loading USDZ from: \(path)")

        if isUrl {
            handleUrlLoad(path: path, result: result)
        } else {
            handleAssetLoad(path: path, result: result)
        }
    }
    
    private func handleAssetLoad(path: String, result: @escaping FlutterResult) {
        guard let key = registrar?.lookupKey(forAsset: path) else {
            result(FlutterError(code: "ASSET_NOT_FOUND", message: "Asset not found: \(path)", details: nil))
            return
        }
        
        guard let assetPath = Bundle.main.path(forResource: key, ofType: nil) else {
            result(FlutterError(code: "ASSET_PATH_ERROR", message: "Cannot get asset path: \(path)", details: nil))
            return
        }
        
        self.fileURL = URL(fileURLWithPath: assetPath)
        showPreview(result: result)
    }
    
    private func handleUrlLoad(path: String, result: @escaping FlutterResult) {
        guard let url = URL(string: path) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid URL format", details: nil))
            return
        }
        
        let fileName = url.lastPathComponent
        let tempDir = FileManager.default.temporaryDirectory
        let localURL = tempDir.appendingPathComponent(fileName)
        self.tempFileURL = localURL
        
        let task = URLSession.shared.downloadTask(with: url) { [weak self] (tempURL, response, error) in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    print("❌ Download error: \(error)")
                    result(FlutterError(code: "DOWNLOAD_ERROR", message: error.localizedDescription, details: nil))
                }
                return
            }
            
            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "NO_FILE", message: "No file downloaded", details: nil))
                }
                return
            }
            
            do {
                if FileManager.default.fileExists(atPath: localURL.path) {
                    try FileManager.default.removeItem(at: localURL)
                }
                
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                self.fileURL = localURL
                
                DispatchQueue.main.async {
                    self.showPreview(result: result)
                }
            } catch {
                print("❌ File error: \(error)")
                DispatchQueue.main.async {
                    result(FlutterError(code: "FILE_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
        task.resume()
    }
    
    private func showPreview(result: @escaping FlutterResult) {
        guard let _ = self.fileURL else {
            result(FlutterError(code: "NO_FILE", message: "No file to preview", details: nil))
            return
        }
        
        let previewController = QLPreviewController()
        previewController.dataSource = self
        
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            rootViewController.present(previewController, animated: true) {
                self.previewController = previewController
                result(true)
            }
        } else {
            result(FlutterError(code: "NO_VIEW", message: "Cannot present view", details: nil))
        }
    }

    private func handleDispose(result: @escaping FlutterResult) {
        DispatchQueue.main.async { [weak self] in
            self?.previewController?.dismiss(animated: true)
            self?.previewController = nil
            
            if let tempURL = self?.tempFileURL,
               FileManager.default.fileExists(atPath: tempURL.path) {
                try? FileManager.default.removeItem(at: tempURL)
            }
            
            self?.fileURL = nil
            self?.tempFileURL = nil
            result(nil)
        }
    }
    
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return fileURL != nil ? 1 : 0
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURL! as QLPreviewItem
    }
}
