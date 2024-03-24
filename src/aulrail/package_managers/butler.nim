import
  os,
  osproc

import
  options,
  ../constants,
  ../result,
  ../types


type Butler* = object of PackageManager
  appPaths: tuple[
    ps, bat: string
  ]
  commands: tuple[
    launchInNewWindow,
    launchInCurrentWindow,
    updatePackages,
    updateSelf: string
  ]


func newButler*(envPath: string): ref Butler =
  ## Butlerオブジェクトを生成
  result = new Butler
  result.appPaths = (
    ps: envPath / ".butler/butler.ps1",
    bat: envPath / ".butler/butler.bat"
  )
  result.appPath = result.appPaths.bat
  let launchInCurrentWindowCommand =
    "pwsh -ExecutionPolicy Bypass " & result.appPaths.ps
  result.commands = (
    launchInNewWindow: "start " & result.appPaths.bat,
    launchInCurrentWindow: launchInCurrentWindowCommand,
    updatePackages: launchInCurrentWindowCommand & " upgrade\n" & pauseCommand,
    updateSelf: launchInCurrentWindowCommand & " selfupgrade\n" & pauseCommand,
  )


proc launchInCurrentWindow(pm: ref Butler): Result[void] =
  ## BUtlerを既存のウィンドウで起動する
  let butlerLanchCommand = pm.commands.launchInCurrentWindow
  try:
    discard execCmd(butlerLanchCommand)
  except:
    result.error = option(Error(
      kind: ErrorKind.failedToLaunchPackageManager,
      executedCommand: butlerLanchCommand
    ))


proc launchInNewWindow(pm: ref Butler): Result[void] =
  ## BUtlerを新しいウィンドウで起動する
  let butlerLaunchInNewWindowCommand = pm.commands.launchInNewWindow
  try:
    discard execShellCmd(butlerLaunchInNewWindowCommand)
  except:
    result.error = option(Error(
      kind: ErrorKind.failedToLaunchPackageManager,
      executedCommand: butlerLaunchInNewWindowCommand
    ))


method launch*(
    pm: ref Butler,
    options: tuple[inCurrentWindow: bool] = (inCurrentWindow: false)
): Result[void] =
  ## BUtlerを起動する
  if not (pm.appPaths.ps.fileExists and pm.appPaths.bat.fileExists):
    result.error = option(Error(
      kind: ErrorKind.pacakgeManagerIsNotInstalled,
      path: pm.appPath
    ))
    return
  return
    if options.inCurrentWindow:
      pm.launchInCurrentWindow
    else:
      pm.launchInNewWindow


method updatePackages*(pm: ref Butler): Result[void] =
  ## BUtlerでパッケージを更新する
  let updatePackagesCommand = pm.commands.updatePackages
  try:
    discard execShellCmd(updatePackagesCommand)
  except:
    result.error = option(Error(
      kind: ErrorKind.failedToUpdatePackages,
      executedCommand: updatePackagesCommand
    ))


method updateSelf*(pm: ref Butler): Result[void] =
  ## BUtler自体を更新する
  let updateSelfCommand = pm.commands.updateSelf
  try:
    discard execShellCmd(updateSelfCommand)
  except:
    result.error = option(Error(
      kind: ErrorKind.failedToUpdatePackageManager,
      executedCommand: updateSelfCommand
    ))
