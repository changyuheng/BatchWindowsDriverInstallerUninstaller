# Batch Windows Driver Installer & Uninstaller

The tool recursively (un)install the drivers in the folder that contains the script.

## Usage

To (un)install, copy the (un)install script to the folder that contains the target drivers' INFs and execute it.

```
install.ps1 / uninstall.ps1
   [-NoPrompt]
```

With `-NoPrompt` specified, the interactive mode will be disabled.

## Troubleshooting

Execute `Set-ExecutionPolicy RemoteSigned` from PowerShell if you see "....ps1 cannot be loaded because running scripts is disabled on this system. ..."
