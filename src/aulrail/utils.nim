import
  osproc


proc openExplorer*(path: string) =
  discard execProcess("explorer.exe", args=[path], options={poUsePath})
