import
  os


const
  aulrailCoreVersion* = "0.1.0"
  envFileName* = "aulrail.env.yaml"
  apmExePath* = getHomeDir() / "AppData/Local/apm/apm.exe"
  butlerPsPath* =
    func (envPath: string): string = envPath / ".butler/butler.ps1"
  butlerLaunchInNewWindowCommand* =
    func (envPath: string): string = "start " & envPath / ".butler/butler.bat"
  butlerLanchCommand* =
    func (envPath: string): string =
      "pwsh -ExecutionPolicy Bypass " & butlerPsPath(envPath)
