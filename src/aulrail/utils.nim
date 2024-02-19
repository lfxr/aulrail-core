import
  os,
  osproc

import
  options,
  result,
  types


proc openExplorer*(path: string): Result =
  if not path.fileExists:
    result.error = option(Error(
      kind: ErrorKind.fileDoesNotExists,
      path: path
    ))
    return
  try:
    execProcess("explorer.exe", args=[path], options={poUsePath})
  except:
    result.error = option(Error(
      kind: ErrorKind.processFailed,
      message: getCurrentExceptionMsg()
    ))

