import
  options,
  os,
  osproc

import
  constants,
  result,
  types,
  utils,
  yaml_file


type Env = object
  path: string
  envFile: EnvFile


func newEnv*(path: string): ref Env =
  result = new Env
  result.path = path
  result.envFile = newEnvFile(path)


func init*(
    env: ref Env,
    envData = tuple[
      name: string,
      description: string = "",
      packageManager: PackageManagers,
    ],
    isForce: bool = false
): Result =
  ## 環境を初期化する
  # 環境ディレクトリがすでに存在する場合はエラーを返す
  if env.path.fileExists and not isForce:
    result.error = option(Error(
      kind: ErrorKind.dirAlreadyInitialized,
      path: env.path
    ))
  else:
    # envファイルを作成
    let envFileYaml = EnvFileYaml(
      aulrail_core_version: aulrailCoreVersion,
      name: envData.name,
      description: envData.description,
      package_manager: envData.packageManager
    )
    env.envFile.save(envFileYaml)


func path*(env: ref Env): string =
  ## 環境のパスを取得する
  result = env.path


proc launch*(env: ref Env): Result =
  ## 環境を起動する
  # envファイルを読み込む
  let
    envFileYaml = env.envFile.load
    launchConfiguration = envFileYaml.launch_configration
    aviutlAppPath = launchConfiguration.aviutl_app_path
  # AviUtlが存在しない場合はエラーを返す
  if not aviutlAppPath.fileExists:
    result.error = option(Error(
      kind: ErrorKind.fileDoesNotExists,
      path: aviutlAppPath
    ))
  # AviUtlを起動する
  try:
    discard execProcess(
      "./" & aviutlAppPath,
      workingDir=env.path,
      args=launchConfiguration.args,
      options={}
    )
  except:
    result.error = option(Error(
      kind: ErrorKind.failedToLaunchAviutl,
      path: aviutlAppPath
    ))


proc launchPackageManager*(
    env: ref Env,
    options: tuple[
      newWindow: bool = false
    ]
): Result =
  ## パッケージマネージャを起動する
  # envファイルを読み込む
  let
    envFileYaml = env.envFile.load
  # envファイルで指定されたパッケージマネージャを起動する
  case envFileYaml.package_manager:
    of PackageManagers.none:
      # パッケージマネージャが設定されていないのでエラーを返す
      result.error = option(Error(
        kind: ErrorKind.packageManagerIsNotSet,
      ))
    of PackageManagers.apm:
      # apmがインストールされていない場合はエラーを返す
      if not apmExePath.fileExists:
        result.error = option(Error(
          kind: ErrorKind.apmIsNotInstalled,
          path: apmExePath
        ))
      else:
        try:
          discard execProcess(apmExePath, options={})
        except:
          result.error = option(Error(
            kind: ErrorKind.failedToLaunchPackageManager,
            path: apmExePath
          ))
    of PackageManagers.butler:
      let butlerPsPath = butlerPsPath(env.path)
      # butlerがインストールされていな場合はエラーを返す
      if not butlerPsPath.fileExists:
        result.error = option(Error(
          kind: ErrorKind.butlerIsNotInstalled,
          path: butlerPsPath
        ))
        return
      if options.newWindow:
        # butlerを新しいウィンドウで起動する
        let butlerLaunchInNewWindowCommand =
          butlerLaunchInNewWindowCommand(env.path)
        try:
          discard execShellCmd(butlerLaunchInNewWindowCommand)
        except:
          result.error = option(Error(
            kind: ErrorKind.failedToLaunchPackageManager,
            executedCommand: butlerLaunchInNewWindowCommand
          ))
      else:
        # butlerを既存のウィンドウで起動する
        let butlerLanchCommand = butlerLanchCommand(env.path)
        try:
          discard execCmd(butlerLanchCommand)
        except:
          result.error = option(Error(
            kind: ErrorKind.failedToLaunchPackageManager,
            executedCommand: butlerLanchCommand
          ))


proc openDir*(env: ref Env): Result =
  ## 環境のディレクトリを開く
  openExplorer(env.path)


proc dupelicate*(env: ref Env, newEnvDirName: string): Result =
  ## 環境を複製する
  let newEnvDirPath = env.path.parentDir / newEnvDirName
  # 新しい環境ディレクトリがすでに存在する場合はエラーを返す
  if newEnvDirPath.dirExists:
    result.error = option(Error(
        kind: ErrorKind.dirAlreadyExists,
        path: newEnvDirPath
    ))
  else:
    # 環境ディレクトリを複製する
    try:
      env.path.copyDir(newEnvDirPath)
    except:
      result.error = option(Error(
        kind: ErrorKind.failedToCopyDir,
        src: env.path,
        dest: newEnvDirPath
      ))


proc remove*(env: ref Env): Result =
  ## 環境を削除する
  let envFilePath = env.envFile.path
  # envファイルが存在しない場合はエラーを返す
  if not envFilepath.fileExists:
    result.error = option(Error(
        kind: ErrorKind.fileDoesNotExists,
        path: envFilePath
    ))
  # envファイルの削除に失敗した場合はエラーを返す
  if not tryRemoveFile(envFilePath):
    result.error = option(Error(
        kind: ErrorKind.failedToRemoveFile,
        path: envFilePath
    ))
