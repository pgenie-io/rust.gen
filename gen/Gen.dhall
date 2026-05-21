let Sdk = ./Deps/GenSdk.dhall

in  Sdk.module { major = 2, minor = 0 } ./Config.dhall ./compile.dhall
