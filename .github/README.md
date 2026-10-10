<div align="center">

## <img src="assets/greeter.svg" alt="illogical-impulse greeter logo" style="float:left; width:400;">

**Greeter for [illogical-impulse dotfiles](https://github.com/Vercixx/illogical-impulse) based on greetd**

(yes it does sync your wallpaper)
</div>

<div align="center"> 
</div>

<img width="2560" height="1440" alt="Greeter showcase" src="https://github.com/user-attachments/assets/64545d6f-71e4-4bf8-91bc-0c250f648a37" />

---

<div align="center">
    <h2>Installation</h2>
</div>

If you're running my fork of illogical-impulse, you can install this from the Settings app (`System` -> `Advanced`).

If you're using an unmodified version by [end-4](https://github.com/end-4/dots-hyprland) or other DE, you can use `install.sh` script.

> [!IMPORTANT]
> You need to manually install these packages using your distribution's package manager:
> 
> `jq`, `greetd`. Install `greetd-agreety` if Agreety is not bundled with `greetd` by default (typical on Arch)
> 
> If you're not using illogical-impulse, you'll also need to manually install fonts (Material Symbols Rounded, Google Sans Flex, Space Grotesk)
> and Hyprland 0.55 or newer + Quickshell. Refer to `sdata` directory in illogical-impulse repository.

```
mkdir -p ~/.cache/ii-greeter
git clone --recurse-submodules https://github.com/Vercixx/ii-greeter.git ~/.cache/ii-greeter
cd ~/.cache/ii-greeter
sudo ./install.sh
```

Then, disable any existing DM in your init and enable `greetd`

You can uninstall greeter with:

```
cd ~/.cache/ii-greeter
sudo ./install.sh uninstall
```

Make sure to enable another DM, so you don't get dropped into bare tty!
