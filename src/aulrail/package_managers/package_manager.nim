import
  options,
  os,
  osproc

import
  ../result,
  ../types


func newPackageManager*(appPath: string): ref PackageManager =
  result = new PackageManager
  result.appPath = appPath


proc launch*(pm: ref PackageManager): Result[void] =
  ## PackageManagerを起動
  if not pm.appPath.fileExists:
    result.error = option(Error(
      kind: ErrorKind.fileDoesNotExists,
      path: pm.appPath
    ))
    return
  try:
    discard execProcess(pm.appPath, options={})
  except:
    result.error = option(Error(
      kind: ErrorKind.failedToLaunchPackageManager,
      executedCommand: pm.appPath
    ))


method updatePackages*(pm: ref PackageManager): Result[void] {.base.} =
  ## パッケージを更新
  result = pm.launch()
