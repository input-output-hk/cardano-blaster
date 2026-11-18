import Lake
open Lake DSL

package «CardanoBlaster» where
  moreLeanArgs := #["--threads=4"]
  moreLinkArgs :=
    if System.Platform.isOSX then
      #["-Wl,-rpath,@loader_path", "-Wl,-rpath,@loader_path/../../packages/Blaster/.lake/build/lib"]
    else
      -- The shim is built against the host glibc. Resolve its symbols at load time.
      #["-Wl,--allow-shlib-undefined", "-Wl,-rpath,$ORIGIN",
        "-Wl,-rpath,$ORIGIN/../../packages/Blaster/.lake/build/lib"]

require Blaster from git "https://github.com/input-output-hk/Lean-blaster" @ "2e46f5dc48cd118d3d750832100720847a0fa969"
require PlutusCore from git "https://github.com/input-output-hk/PlutusCoreBlaster" @ "eed6584454a5c76de20f5b316fea203553d38452"
require CardanoLedgerApi from git "https://github.com/input-output-hk/CardanoLedgerApiBlaster" @ "c4711cfde34b49b163a627dafafee4526a3450fd"

lean_lib CardanoBlaster

lean_lib CardanoBlasterTests where
  srcDir := "Tests"

lean_exe «native-tests» where
  root := `Tests.Main
  supportInterpreter := true

@[default_target]
lean_exe «cardano-blaster» where
  root := `CardanoBlaster.Main
  supportInterpreter := true
