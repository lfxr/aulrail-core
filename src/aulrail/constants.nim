import
  os


const
  aulrailCoreVersion* = "0.1.0"
  envFileName* = "aulrail.env.yaml"
  apmExePath* = getHomeDir() / "AppData/Local/apm/apm.exe"
  butlerLaunchInNewWindowCommand* =
    func (envPath: string): string = "start " & envPath / ".butler/butler.bat"
  butlerLanchCommand* = "pwsh -ExecutionPolicy Bypass ./.butler/butler.ps1"
