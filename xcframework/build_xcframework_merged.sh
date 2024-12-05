# This scripts creates merged library for arm64 only for both sim and ios, and then creates xcframework from it.

rm -rf ../Libs/Rapidsnark.xcframework

libtool -static -o ios/librapidsnarkmerged.a ios/libfq.a ios/libfr.a ios/libgmp.a ios/librapidsnark.a \
&& \
libtool -static -o sim/librapidsnarkmerged.a sim/libfq.a sim/libfr.a sim/libgmp.a sim/librapidsnark.a \
&& \
libtool -static -o macos/librapidsnarkmerged.a macos/libfq.a macos/libfr.a macos/libgmp.a macos/librapidsnark.a -arch_only arm64 \
&& \
xcodebuild -create-xcframework \
-library ios/librapidsnarkmerged.a \
-headers headers \
-library sim/librapidsnarkmerged.a \
-headers headers \
-library macos/librapidsnarkmerged.a \
-headers headers \
-output ../Libs/Rapidsnark.xcframework \
