#if canImport(rapidsnarkC)
import rapidsnarkC
#endif

import Darwin.C.string
import Foundation

public let defaultProofBufferSize = 1024
public let defaultErrorBufferSize = 256

/**
 Performs cryptographic proofs using the Groth16 proving scheme
 
 - Parameters:
 - zkey: The zkey data used to generate the proof.
 - witness: The witness data used to generate the proof.
 - proofBufferSize: The size of the buffer to store the proof. Defaults to a predefined value.
 - publicBufferSize: The size for the public signal buffer. If not provided, it's calculated dynamically.
 - errorBufferSize: The size of the buffer for error messages. Defaults to a predefined value.
 
 - Throws: `RapidsnarkProverError` child classes
 if the proof generation fails, with the error message indicating the reason for failure.
 
 - Returns: A tuple containing the generated proof as a string and the public signals as a string.
 */
public func groth16Prove(
    zkey: Data,
    witness: Data,
    proofBufferSize: Int = defaultProofBufferSize,
    publicBufferSize: Int? = nil,
    errorBufferSize: Int = defaultErrorBufferSize
) throws -> (proof: String, publicSignals: String) {
    let zkeyBuf = NSData(data: zkey).bytes
    let witnessBuf = NSData(data: witness).bytes
    
    // calculate the size for the public signal buffer if not provided
    var currentPublicBufferSize : Int;
    if let publicBufferSize {
        currentPublicBufferSize = publicBufferSize;
    } else {
        currentPublicBufferSize = try groth16PublicSizeForZkeyBuf(zkey: zkey, errorBufferSize: errorBufferSize);
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

/**
 Performs cryptographic proofs using the Groth16 proving scheme.
 
 - Parameters:
 - zkeyPath: The path to the .zkey file.
 - witness: The witness data used to generate the proof.
 - proofBufferSize: The size of the buffer to store the proof. Defaults to a predefined value.
 - publicBufferSize: The size for the public signal buffer. If not provided, it's calculated dynamically.
 - errorBufferSize: The size of the buffer for error messages. Defaults to a predefined value.
 
 - Throws: `RapidsnarkProverError` child classes
 if the proof generation fails, with the error message indicating the reason for failure.
 
 - Returns: A tuple containing the generated proof as a string and the public signals as a string.
 */
public func groth16ProveWithZKeyFilePath(
    zkeyPath: String,
    witness: Data,
    proofBufferSize: Int = defaultProofBufferSize,
    publicBufferSize: Int? = nil,
    errorBufferSize: Int = defaultErrorBufferSize
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

/**
 Verifying proofs using the Groth16 scheme.
 
 - Parameters:
 - proof: The proof data to be verified.
 - inputs: The input data used for verification.
 - verificationKey: The verification key data used for verification.
 - errorBufferSize: The size of the buffer for error messages. Defaults to a predefined value.
 
 - Throws: `RapidsnarkVerifierError` child classes
 if the proof verification fails, with the error message indicating the reason for failure.
 
 - Returns: A boolean value indicating whether the proof is valid (`true`) or not (`false`).
 */
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
    } else if (statusCode == VERIFIER_INVALID_PROOF) {
        throw RapidsnarkVerifierError.invalidProof(message: String(cString: errorMessageBuffer))
    } else if (statusCode == VERIFIER_ERROR) {
        throw RapidsnarkVerifierError.error(message: String(cString: errorMessageBuffer))
    } else {
        throw RapidsnarkUnknownStatusError(message: String(cString: errorMessageBuffer))
    }
}


/**
 Calculates the size of the public signal buffer based on the provided zkey file data.
 
 - Parameters:
 - zkey: The zkey data used to calculate the public signal buffer size.
 - errorBufferSize: The size of the buffer for error messages. Defaults to a predefined value.
 
 - Throws: `RapidsnarkProverError` child classes
 if the calculation of the public signal buffer size fails, with the error message indicating the reason for failure.
 
 - Returns: An integer value representing the calculated size of the public signal buffer.
 */
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


/**
 Determine the necessary buffer size for storing public signals based on a provided .zkey file
 
 - Parameters:
 - zkeyPath: The path to the .zkey file used to calculate the public signal buffer size.
 - errorBufferSize: The size of the buffer for error messages. Defaults to a predefined value.
 
 - Throws: `RapidsnarkProverError` child classes
 if the calculation of the public signal buffer size fails, with the error message indicating the reason for failure.
 
 - Returns: An integer value representing the calculated size of the public signal buffer.
 */
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
    default:
        return RapidsnarkUnknownStatusError(message: message)
    }
}


public protocol RapidsnarkError : CustomNSError {
    var message: String { get }
}

public extension RapidsnarkError {
    var errorUserInfo: [String : Any] {
        return ["message": message]
    }
}

public enum RapidsnarkProverError : RapidsnarkError {
    case error(message: String)
    case shortBuffer(message: String)
    case invalidWitnessLength(message: String)
    
    public var message: String {
        switch self {
        case .error(let message):
            return message
        case .shortBuffer(let message):
            return message
        case .invalidWitnessLength(let message):
            return message
        }
    }
    
    public var errorCode: Int {
        switch self {
        case .error:
            return NSNumber(value: PROVER_ERROR).intValue
        case .shortBuffer:
            return NSNumber(value: PROVER_ERROR_SHORT_BUFFER).intValue
        case .invalidWitnessLength:
            return NSNumber(value: PROVER_INVALID_WITNESS_LENGTH).intValue
        }
    }
}

public enum RapidsnarkVerifierError : RapidsnarkError {
    case error(message: String)
    case invalidProof(message: String)
    
    public var message: String {
        switch self {
        case .error(let message):
            return message
        case .invalidProof(let message):
            return message
        }
    }

    public var errorCode: Int {
        switch self {
        case .error:
            return NSNumber(value: VERIFIER_ERROR).intValue
        case .invalidProof:
            return NSNumber(value: VERIFIER_INVALID_PROOF).intValue
        }
    }
}

public class RapidsnarkUnknownStatusError : RapidsnarkError {
    public let message: String

    init(message: String) {
        self.message = message
    }
    
    public var errorCode: Int {
        return -1
    }
}
