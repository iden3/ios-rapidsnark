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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        do {
            try groth16PublicSizeForZkeyBuf(zkey: "")
        } catch {
            os_log("Error: %@", log: .default, type: .error, String(describing: error))
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

