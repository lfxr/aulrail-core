import
  options,
  os,
  osproc,
  sequtils

import
  constants,
  package_manager,
  result,
  types,
  utils,
  yaml_file


const DummyCoreVersions = (
  aviutl: "1.10",
  exedit: "0.92"
)


type Env = object
  path: string
  envFile: EnvFile


func newEnv*(path: string): ref Env =
  result = new Env
  result.path = path
  result.envFile = newEnvFile(path)


proc isInitialized*(env: ref Env): bool =
  ## 環境が初期化されているかどうかを返す
  return env.envFile.path.fileExists


proc detectAulCoreVersions*(env: ref Env): CoreVersions =
  ## 使用されているAviUtl本体と拡張編集のバージョンを検出する
  return DummyCoreVersions


proc detectPackageManager*(env: ref Env): PackageManagers =
  ## 使用されているパッケージマネージャーを検出する
  let packageManagers = [
    (
      packageManager: PackageManagers.apm,
      evidenceFilePath: newApm().usedInEnvEvidenceFilePath
    ),
    (
      packageManager: PackageManagers.butler,
      evidenceFilePath: newButler("").usedInEnvEvidenceFilePath
    )
  ]
  # 環境のディレクトリを再帰的に探索してパッケージマネージャーの証拠ファイルがあるか調べる
  for file in walkDirRec(env.path, relative = true):
    for packageManager in packageManagers:
      if file == packageManager.evidenceFilePath:
        return packageManager.packageManager

  # パッケージマネージャーの証拠ファイルが見つからなかった場合は,
  # パッケージマネージャーが設定されていないと判断する
  return PackageManagers.none


proc isSetUp*(env: ref Env): bool =
  ## 環境がセットアップ済みかどうかを返す
  # パッケージマネージャーが検出された場合にはセットアップ済みと判断する
  if env.detectPackageManager != PackageManagers.none:
    return true
  # AviUtl・Exedit本体のファイルが1つでも存在する場合には,
  # セットアップ済みと判断する
  const AulCoreEvidenceFilePaths = [
    "aviutl.exe",
    "aviutl.sav",
    "exedit.anm",
    "exedit.auf",
    "exedit.auo",
    "exedit.cam",
    "exedit.ini",
    "exedit.obj",
    "exedit.scn",
    "exedit.tra",
  ]
  return AulCoreEvidenceFilePaths.filterIt(fileExists(env.path / it)).len > 0


proc init*(
    env: ref Env,
    envData: tuple[
      name: string,
      description: string = "",
      packageManager: PackageManagers,
    ],
    isForce: bool = false
): Result[void] =
  ## 環境を初期化する
  # 環境ディレクトリがすでに存在する場合はエラーを返す
  if env.isInitialized and not isForce:
    result.error = option(Error(
      kind: ErrorKind.dirAlreadyInitialized,
      path: env.path
    ))
    return
  if not env.path.dirExists:
    result.error = option(Error(
      kind: ErrorKind.dirDoesNotExists,
      path: env.path
    ))
    return
  # envファイルを作成
  if env.isSetUp:
    # 環境がセットアップ済みの場合,
    # AviUtlのコアのバージョンとパッケージマネージャーを検出し,
    # envファイルを作成する
    let envFileYaml = EnvFileYaml(
      aulrail_core_version: aulrailCoreVersion,
      name: envData.name,
      description: envData.description,
      package_manager: env.detectPackageManager, 
    )
    let writingEnvFileYamlResult = env.envFile.save(envFileYaml)
    if writingEnvFileYamlResult.isError:
      result.error = writingEnvFileYamlResult.error
      return
  else:
    # TODO: implement later
    discard


func path*(env: ref Env): string =
  ## 環境のパスを取得する
  result = env.path


proc launch*(env: ref Env): Result[void] =
  ## 環境を起動する
  # envファイルを読み込む
  let envFileYaml = env.envFile.load
  if envFileYaml.isError:
    result.error = envFileYaml.error
    return
  let
    launchConfiguration = envFileYaml.result.launch_configration
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


proc packageManager*(env: ref Env): Result[ref PackageManager] =
  ## 環境のパッケージマネージャを取得する
  let envFileYaml = env.envFile.load
  if envFileYaml.isError:
    result.error = envFileYaml.error
    return
  case envFileYaml.result.package_manager:
    of PackageManagers.none:
      result.error = option(Error(
        kind: ErrorKind.packageManagerIsNotSet,
      ))
    of PackageManagers.apm:
      result.result = newApm()
    of PackageManagers.butler:
      result.result = newButler(env.path)


proc openDir*(env: ref Env): Result[void] =
  ## 環境のディレクトリを開く
  openExplorer(env.path)


proc dupelicate*(env: ref Env, newEnvDirName: string): Result[void] =
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


proc remove*(env: ref Env): Result[void] =
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
