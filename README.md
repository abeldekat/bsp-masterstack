# bsp-masterstack
Add master-stack to bspwm.
This project started as a fork of [bsp-layout](https://github.com/phenax/bsp-layout). It is strongly encouraged to inspect and testdrive that project. 
Many thanks to its creator, Akshay Nair, for the inspiration and a great baseline. 
Aim:
It would be great if some notable features of dwm are also possible in bspwm:
1. An ordered stack, completely predictable. New windows are always spawned to master 
2. Promote, demote between stack and master
3. The various layouts
4. Increase/decrease the number of master windows
5. Taglike behaviour for windows and collections of windows.

Technically implementing the stack requires a strictly event driven approach. This project also aims to leverage bspwm completely. 
Windows for example are not resized by this script. A split ratio is not provided.
Monocle and tiled are not provided.
The main actions this script takes are:
1. Move nodes.
2. Balance the stack.
3. Rotate a part of the stack

This project is currently very much work a work in process...

[BSPWM](https://github.com/baskerville/bspwm) does one thing and it does it well. It is a window manager. But some workflows require layout management to some extent. `bsp-layout` fills that gap.

### Dependencies
* `bash`
* `bspc`
* `man`
* `tac`

### Installation

#### AUR

#### Install script
Others can install it directly using the install script.

**Note: Please read scripts like these before executing it on your machine**
```bash
curl https://raw.githubusercontent.com/abeldekat/bsp-masterstack/master/install.sh | bash -;
```

#### Clone and make
You can also clone the repo on your machine and run `sudo make install` in the cloned directory

### Supported layouts

### Usage

* Help menu
```bash
bsp-masterstack help
```

### Configuration
