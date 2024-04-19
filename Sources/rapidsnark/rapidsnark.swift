#if canImport(C)
    import C
#endif

import Darwin.C.string
import Foundation

public let defaultProofBufferSize = 1024
public let defaultErrorBufferSize = 256

// Performs cryptographic proofs using the Groth16 proving scheme
public func groth16Prove(
    zkey: Data,
    witness: Data,
    proofBufferSize: Int = defaultProofBufferSize, // Optional: Sets the size of the buffer to store the proof, with a default size
    publicBufferSize: Int? = nil, // Optional: the  size for the public signal buffer, otherwise calculated dynamically
    errorBufferSize: Int = defaultErrorBufferSize // Optional: the size of the buffer for error messages
) throws -> (proof: String, publicSignals: String) {
    let zkeyBuf = NSData(data: zkey).bytes
    let witnessBuf = NSData(data: witness).bytes

    // calculate the size for the public signal buffer if not provided
    var currentPublicBufferSize : Int;
    if let publicBufferSize {
        currentPublicBufferSize = publicBufferSize;
    } else {
        do{
            currentPublicBufferSize = try groth16PublicSizeForZkeyBuf(zkey: zkey, errorBufferSize: errorBufferSize);
        }catch{
            throw error
        }
    }

    var proofBuffer = Array<CChar>(repeating: 0, count: proofBufferSize);
    var publicBuffer = Array<CChar>(repeating: 0, count: currentPublicBufferSize)
    var errorMessageBuffer: [CChar] = Array(repeating: 0, count: errorBufferSize)
    
    var proofBufferSizeUInt = UInt(proofBufferSize)
    var currentPublicBufferSizeUInt = UInt(currentPublicBufferSize)
    let errorBufferSizeUInt = UInt(errorBufferSize)

    // Call the rapidsnark C++ library function to perform the Groth16 proof
    let statusCode = groth16_prover(
        zkeyBuf, UInt(zkey.count),
        witnessBuf, UInt(witness.count),
        &proofBuffer, &proofBufferSizeUInt,
        &publicBuffer, &currentPublicBufferSizeUInt,
        &errorMessageBuffer, errorBufferSizeUInt
    );

    if (statusCode == PROVER_OK) {
        return (String(cString: proofBuffer), String(cString: publicBuffer))
    }

    throw groth16proverStatusCodeErrors(statusCode, message: String(cString: errorMessageBuffer))
}

// Performs cryptographic proofs using the Groth16 proving scheme
public func groth16ProveWithZKeyFilePath(
    zkeyPath: String, // Path to .zkey file
    witness: Data,
    proofBufferSize: Int = defaultProofBufferSize, // Optional: Sets the size of the buffer to store the proof, with a default size
    publicBufferSize: Int? = nil, // Optional: the  size for the public signal buffer, otherwise calculated dynamically
    errorBufferSize: Int = defaultErrorBufferSize // Optional: the size of the buffer for error messages
) throws -> (proof: String, publicSignals: String) {
    let witnessBuf = NSData(data: witness).bytes

    // calculate the size for the public signal buffer if not provided
    var currentPublicBufferSize : Int;
    if let publicBufferSize {
        currentPublicBufferSize = publicBufferSize;
    } else {
        currentPublicBufferSize = try groth16PublicSizeForZkeyFile(zkeyPath: zkeyPath, errorBufferSize: errorBufferSize);
    }
    
    var proofBuffer = Array<CChar>(repeating: 0, count: proofBufferSize);
    var publicBuffer = Array<CChar>(repeating: 0, count: currentPublicBufferSize)
    var errorMessageBuffer: [CChar] = Array(repeating: 0, count: errorBufferSize)

    var proofBufferSizeUInt = UInt(proofBufferSize)
    var currentPublicBufferSizeUInt = UInt(currentPublicBufferSize)
    let errorBufferSizeUInt = UInt(errorBufferSize)
    
    // Call the rapidsnark C++ library function to perform the Groth16 proof
    let statusCode = groth16_prover_zkey_file(
        zkeyPath,
        witnessBuf, UInt(witness.count),
        &proofBuffer, &proofBufferSizeUInt,
        &publicBuffer, &currentPublicBufferSizeUInt,
        &errorMessageBuffer, errorBufferSizeUInt
    );

    if (statusCode == PROVER_OK) {
        return (String(cString: proofBuffer), String(cString: publicBuffer))
    }

    throw groth16proverStatusCodeErrors(statusCode, message: String(cString: errorMessageBuffer))
}

// Verifying proofs using the Groth16 scheme.
public func groth16Verify(
    proof: Data,
    inputs: Data,
    verificationKey: Data,
    errorBufferSize: Int = defaultErrorBufferSize
) throws -> Bool {
    let proofBuf = NSData(data: proof).bytes
    let inputsBuf = NSData(data: inputs).bytes
    let verificationKeyBuf = NSData(data: verificationKey).bytes

    var errorMessageBuffer: [CChar] = Array(repeating: 0, count: errorBufferSize)

    // Call the rapidsnark C++ library function to perform the Groth16 Verification
    let statusCode = groth16_verify(
        proofBuf,
        inputsBuf,
        verificationKeyBuf,
        &errorMessageBuffer,
        UInt(errorBufferSize)
    );

    if (statusCode == VERIFIER_VALID_PROOF) {
        return true;
    }
    
    throw groth16proverStatusCodeErrors(statusCode, message: String(cString: errorMessageBuffer))
}

public func groth16PublicSizeForZkeyBuf(
    zkey: Data,
    errorBufferSize: Int = defaultErrorBufferSize
) throws -> Int {
    let zkeyBuffer = NSData(data: zkey).bytes

    var errorMessageBuffer: [CChar] = Array(repeating: 0, count: errorBufferSize)

    var size = 0

    let statusCode = groth16_public_size_for_zkey_buf(
        zkeyBuffer,
        UInt(zkey.count),
        &size,
        &errorMessageBuffer,
        UInt(errorBufferSize)
    );

    if (statusCode == PROVER_OK) {
        return size
    }
    
    throw RapidsnarkProverError.error(message: String(cString: errorMessageBuffer))
}


// Determine the necessary buffer size for storing public signals
// based on a provided .zkey file
public func groth16PublicSizeForZkeyFile(
    zkeyPath: String,
    errorBufferSize: Int = defaultErrorBufferSize
) throws -> Int {
    var errorMessageBuffer: [CChar] = Array(repeating: 0, count: errorBufferSize)

    var size = 0

    let statusCode = groth16_public_size_for_zkey_file(
        zkeyPath,
        &size,
        &errorMessageBuffer,
        UInt(errorBufferSize)
    );

    if (statusCode == PROVER_OK) {
        return size
    }
    
    throw RapidsnarkProverError.error(message: String(cString: errorMessageBuffer))
}

// Helper function to convert the status code and message into a specific error type
private func groth16proverStatusCodeErrors(_ statusCode: Int32, message: String) -> RapidsnarkError {
    switch statusCode {
    case PROVER_ERROR:
        return RapidsnarkProverError.error(message: message)
    case PROVER_ERROR_SHORT_BUFFER:
        return RapidsnarkProverError.shortBuffer(message: message)
    case PROVER_INVALID_WITNESS_LENGTH:
        return RapidsnarkProverError.invalidWitnessLength(message: message)
    case VERIFIER_INVALID_PROOF:
        return RapidsnarkVerifierError.invalidProof(message: message)
    case VERIFIER_ERROR:
        return RapidsnarkVerifierError.error(message: message)
    default:
        return RapidsnarkUnknownStatusError(message: message)
    }
}


public protocol RapidsnarkError : Error {
}

public enum RapidsnarkProverError : RapidsnarkError {
    case error(message: String)
    case shortBuffer(message: String)
    case invalidWitnessLength(message: String)
}

public enum RapidsnarkVerifierError : RapidsnarkError {
    case error(message: String)
    case invalidProof(message: String)
}

public class RapidsnarkUnknownStatusError : RapidsnarkError {
    let message: String
    
    init(message: String) {
        self.message = message
    }
}
