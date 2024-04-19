//
//  ViewController.swift
//  rapidsnark
//
//  Created by Yaroslav Moria on 04/04/2024.
//  Copyright (c) 2024 Yaroslav Moria. All rights reserved.
//

import UIKit
import os.log

import rapidsnark

class ViewController: UIViewController {

    @IBOutlet weak var resultLabel: UILabel!;

    @IBOutlet weak var proofLabel: UILabel!;
    @IBOutlet weak var inputLabel: UILabel!;
    @IBOutlet weak var executionTimeLabel: UILabel!;
    @IBOutlet weak var verificationTimeLabel: UILabel!;

    override func viewDidLoad() {
        super.viewDidLoad();
        // Do any additional setup after loading the view, typically from a nib.
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
            let witness = FileManager.default.contents(atPath: witnessPath())!;

            let startTime = Date()

            let proof, inputs: String
            if buffer {
                let zkey = FileManager.default.contents(atPath: zkeyPath)!;
                (proof, inputs) = try groth16Prove(zkey: zkey, witness: witness);
            }else{
                (proof, inputs) = try groth16ProveWithZKeyFilePath(zkeyPath: zkeyPath, witness: witness);
            }

            let endTime = Date()
            let diffProofTime = endTime.timeIntervalSince(startTime)


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

    func displayExecutionResult(_ proof: String, _ inputs: String, _ executionTime: Double, _ verificationTime: Double){
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

    func zkeyPath() -> String {
        return Bundle.main.path(forResource: "circuit_final", ofType: "zkey")!;
    }

    func witnessPath() -> String {
        return Bundle.main.path(forResource: "witness", ofType: "wtns")!;
    }

    func verificatonKeyPath() -> String {
        return Bundle.main.path(forResource: "verification_key", ofType: "json")!;
    }
}
