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
    @IBOutlet weak var fileProverSwitch: UISwitch!;
    
    var result: String = "";
    
    override func viewDidLoad() {
        super.viewDidLoad();
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning();
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction
    func onCalculateProof() {
        var timestamp = NSDate().timeIntervalSince1970
        var readTimestamp = NSDate().timeIntervalSince1970

        let zkeyPath = zkeyPath();

        do {
            let witness = FileManager.default.contents(atPath: witnessPath())!;
            
            readTimestamp = NSDate().timeIntervalSince1970 - readTimestamp

            let (proof, inputs) : (proof: String, inputs: String);
            if (fileProverSwitch.isOn) {
                os_log("file prover")
                (proof, inputs) = try groth16ProveWithZKeyFilePath(zkeyPath: zkeyPath, witness: witness);
            } else {
                os_log("buffer prover")
                let zkey = FileManager.default.contents(atPath: zkeyPath)!;
                
                (proof, inputs) = try groth16Prove(zkey: zkey, witness: witness);
            }
            
            timestamp = NSDate().timeIntervalSince1970 - timestamp
            
            result = timestamp.description + "\n" + readTimestamp.description + "\n" + proof + "\n" + inputs;
            
            resultLabel.text = result;
        } catch {
            resultLabel.text = "Error while calculating proof: " + String(describing: error);
            os_log("Error: %@", log: .default, type: .error, String(describing: error));
        }
    }
    
    @IBAction
    func onCopyToClipboard() {
        let pasteBoard = UIPasteboard.general;
        pasteBoard.string = result;
    }
    
    func zkeyPath() -> String {
        return Bundle.main.path(forResource: "circuit_final", ofType: "zkey")!;
    }
    
    func witnessPath() -> String {
        return Bundle.main.path(forResource: "witness", ofType: "wtns")!;
    }
}
