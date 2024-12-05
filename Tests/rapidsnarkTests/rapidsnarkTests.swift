import XCTest
import ZIPFoundation
import os
import CircomWitnesscalc

@testable import rapidsnark

let circuitsUrl = URL(string: "https://github.com/iden3/ios-rapidsnark/releases/download/0.0.1-alpha.5/testdata.zip")!
let circuitsZipPath = cacheFolder.path + "/testdata.zip"
let circuitsZipUrl = URL(fileURLWithPath: circuitsZipPath)
let circuitsFolderPath = cacheFolder.path + "/testdata"
let circuitsFolderUrl = URL(fileURLWithPath: circuitsFolderPath)

final class rapidsnarkTests: XCTestCase {
    
    override func setUp() async throws {
        if !FileManager.default.fileExists(atPath: circuitsZipPath) {
            if #available(iOS 15.0, *) {
                let (localURL, _) = try await URLSession.shared.download(from: circuitsUrl)
                let zipData = try Data(contentsOf: localURL)
                FileManager.default.createFile(atPath: circuitsZipPath, contents: zipData)
            } else {
                // TODO: Implement async download earlier versions of iOS
            }
        }
        
        if !FileManager.default.fileExists(atPath: circuitsFolderPath) {
            try FileManager.default.createDirectory(
                atPath: circuitsFolderPath,
                withIntermediateDirectories: true
            )
        }
        
        let testdataFolderContents = try FileManager.default.contentsOfDirectory(atPath: circuitsFolderPath)
        if testdataFolderContents.isEmpty {
            try FileManager.default.unzipItem(
                at: circuitsZipUrl,
                to: circuitsFolderUrl,
                skipCRC32: true,
                allowUncontainedSymlinks: true
            )
        }
    }
    
    func testBufferProofGeneration() throws {
        for circuitId in CircuitId.allCases {
            do {
                let witness = try calculateWitness(
                    inputs: circuitId.inputs,
                    graph: circuitId.wcdGraph
                )
                
                let proof = try groth16Prove(
                    zkey: circuitId.zkey,
                    witness: witness
                )
                
                XCTAssertTrue(!proof.proof.isEmpty, "Proof is empty for " + circuitId.rawValue)
                XCTAssertTrue(!proof.publicSignals.isEmpty, "Public signals are empty for " + circuitId.rawValue)
                
                let valid = try groth16Verify(
                    proof: proof.proof.data(using: .utf8)!,
                    inputs: proof.publicSignals.data(using: .utf8)!,
                    verificationKey: circuitId.verificationKey
                )
                XCTAssertTrue(valid, "Proof is invalid for " + circuitId.rawValue)
            } catch {
                NSLog("Buffer prover test failed for: " + circuitId.rawValue + " proof and inputs:")
                throw error
            }
            
            NSLog("Buffer prover test passed for: " + circuitId.rawValue)
        }
    }
    
    func testPathProofGeneration() throws {
        for circuitId in CircuitId.allCases {
            do {
                let witness = try calculateWitness(
                    inputs: circuitId.inputs,
                    graph: circuitId.wcdGraph
                )
                
                let proof = try groth16ProveWithZKeyFilePath(
                    zkeyPath: circuitId.zkeyPath,
                    witness: witness
                )
                
                XCTAssertTrue(!proof.proof.isEmpty, "Proof is empty for " + circuitId.rawValue)
                XCTAssertTrue(!proof.publicSignals.isEmpty, "Public signals are empty for " + circuitId.rawValue)
                
                let valid = try groth16Verify(
                    proof: proof.proof.data(using: .utf8)!,
                    inputs: proof.publicSignals.data(using: .utf8)!,
                    verificationKey: circuitId.verificationKey
                )
                
                XCTAssertTrue(valid, "Proof is invalid for " + circuitId.rawValue)
            } catch {
                NSLog("Path prover test failed for: " + circuitId.rawValue + " proof and inputs:")
                throw error
            }
            
            NSLog("Buffer prover test passed for: " + circuitId.rawValue)
        }
    }
    
    func testSingleCircuit() throws {
        let circuitId = CircuitId.sigonchain
        
        do {
            let witness = try calculateWitness(
                inputs: circuitId.inputs,
                graph: circuitId.wcdGraph
            )
            
            let proof = try groth16ProveWithZKeyFilePath(
                zkeyPath: circuitId.zkeyPath,
                witness: witness
            )
            
            XCTAssertTrue(!proof.proof.isEmpty, "Proof is empty for " + circuitId.rawValue)
            XCTAssertTrue(!proof.publicSignals.isEmpty, "Public signals are empty for " + circuitId.rawValue)
            
            let valid = try groth16Verify(
                proof: proof.proof.data(using: .utf8)!,
                inputs: proof.publicSignals.data(using: .utf8)!,
                verificationKey: circuitId.verificationKey
            )
            
            XCTAssertTrue(valid, "Proof is invalid for " + circuitId.rawValue)
        } catch {
            NSLog("Path prover test failed for: " + circuitId.rawValue + " proof and inputs:")
            throw error
        }
        
        NSLog("Test passed for: " + circuitId.rawValue)
    }
}

var cacheFolder: URL = {
    let fm = FileManager.default
    let folder = fm.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    
    var isDirectory: ObjCBool = false
    if !(fm.fileExists(atPath: folder.path, isDirectory: &isDirectory) && isDirectory.boolValue) {
        try! fm.createDirectory(at: folder, withIntermediateDirectories: false, attributes: nil)
    }
    return folder
}()

enum CircuitId: String, CaseIterable {
    case auth = "authV2"
    case mtp = "credentialAtomicQueryMTPV2"
    case sig = "credentialAtomicQuerySigV2"
    case mtponchain = "credentialAtomicQueryMTPV2OnChain"
    case sigonchain = "credentialAtomicQuerySigV2OnChain"
    case circuitsV3 = "credentialAtomicQueryV3-beta.1"
    case circuitsV3onchain = "credentialAtomicQueryV3OnChain-beta.1"
    case linkedMultiQuery = "linkedMultiQuery10-beta.1"
    
    var inputs: Data {
        get throws {
            return try Data(contentsOf: circuitsFolderUrl.appendingPathComponent("\(self.rawValue)_inputs.json"))
        }
    }
    var wcdGraph: Data {
        get throws {
            return try Data(contentsOf: circuitsFolderUrl.appendingPathComponent("\(self.rawValue).wcd"))
        }
    }
    var zkey: Data {
        get throws {
            return try Data(contentsOf: circuitsFolderUrl.appendingPathComponent("\(self.rawValue).zkey"))
        }
    }
    var zkeyPath: String {
        get {
            return circuitsFolderUrl.path + "/\(self.rawValue).zkey"
        }
    }
    var verificationKey: Data {
        get throws {
            return try Data(contentsOf: circuitsFolderUrl.appendingPathComponent("\(self.rawValue)_verification_key.json"))
        }
    }
}
