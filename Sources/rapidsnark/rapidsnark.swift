#if canImport(C)
    import C
#endif

import Darwin.C.string

public let DEFAULT_PROOF_BUFFER_SIZE = 1024;
public let DEFAULT_ERROR_BUFFER_SIZE = 256;

public func groth16Prove(
    zkey: String,
    witness: String,
    proofBufferSize: Int = DEFAULT_PROOF_BUFFER_SIZE,
    publicBufferSize: Int?,
    errorBufferSize: Int = DEFAULT_ERROR_BUFFER_SIZE
) throws -> (proof: String, pub_signals: String) {
    let zkeyBuf = zkey.toBuffer()
    let witnessBuf = witness.toBuffer()

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
    witness: String,
    proofBufferSize: Int = DEFAULT_PROOF_BUFFER_SIZE,
    publicBufferSize: Int?,
    errorBufferSize: Int = DEFAULT_ERROR_BUFFER_SIZE
) throws -> (proof: String, pub_signals: String) {
    let zkeyPathBuf = zkeyPath.toBuffer()
    let witnessBuf = witness.toBuffer()

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
        zkeyPathBuf,
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
    proof: String,
    inputs: String,
    verificationKey: String,
    errorBufferSize: Int = DEFAULT_ERROR_BUFFER_SIZE
) throws -> Bool {
    let proofBuf = proof.toBuffer()
    let inputsBuf = inputs.toBuffer()
    let verificationKeyBuf = verificationKey.toBuffer()

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
    zkey: String,
    errorBufferSize: Int = DEFAULT_ERROR_BUFFER_SIZE
) throws -> Int {
    let zkeyBuffer = zkey.toBuffer()

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
    let zkeyPathBuffer = zkeyPath.toBuffer()

    var errorMessageBuffer: [CChar] = Array(repeating: 0, count: errorBufferSize)

    var publicSize = 0

    let statusCode = groth16_public_size_for_zkey_file(
        zkeyPathBuffer,
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


extension String {
    func toBuffer() -> [CChar] {
        var buffer: [CChar] = Array(repeating: 0, count: count)
        strcpy(&buffer, self)
        return buffer
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
