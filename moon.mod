// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "hua1104/moon-resend"

version = "0.2.0"

readme = "README.mbt.md"

repository = "https://github.com/hua1104/moon-resend"

license = "Apache-2.0"

keywords = [ "resend", "email", "sdk", "saas", "moonbit" ]

preferred_target = "wasm"

description = "A typed MoonBit SDK for Resend with a moonfetch HTTP adapter"

import {
  "moonbitlang/async@0.22.5",
  "moonbitstack/moonfetch@0.1.8",
  "moonbitstack/mooncrypt@0.4.14",
}
