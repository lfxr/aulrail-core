import
  os,
  streams

import
  yaml,
  yaml/presenter

import
  constants,
  options,
  result,
  types


type EnvFile* = object
  path*: string


proc newEnvFile*(envPath: string): EnvFile =
  result = EnvFile()
  result.path = envPath / envFileName


proc load*(envFile: EnvFile): Result[EnvFileYaml] =
  let envFilePath = envFile.path
  if not envFilePath.fileExists:
    result.error = option(Error(
      kind: ErrorKind.fileDoesNotExists,
      path: envFilePath
    ))
    return
  let fileStream = newFileStream(envFilePath)
  var envFileYaml: EnvFileYaml
  try:
    fileStream.load(envFileYaml)
  except YamlConstructionError:
    result.error = option(Error(
      kind: ErrorKind.invalidYaml,
      path: envFilePath
    ))
  except IOError as e:
    result.error = option(Error(
      kind: ErrorKind.ioError,
      ioErrorObject: e
    ))
  except OSError as e:
    result.error = option(Error(
      kind: ErrorKind.osError,
      osErrorObject: e
    ))
  fileStream.close()


proc save*(envFile: EnvFile, envFileYaml: EnvFileYaml): Result[void] =
  let fileStream = newFileStream(envFile.path, fmWrite)
  try:
    Dumper().dump(envFileYaml, fileStream)
  except YamlPresenterOutputError:
    result.error = option(Error(
      kind: ErrorKind.writingStreamError,
      path: envFile.path
    ))
  except YamlPresenterJsonError, YamlSerializationError:
    result.error = option(Error(
      kind: ErrorKind.invalidYaml,
      path: envFile.path
    ))
  fileStream.close()
