import
  os,
  osproc

import
  options,
  ../result,
  ../types


type Butler* = object of PackageManager
  appPaths: tuple[
    ps, bat: string
  ]
  commands: tuple[
    launchInNewWindow, launchInCurrentWindow: string
  ]


func newButler*(envPath: string): ref Butler =
  ## Butlerオブジェクトを生成
  result = new Butler
  result.appPaths = (
    ps: envPath / ".butler/butler.ps1",
    bat: envPath / ".butler/butler.bat"
  )
  result.appPath = result.appPaths.bat
  result.commands = (
    launchInNewWindow: "start " & result.appPaths.bat,
    launchInCurrentWindow: "pwsh -ExecutionPolicy Bypass " & result.appPaths.ps
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


proc launch*(
    pm: ref Butler,
    options: tuple[inCurrentWindow: bool = false]
): Result[void] =
  ## BUtlerを起動する
  if not (pm.appPaths.ps.fileExists and pm.appPaths.bat.fileExists):
    result.error = option(Error(
      kind: ErrorKind.pacakgeManagerIsNotInstalled,
      path: pm.appPath
    ))
  if options.inCurrentWindow:
    pm.launchInCurrentWindow
  else:
    pm.launchInNewWindow
