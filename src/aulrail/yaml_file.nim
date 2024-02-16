import
  os,
  streams

import
  yaml

import
  constants,
  types


type EnvFile* = object
  path*: string


proc newEnvFile*(envPath: string): EnvFile =
  result = EnvFile()
  result.path = envPath / envFileName


proc load*(envFile: EnvFile): EnvFileYaml =
  let fileStream = newFileStream(envFile.path)
  var envFileYaml: EnvFileYaml
  fileStream.load(envFileYaml)
  fileStream.close()


proc save*(envFile: EnvFile, envFileYaml: EnvFileYaml) =
  let fileStream = newFileStream(envFile.path, fmWrite)
  Dumper().dump(envFileYaml, fileStream)
  fileStream.close()
