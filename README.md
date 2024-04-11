# rapidsnark

---

This library is Swift wrapper for the [Rapidsnark](https://github.com/iden3/rapidsnark). It enables the
generation of proofs for specified circuits within an iOS environment.

## Platform Support

**iOS**: Compatible with any iOS device with 64 bit architecture.
> Version for emulator built without assembly optimizations, resulting in slower performance.

**macOS**: Not supported yet.

## Requirements

- iOS 12.0+

## Installation

rapidsnark is available through [CocoaPods](https://cocoapods.org) and [SPM](https://www.swift.org/documentation/package-manager/).
To install it, simply add the following line to your Podfile:

```ruby
pod 'rapidsnark'
```

or add it to your project SPM dependencies in XCode.

## Usage


#### groth16ProveWithZKeyFilePath

Function takes path to .zkey file and witness file (as base64 encoded String) and returns proof and public signals.

Reads .zkey file directly from filesystem.


```Swift
import rapidsnark

// ...

let zkeyPath = "path/to/zkey";
let wtns = PackageManager.default.contents(atPath: "path/to/wtns")?.base64EncodedString(options: .endLineWithLineFeed);

let (proof, publicSignals) = groth16ProveWithZKeyFilePath(zkeyPath, wtns);
```

#### groth16Verify

Verifies proof and public signals against verification key.

```Swift
import rapidsnark

// ...

let zkey = PackageManager.default.contents(atPath: "path/to/zkey")?.base64EncodedString(options: .endLineWithLineFeed);
let wtns = PackageManager.default.contents(atPath: "path/to/wtns")?.base64EncodedString(options: .endLineWithLineFeed);
let verificationKey = PackageManager.default.contents(atPath: "path/to/verification_key")?.base64EncodedString(options: .endLineWithLineFeed);

let (proof, publicSignals) = await groth16Prove(zkey, wtns);

let proofValid = groth16Verify(proof, publicSignals, verificationKey);
```

#### groth16Prove

Function that takes zkey and witness files encoded as base64.

`proof` and `publicSignals` are base64 encoded strings.

>Large circuits might cause OOM. Use with caution.

```Swift
import rapidsnark

// ...

let zkey = PackageManager.default.contents(atPath: "path/to/zkey")?.base64EncodedString(options: .endLineWithLineFeed);
let wtns = PackageManager.default.contents(atPath: "path/to/wtns")?.base64EncodedString(options: .endLineWithLineFeed);

let (proof, publicSignals) = await groth16Prove(zkey, wtns);
```
#### groth16PublicSizeForZkeyFile

Calculates public buffer size for specified zkey.

```Swift
import rapidsnark

// ...

let publicBufferSize = await groth16PublicSizeForZkeyFile("path/to/zkey");
```

### Public buffer size

Both `groth16Prove` and `groth16ProveWithZKeyFilePath` has an optional `proofBufferSize`, `publicBufferSize` and `errorBufferSize`  parameters. 
If `publicBufferSize` is too small it will be calculated automatically by library.

These parameters are used to set the size of the buffers used to store the proof, public signals and error.

If you have embedded circuit in the app, it is recommended to calculate the size of the public buffer once and reuse it.
To calculate the size of public buffer call `groth16PublicSizeForZkeyFile`.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.
Then open the `rapidsnark.xcworkspace` file in XCode and run it on iOS device or simulator.

## License

ios-rapidsnark is part of the iden3 project 0KIMS association. Please check the [COPYING](./COPYING) file for more details.
