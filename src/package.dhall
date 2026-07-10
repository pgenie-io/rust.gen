let Sdk = ./Deps/Sdk.dhall

let ProjectInterpreter = ./Interpreters/Project.dhall

let Config = { deadpool : Bool }

let defaultConfig = { deadpool = False }

in  Sdk.Sigs.generator Config defaultConfig ProjectInterpreter.run
