//
//  ViewController.swift
//  rapidsnark
//
//  Created by Yaroslav Moria on 04/04/2024.
//  Copyright (c) 2024 Yaroslav Moria. All rights reserved.
//

import UIKit
import os.log
import UniformTypeIdentifiers

import CircomWitnesscalc
import rapidsnark

class ViewController: UIViewController, UIDocumentPickerDelegate {
    var pickedFileType = FileType.inputs
    
    var inputs: Data?
    var graph: Data?
    var zkeyPath: String?
    var verificationKey: Data?
    
    var witness: Data?
    
    var proof: (proof: String, inputs: String)?
    
    @IBOutlet
    weak var inputsLabel: UILabel!;
    
    @IBOutlet
    weak var graphLabel: UILabel!;
    
    @IBOutlet
    weak var zkeyLabel: UILabel!;
    
    @IBOutlet
    weak var verificationKeyLabel: UILabel!;
    
    @IBOutlet
    weak var witnessLabel: UILabel!;
    
    @IBOutlet
    weak var proofLabel: UILabel!;
    
    @IBOutlet
    weak var verificationLabel: UILabel!;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        // Do any additional setup after loading the view, typically from a nib.
        
        inputs = FileManager.default.contents(atPath :inputsPath())!
        graph = FileManager.default.contents(atPath :witnessGraphPath())!
        verificationKey = FileManager.default.contents(atPath :verificatonKeyPath())!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction
    public func selectInputs() {
        pickedFileType = FileType.inputs
        
        let pickerViewController = filePicker(fileType: pickedFileType)
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    @IBAction
    public func selectGraphBinFile() {
        pickedFileType = FileType.graph
        
        let pickerViewController = filePicker(fileType: pickedFileType)
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    @IBAction
    public func selectZkeyFile() {
        pickedFileType = FileType.zkey
        
        let pickerViewController = filePicker(fileType: pickedFileType)
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    @IBAction
    public func selectVerificationKeyFile() {
        pickedFileType = FileType.verificationKey
        
        let pickerViewController = filePicker(fileType: pickedFileType)
        self.present(pickerViewController, animated: true, completion: nil)
    }
    
    @IBAction
    func generateProof() {
        do {
            let zkeyPath = getZkeyPath();
            let witness = try calculateWitness(
                inputs: inputs!,
                graph: graph!
            )
            
            let startTime = Date()
            
            let (proof, inputs) = try groth16Prove(zkeyPath: zkeyPath, witness: witness);
            
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)
            
            self.proof = (proof: proof, inputs: inputs)
            
            proofLabel.text = "Execution Time: \(executionTime) seconds\n\(proof)"
            // print result in console
            print("Proof: \(proof)")
            print("Inputs: \(inputs)")
            print("Execution Time: \(executionTime) seconds")
        } catch {
            proofLabel.text = "Error while calculating proof: " + String(describing: error);
            print(error)
        }
    }
    
    @IBAction
    func onValidateProof() {
        do {
            let verificationKey = verificationKey ?? FileManager.default.contents(atPath :verificatonKeyPath())!
            let startVerificationTime = Date()
            let isValid = try groth16Verify(
                proof: proof!.proof.data(using: .utf8)!,
                inputs: proof!.inputs.data(using: .utf8)!,
                verificationKey: verificationKey
            )
            let endVerificatonTime = Date()
            let verificationTime = endVerificatonTime.timeIntervalSince(startVerificationTime)
            
            print("Verification result: \(isValid)")
            print("Verification Time: \(verificationTime) seconds")
            
            verificationLabel.text = "Verification result: \(isValid)\nVerification Time: \(verificationTime) seconds"
        } catch {
            proofLabel.text = "Error while verifying proof: " + String(describing: error);
            print(error)
        }
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            NSLog("File pick ulrs empty or cancelled")
            return
        }
        NSLog("Selected file URL: " + url.description)
        
        let label = switch pickedFileType {
        case .zkey: zkeyLabel
        case .inputs: inputsLabel
        case .graph: graphLabel
        case .verificationKey: verificationKeyLabel
        }
        
        var data = Data()
        do {
            if pickedFileType == .zkey {
                zkeyPath = url.path
            } else {
                data = try Data(contentsOf: url)
            }
        } catch {
            label?.text = "Error picking " + pickedFileType.name + ": " + error.localizedDescription
            NSLog(error.localizedDescription)
            return
        }
        
        label?.text = "Got " + pickedFileType.name + ". Name: " + url.lastPathComponent
        
        switch pickedFileType {
        case .graph:
            graph = data
        case .inputs:
            inputs = data
        case .verificationKey:
            verificationKey = data
        default:
            break
        }
    }
    
    private func filePicker(fileType: FileType) -> UIDocumentPickerViewController {
        let pickerViewController = if #available(iOS 14.0, *) {
            UIDocumentPickerViewController(
                forOpeningContentTypes: [fileType.uttype],
                asCopy: true
            )
        } else {
            UIDocumentPickerViewController(
                documentTypes: [fileType.documentType],
                in: UIDocumentPickerMode.open
            )
        }
        pickerViewController.delegate = self
        pickerViewController.allowsMultipleSelection = false
        if #available(iOS 13.0, *) {
            pickerViewController.shouldShowFileExtensions = true
        }
        return pickerViewController
    }
    
    @IBAction
    func onCopyToClipboard() {
        let pasteBoard = UIPasteboard.general;
        pasteBoard.string = proof.map { $0.proof + "\n" + $0.inputs }
        
        // Create and present an alert controller
        let alertController = UIAlertController(title: "Copied", message: "Proof and inputs have been copied to clipboard.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alertController, animated: true)
    }
    
    @IBAction
    func onShare() {
        if (proof == nil) {
            return
        }
        
        let file = proof!.proof.data(using: .utf8)!.dataToFile(fileName: "proof.json")
        
        let fileURL = NSURL(fileURLWithPath: file!.path!)
        
        // Create the Array which includes the files you want to share
        let filesToShare = [fileURL]
        
        // Make the activityViewContoller which shows the share-view
        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
        
        // Show the share-view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    func inputsPath() -> String {
        return Bundle.main.path(forResource: "authV2_inputs", ofType: "json")!;
    }
    
    func witnessGraphPath() -> String {
        return Bundle.main.path(forResource: "authV2", ofType: "wcd")!;
    }
    
    func getZkeyPath() -> String {
        return zkeyPath ?? Bundle.main.path(forResource: "authV2", ofType: "zkey")!;
    }
    
    func verificatonKeyPath() -> String {
        return Bundle.main.path(forResource: "authV2_verification_key", ofType: "json")!;
    }
}

enum FileType {
    case zkey, graph, inputs, verificationKey;
    
    public var name : String {
        return switch self {
        case .zkey: "zkey"
        case .graph: "graph"
        case .inputs: "inputs"
        case .verificationKey: "verificationKey"
        }
    }
    
    @available(iOS 14.0, *)
    public var uttype: UTType {
        switch self {
        case .zkey:
            return UTType.data
        case .graph:
            return UTType.data
        case .inputs:
            return UTType.json
        case .verificationKey:
            return UTType.json
        }
    }
    
    public var documentType: String {
        switch self {
        case .zkey:
            return "application/octet-stream"
        case .graph:
            return "application/octet-stream"
        case .inputs:
            return "application/json"
        case .verificationKey:
            return "application/json"
        }
    }
}

func getDocumentsDirectory() -> NSString {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentsDirectory = paths[0]
    return documentsDirectory as NSString
}

extension Data {
    func dataToFile(fileName: String) -> NSURL? {
        let data = self
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            try data.write(to: URL(fileURLWithPath: filePath))
            return NSURL(fileURLWithPath: filePath)
        } catch {
            print("Error writing the file: \(error.localizedDescription)")
        }
        return nil
    }
}
