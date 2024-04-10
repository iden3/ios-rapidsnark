#if canImport(C)
    import C
#endif

import Darwin.C.string

public let DEFAULT_PROOF_BUFFER_SIZE = 1024;
public let DEFAULT_ERROR_BUFFER_SIZE = 256;

public func groth16Prove(
    zkey: Data,
    witness: Data,
    proofBufferSize: Int = DEFAULT_PROOF_BUFFER_SIZE,
    publicBufferSize: Int? = nil,
    errorBufferSize: Int = DEFAULT_ERROR_BUFFER_SIZE
) throws -> (proof: String, publicSignals: String) {
    let zkeyBuf = NSData(data: zkey).bytes
    let witnessBuf = NSData(data: witness).bytes

    var public_buffer_size : Int;
    if let publicBufferSize {
        public_buffer_size = publicBufferSize;
    } else {
        public_buffer_size = try! groth16PublicSizeForZkeyBuf(zkey: zkey, errorBufferSize: errorBufferSize);
    }

    var proof_buffer_size = UInt(proofBufferSize);
    var proofBuffer = Array<CChar>(repeating: 0, count: proofBufferSize);

    var public_buffer_size_uint = UInt(public_buffer_size)
    var publicBuffer = Array<CChar>(repeating: 0, count: public_buffer_size)

    let error_buffer_size = UInt(errorBufferSize)
    var errorMessageBuffer: [CChar] = Array(repeating: 0, count: errorBufferSize)

    let statusCode = groth16_prover(
        zkeyBuf, UInt(zkey.count),
        witnessBuf, UInt(witness.count),
        &proofBuffer, &proof_buffer_size,
        &publicBuffer, &public_buffer_size_uint,
        &errorMessageBuffer, error_buffer_size
    );

    if (statusCode == PROVER_OK) {
        let proof = String(cString: proofBuffer)
        let publicSignals = String(cString: publicBuffer)

        return (proof, publicSignals)
    }

    let error = String(cString: errorMessageBuffer)

    if (statusCode == PROVER_ERROR) {
        throw RapidsnarkProverError.error(message: error);
    } else if (statusCode == PROVER_ERROR_SHORT_BUFFER) {
        throw RapidsnarkProverError.shortBuffer(message: error);
    } else if (statusCode == PROVER_INVALID_WITNESS_LENGTH) {
        throw RapidsnarkProverError.invalidWitnessLength(message: error);
    }

    throw RapidsnarkUnknownStatusError()
}

public func groth16ProveWithZKeyFilePath(
    zkeyPath: String,
    witness: Data,
    proofBufferSize: Int = DEFAULT_PROOF_BUFFER_SIZE,
    publicBufferSize: Int? = nil,
    errorBufferSize: Int = DEFAULT_ERROR_BUFFER_SIZE
) throws -> (proof: String, publicSignals: String) {
    let witnessBuf = NSData(data: witness).bytes

    var public_buffer_size : Int;
    if let publicBufferSize {
        public_buffer_size = publicBufferSize;
    } else {
        public_buffer_size = try! groth16PublicSizeForZkeyFile(zkeyPath: zkeyPath, errorBufferSize: errorBufferSize);
    }

    var proof_buffer_size = UInt(proofBufferSize);
    var proofBuffer = Array<CChar>(repeating: 0, count: proofBufferSize);

    var public_buffer_size_uint = UInt(public_buffer_size)
    var publicBuffer = Array<CChar>(repeating: 0, count: public_buffer_size)

    let error_buffer_size = UInt(errorBufferSize)
    var errorMessageBuffer: [CChar] = Array(repeating: 0, count: errorBufferSize)

    let statusCode = groth16_prover_zkey_file(
        zkeyPath,
        witnessBuf, UInt(witness.count),
        &proofBuffer, &proof_buffer_size,
        &publicBuffer, &public_buffer_size_uint,
        &errorMessageBuffer, error_buffer_size
    );

    if (statusCode == PROVER_OK) {
        let proof = String(cString: proofBuffer)
        let publicSignals = String(cString: publicBuffer)

        return (proof, publicSignals)
    }

    let error = String(cString: errorMessageBuffer)

    if (statusCode == PROVER_ERROR) {
        throw RapidsnarkProverError.error(message: error);
    } else if (statusCode == PROVER_ERROR_SHORT_BUFFER) {
        throw RapidsnarkProverError.shortBuffer(message: error);
    } else if (statusCode == PROVER_INVALID_WITNESS_LENGTH) {
        throw RapidsnarkProverError.invalidWitnessLength(message: error);
    }

    throw RapidsnarkUnknownStatusError()
}

public func groth16Verify(
    proof: Data,
    inputs: Data,
    verificationKey: Data,
    errorBufferSize: Int = DEFAULT_ERROR_BUFFER_SIZE
) throws -> Bool {
    let proofBuf = NSData(data: proof).bytes
    let inputsBuf = NSData(data: inputs).bytes
    let verificationKeyBuf = NSData(data: verificationKey).bytes

    var errorMessageBuffer: [CChar] = Array(repeating: 0, count: errorBufferSize)

    let result = groth16_verify(
        proofBuf,
        inputsBuf,
        verificationKeyBuf,
        &errorMessageBuffer,
        UInt(errorBufferSize)
    );

    if (result == VERIFIER_VALID_PROOF) {
        return true;
    }

    let error = String(cString: errorMessageBuffer)

    if (result == VERIFIER_INVALID_PROOF) {
        throw RapidsnarkVerifierError.invalidProof(message: error)
    } else if (result == VERIFIER_ERROR) {
        throw RapidsnarkVerifierError.error(message: error)
    }

    throw RapidsnarkUnknownStatusError()
}

public func groth16PublicSizeForZkeyBuf(
    zkey: Data,
    errorBufferSize: Int = DEFAULT_ERROR_BUFFER_SIZE
) throws -> Int {
    let zkeyBuffer = NSData(data: zkey).bytes

    var errorMessageBuffer: [CChar] = Array(repeating: 0, count: errorBufferSize)

    var publicSize = 0

    let statusCode = groth16_public_size_for_zkey_buf(
        zkeyBuffer,
        UInt(zkey.count),
        &publicSize,
        &errorMessageBuffer,
        UInt(errorBufferSize)
    );

    if (statusCode == PROVER_OK) {
        return publicSize
    } else {
        let error = String(cString: errorMessageBuffer)
        throw RapidsnarkProverError.error(message: error)
    }
}

public func groth16PublicSizeForZkeyFile(
    zkeyPath: String,
    errorBufferSize: Int = DEFAULT_ERROR_BUFFER_SIZE
) throws -> Int {
    var errorMessageBuffer: [CChar] = Array(repeating: 0, count: errorBufferSize)

    var publicSize = 0

    let statusCode = groth16_public_size_for_zkey_file(
        zkeyPath,
        &publicSize,
        &errorMessageBuffer,
        UInt(errorBufferSize)
    );

    if (statusCode == PROVER_OK) {
        return publicSize
    } else {
        let error = String(cString: errorMessageBuffer)
        throw RapidsnarkProverError.error(message: error)
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
}
