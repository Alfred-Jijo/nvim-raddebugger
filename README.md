# nvim-raddebugger

![Lua](https://img.shields.io/badge/Made%20with-Lua-blueviolet.svg?style=for-the-badge&logo=lua)
![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-green.svg?style=for-the-badge&logo=neovim)
![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6.svg?style=for-the-badge&logo=windows)

**nvim-raddebugger** bridges the modal efficiency of Neovim with the next-generation debugging power of [The RAD Debugger](https://github.com/EpicGamesExt/raddebugger) (Epic Games Tools). 

Debug C/C++ projects on Windows seamlessly with bi-directional syncing of breakpoints, execution control, and target management, all via the RAD Debugger's IPC interface.

> [!IMPORTANT]
> **Manual Launch Required** > Currently, this plugin **does not** automatically spawn the `raddbg.exe` process due to Windows process detachment constraints.  
> 
> **You must launch the RAD Debugger manually** (e.g., via your Start Menu or Terminal) *before* issuing commands in Neovim. Automatic process management is the top priority on our roadmap.

## Features

- **Bi-directional Sync:** Toggling breakpoints in Neovim updates RAD immediately.
- **IPC Target Control: (WIP)** Switch debug targets directly from a Neovim floating menu.
- **Visual Studio Keybindings:** Familiar defaults (`F5`, `F10`, `F11`) out of the box.
- **Status Line Integration:** Exposes debugger state (RUNNING, PAUSED, IDLE) for lualine/heirline.
- **Hot-Reload Support: (WIP)** Works with hot-reloading executables by managing IPC attachment states.

## Prerequisites

1.  **Windows** (x64).
2.  **Neovim 0.10+** (Required for `vim.system` async APIs).
3.  **`raddbg.exe`** must be in your system `PATH`.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "Alfred-Jijo/nvim-raddebugger",
    dependencies = { "nvim-lua/plenary.nvim" }, -- Optional utility
    lazy = false,   -- Recommended to load immediately for IPC listeners
    opts = {
        -- Your configuration here (see Defaults below)
    }
}

```

### [pckr.nvim](https://github.com/lewis6991/pckr.nvim)

```lua
{ 
  "Alfred-Jijo/nvim-raddebugger",
  config = function()
    require("raddebugger").setup()
  end
}
```

### [vim.pack](https://neovim.io/doc/user/pack.html)

```lua
vim.pack.add({
	{ src = "https://github.com/Alfred-Jijo/nvim-raddebugger" },
})
```

## Configuration

The plugin comes with defaults mimicking Visual Studio. You can override any of these settings in the `setup` table.

```lua
require("raddebugger").setup({
    -- If nil, auto-detects .raddbg or .exe in root/build folders
    project_file = nil, 

    -- Keymaps (Set to false to disable specific mappings)
    keymaps = {
        toggle_breakpoint = "<F9>",
        continue          = "<F5>",
        step_over         = "<F10>",
        step_into         = "<F11>",
        step_out          = "<S-F11>",
        stop              = "<S-F5>",
        target_menu       = nil, -- Example: "<leader>dt"
    },

    -- Visual customization
    breakpoint_color = "#51202a", -- Background color for the breakpoint line
    statusline = true,            -- Enable internal status tracking
    auto_update = true,           -- Sync file changes automatically
    debounce_ms = 500             -- Debounce for file watchers
})
```

## Usage Guide

1. **Start RadDebugger:** Open `raddbg.exe` manually.
2. **Open Neovim:** Navigate to your project root.
3. **Initialize:** Run `:RaddebuggerInit`.
* This will attempt to find a `.raddbg` project file or an `.exe` in your build folder.
* It will connect to the running RAD instance via IPC.


4. **Sync:** Toggling a breakpoint (`F9`) in Neovim will now instantly appear in the RAD window.

## Keybindings

| Key | Command | Action |
| --- | --- | --- |
| **F5** | `:RaddebuggerContinue` | **Run / Continue** execution. |
| **Shift+F5** | `:RaddebuggerKill` | **Stop/Kill** the debug process. |
| **F9** | `:RaddebuggerToggleBreakpoint` | **Toggle Breakpoint** on current line. |
| **F10** | `:RaddebuggerStepOver` | **Step Over** line. |
| **F11** | `:RaddebuggerStepInto` | **Step Into** function. |
| **Shift+F11** | `:RaddebuggerStepOut` | **Step Out** of function. |
| *(None)* | `:RaddebuggerTargetMenu` | Open floating menu to switch targets. |

## Roadmap

* [ ] **Process Management:** Automatically launch `raddbg` detached from Neovim.
* [ ] **Variable Hover:** Show value under cursor using IPC evaluation.
* [ ] **DAP Adapter:** Potential integration with `nvim-dap` protocol (long term).

## License

[Apache 2.0](./LICENSE)

