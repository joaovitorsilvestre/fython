### How to compile cli:

### Folder structure:
```
├── beams
│   ├── elixir_beams
│   └── fython_compiler_beams
├── compiled
│   └── Elixir.Main.beam
```
In the `beams` folder we will store all .beams of elixir and
fython in their respective folders.

Fython modules depends a lot of elixir modules, like IO, Map, etc.
To make it work we need to copy the beam files of elixir
modules that we depend on to the `elixir_beams` folder.

The `compiled` folder is where the Fython CLI beam files are
saved (like any other fython compiled project).