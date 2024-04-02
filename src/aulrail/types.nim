type PackageManagers* = enum
  none = "none"
  apm = "apm"
  butler = "butler"


type PackageManager* = object of RootObj
  appPath*: string
  usedInEnvEvidenceFilePath*: string


type EnvFileYamlLaunchConfiguration* = object
  aviutl_app_path*: string
  args*: seq[string]


type EnvFileYaml* = object
  aulrail_core_version*: string
  name*: string
  description*: string
  package_manager*: PackageManagers
  launch_configration*: EnvFileYamlLaunchConfiguration


type ErrorKind* = enum
  fileDoesNotExists,
  failedToLaunchAviutl,
  dirAlreadyExists,
  failedToCopyDir,
  failedToRemoveFile,
  packageManagerIsNotSet,
  failedToLaunchPackageManager,
  failedToUpdatePackages,
  failedToUpdatePackageManager,
  processFailed,
  dirAlreadyInitialized,
  invalidYaml,
  ioError,
  osError,
  writingStreamError,
  pacakgeManagerIsNotInstalled,
  envNotInitialized,


type Error* = object of CatchableError
  case kind*: ErrorKind
    of fileDoesNotExists,
       failedToLaunchAviutl,
       dirAlreadyExists,
       failedToRemoveFile,
       dirAlreadyInitialized,
       invalidYaml,
       writingStreamError,
       pacakgeManagerIsNotInstalled,
       envNotInitialized:
      path*: string
    of failedToCopyDir:
      src*: string
      dest*: string
    of processFailed:
      message*: string
    of failedToLaunchPackageManager,
       failedToUpdatePackages,
       failedToUpdatePackageManager:
      executedCommand*: string
    of packageManagerIsNotSet:
      discard
    of ioError:
      ioErrorObject*: ref IOError
    of osError:
      osErrorObject*: ref OSError
