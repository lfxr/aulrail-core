import
  os,
  osproc

import
  constants,
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
) =
  ## 環境を初期化する
  if env.path.fileExists and not isForce:
    echo "すでに環境が初期化されています"
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


proc launch*(env: ref Env) =
  ## 環境を起動する
  # envファイルを読み込む
  let
    envFileYaml = env.envFile.load
    launchConfiguration = envFileYaml.launch_configration
  # AviUtlを起動する
  discard execProcess(
    "./" & launchConfiguration.aviutl_app_path,
    workingDir=env.path,
    args=launchConfiguration.args,
    options={}
  )


proc launchPackageManager*(
    env: ref Env,
    options: tuple[
      newWindow: bool = false
    ]
) =
  ## パッケージマネージャを起動する
  # envファイルを読み込む
  let
    envFileYaml = env.envFile.load
  # envファイルで指定されたパッケージマネージャを起動する
  case envFileYaml.package_manager:
    of PackageManagers.none:
      echo "パッケージマネージャが設定されていません"
    of PackageManagers.apm:
      discard execProcess(apmExePath, options={})
    of PackageManagers.butler:
      if options.newWindow:
        discard execShellCmd(butlerLaunchInNewWindowCommand(env.path))
      else:
        discard execCmd(butlerLanchCommand)


proc openDir*(env: ref Env) =
  ## 環境のディレクトリを開く
  openExplorer(env.path)


proc dupelicate*(env: ref Env, newEnvDirName: string) =
  ## 環境を複製する
  let newEnvDirPath = env.path / newEnvDirName
  if newEnvDirPath.fileExists:
    echo "すでに同名のディレクトリが存在します"
  else:
    env.path.copyDir(newEnvDirPath)


proc remove*(env: ref Env) =
  ## 環境を削除する
  # envファイルを削除
  removeFile(env.path / envFileName)
