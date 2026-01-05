# nvim-raddebugger

![Lua](https://img.shields.io/badge/Made%20with-Lua-blueviolet.svg?style=for-the-badge&logo=lua)
![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-green.svg?style=for-the-badge&logo=neovim)
![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6.svg?style=for-the-badge&logo=windows)

**nvim-raddebugger** bridges the modal efficiency of Neovim with the next-generation debugging power of [The RAD Debugger](https://github.com/EpicGamesExt/raddebugger) (Epic Games Tools). 

> [!IMPORTANT]
> **Manual Launch Required:** Currently, you must launch `raddbg.exe` manually before running Neovim commands. Automatic process management is on the roadmap.

## Features

- **Bi-directional Sync:** Toggling breakpoints in Neovim updates RAD immediately.
- **Project Awareness:** Automatically detects `.raddbg` project files to preserve your window layouts and watch variables.
- **IPC Target Control:** Switch debug targets directly from a Neovim floating menu.
- **Visual Studio Keybindings:** Familiar defaults (`F5`, `F10`, `Ctrl+F10`) out of the box.
- **Watch Window Integration:** Send variables from Neovim to the RadDebugger Watch window instantly.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "Alfred-Jijo/nvim-raddebugger",
    lazy = false,
    opts = {}
}

```

## Usage

1. **Start RadDebugger:** Open `raddbg.exe` manually.
2. **Open Neovim:** Navigate to your project root.
3. **Initialize:** Run `:RaddebuggerInit` (or just hit `F5`).
* This will auto-detect your `.raddbg` project or `.exe` and attach.



## Keybindings & Commands

| Key | Command | Action |
| --- | --- | --- |
| **F5** | `:RaddebuggerContinue` | **Run / Continue** execution. |
| **Shift+F5** | `:RaddebuggerKill` | **Stop/Kill** the debug process. |
| **F9** | `:RaddebuggerToggleBreakpoint` | **Toggle Breakpoint** on current line. |
| **F10** | `:RaddebuggerStepOver` | **Step Over** line. |
| **F11** | `:RaddebuggerStepInto` | **Step Into** function. |
| **Shift+F11** | `:RaddebuggerStepOut` | **Step Out** of function. |
| **Ctrl+F10** | `:RaddebuggerRunToCursor` | **Run to Cursor** (Execute until current line). |
| *(None)* | `:RaddebuggerRestart` | **Restart** the current session. |
| *(None)* | `:RaddebuggerWatch` | Add the word under cursor to **RadDebugger Watch**. |
| *(None)* | `:RaddebuggerTargetMenu` | Open floating menu to **Switch Targets**. |
| *(None)* | `:RaddebuggerFocus` | Force RadDebugger to jump to Neovim's current line. |
| *(None)* | `:RaddebuggerSave` | Force save User & Project settings to disk. |

## ⚙️ Configuration

Defaults (Visual Studio Style):

```lua
require("raddebugger").setup({
    keymaps = {
        toggle_breakpoint = "<F9>",
        continue          = "<F5>",
        step_over         = "<F10>",
        step_into         = "<F11>",
        step_out          = "<S-F11>",
        run_to_cursor     = "<C-F10>",
        stop              = "<S-F5>",
        target_menu       = nil, 
    }
})

```

## Roadmap (Beta)

* [ ] **Reverse Sync:** When stepping in RadDebugger, move the cursor in Neovim automatically.
* [ ] **Variable Hover:** Show variable values in a Neovim floating window (requires IPC return values).
* [ ] **Native Launching:** Remove the need for manual `raddbg` startup.

## License

[Apache 2.0](https://www.google.com/search?q=./LICENSE)
