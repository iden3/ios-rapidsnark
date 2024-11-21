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

class ViewController: UIViewController {
    var pickedFileType = FileType.inputs
    
    var inputs: Data?
    var graph: Data?
    var zkey: Data?
    var verificationKey: Data?
    
    var witness: Data?
    
    var proof: (proof: String, publicSignals: String)?
    
    @IBOutlet weak var resultLabel: UILabel!;
    
    @IBOutlet weak var proofLabel: UILabel!;
    @IBOutlet weak var inputLabel: UILabel!;
    @IBOutlet weak var executionTimeLabel: UILabel!;
    @IBOutlet weak var verificationTimeLabel: UILabel!;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        // Do any additional setup after loading the view, typically from a nib.
        
        inputs = FileManager.default.contents(atPath :inputsPath())!
        graph = FileManager.default.contents(atPath :witnessGraphPath())!
        zkey = FileManager.default.contents(atPath :zkeyPath())!
        verificationKey = FileManager.default.contents(atPath :verificatonKeyPath())!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func generateProofClick(_ sender: Any) {
        generateProof(buffer:false)
    }
    
    @IBAction func generateBufferProofClick(_ sender: Any) {
        generateProof(buffer:true)
    }
    
    func generateProof(buffer: Bool){
        do {
            let zkeyPath = zkeyPath();
            let witness = try calculateWitness(
                inputs: inputs!,
                graph: graph!
            )
            
            let startTime = Date()
            
            let proof, inputs: String
            if buffer {
                let zkey = FileManager.default.contents(atPath: zkeyPath)!;
                (proof, inputs) = try groth16Prove(zkey: zkey, witness: witness);
            } else {
                (proof, inputs) = try groth16ProveWithZKeyFilePath(zkeyPath: zkeyPath, witness: witness);
            }
            
            let endTime = Date()
            let diffProofTime = endTime.timeIntervalSince(startTime)
            
            self.proof = (proof: proof, publicSignals: inputs)
            
            let verificationKey = FileManager.default.contents(atPath :verificatonKeyPath())!
            let startVerificationTime = Date()
            let isValid = try groth16Verify(proof: proof.data(using: .utf8)!, inputs: inputs.data(using: .utf8)!, verificationKey: verificationKey)
            let endVerificatonTime = Date()
            let diffVerificationTime = endVerificatonTime.timeIntervalSince(startVerificationTime)
            
            let bufferSize = try groth16PublicSizeForZkeyFile(zkeyPath: zkeyPath)
            print("Buffer size: \(bufferSize)")

            print("Verification result: \(isValid)")
            displayExecutionResult(proof, inputs, diffProofTime, diffVerificationTime)
        } catch {
            resultLabel.text = "Error while calculating proof: " + String(describing: error);
            print(error)
        }
    }
    
    func displayExecutionResult(
        _ proof: String,
        _ inputs: String,
        _ executionTime: Double,
        _ verificationTime: Double
    ) {
        proofLabel.text = proof
        inputLabel.text = inputs
        executionTimeLabel.text = executionTime.description
        verificationTimeLabel.text = verificationTime.description
        // print result in console
        print("Proof: \(proof)")
        print("Inputs: \(inputs)")
        print("Execution Time: \(executionTime) seconds")
        print("Verification Time: \(verificationTime) seconds")
    }
    
    @IBAction
    func onCopyToClipboard() {
        let pasteBoard = UIPasteboard.general;
        let str = (proofLabel.text ?? "") + "\n" + (inputLabel.text ?? "")
        pasteBoard.string = str;
        
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
    
    func zkeyPath() -> String {
        return Bundle.main.path(forResource: "authV2", ofType: "zkey")!;
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
