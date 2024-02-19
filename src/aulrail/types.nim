type PackageManagers* = enum
  none = "none"
  apm = "apm"
  butler = "butler"


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

type Error* = object of CatchableError
  case kind*: ErrorKind
    of fileDoesNotExists,
       failedToLaunchAviutl,
       dirAlreadyExists,
       failedToRemoveFile:
      path: string
    of failedToCopyDir:
      src: string
      dest: string
