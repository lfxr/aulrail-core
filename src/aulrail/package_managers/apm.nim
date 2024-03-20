import
  os

import
  ../types


type Apm* = object of PackageManager


func newApm*(): ref Apm =
  ## Apmオブジェクトを生成
  result = new Apm
  result.appPath = getHomeDir() / "AppData/Local/apm/apm.exe"
