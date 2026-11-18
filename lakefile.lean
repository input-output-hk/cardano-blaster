import Lake
open Lake DSL System

private unsafe def gccArchive (name : String) : String :=
  match unsafeIO do
    let result ← IO.Process.run { cmd := "g++", args := #[s!"-print-file-name={name}"] }
    let path := result.trim
    unless ← (FilePath.mk path).pathExists do
      throw <| IO.userError s!"Install the GCC runtime archive {name} to link Z3"
    pure path with
  | .ok path => path
  | .error e => panic! s!"{e}"

private unsafe def z3LinkArgsImpl : Array String :=
  let library := (unsafeBaseIO (IO.getEnv "Z3_LIB_PATH")).getD ".lake/z3/bin"
  let archive := s!"{library}/libz3.a"
  if System.Platform.isOSX then
    #[archive, "-lc++"]
  else
    -- Lake inherits the shim archive, but not its package's linker flags.
    -- Keep Z3's C++ unwinder local to these Linux executables.
    #[archive, gccArchive "libstdc++.a", gccArchive "libgcc_eh.a",
      "-Wl,--exclude-libs,libz3.a", "-Wl,--exclude-libs,libstdc++.a",
      "-Wl,--exclude-libs,libgcc_eh.a"]

@[implemented_by z3LinkArgsImpl]
private opaque z3LinkArgs : Array String := #[]

package «CardanoBlaster» where
  moreLeanArgs := #["--threads=4"]
  moreLinkArgs := z3LinkArgs

require Blaster from git "https://github.com/input-output-hk/Lean-blaster" @ "488d1fe635d66a8ada10bd62fa801b3fc97feee8"
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
