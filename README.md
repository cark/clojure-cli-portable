# Clojure-cli-portable
An unofficial Clojure command line replacement
## What is it
The new Clojure CLI is great, but we're having issues on Windows as described [here](https://github.com/cark/clojure-windows-cli-issues).

I first made an [exploratory wrapper](https://github.com/cark/clojure-win-cli-wrap) to the existing [Powershell implementation](https://github.com/clojure/tools.deps.alpha/wiki/clj-on-Windows), and it works well enough, but we're still paying a hefty startup time penalty by calling into Powershell. So this project was born, a reimplementation of the powershell/bash scripts as small binary executable, writen with [Nim](https://nim-lang.org/).
## Project goal
We're exploring the possibilities and hope to have Cognitect adopt this or something like it. The project was made portable with the idea that this migh ease the maintenance effort. Nim was chosen because it's easy to read, memory safe and portable. 

I purposefully tried to maintain the shape of the existing bash script (almost line for line), and kept the same variable names so that this would be easy to transition to.
## Benefits
- command line parity between windows and the official posix cli
- tools like cider jack-in deps.edn and shadow-cljs with deps.edn work on Windows
- no need to lower the security of your Powershell by setting a permissive execution policy
- fast
- small
- source code is quite readable
## Binaries 
Windows binaries binaries are provided here.
## Build from source
### Windows
#### Requirements
- a Windows computer or VM
- a recent [Nim compiler](https://nim-lang.org/install_windows.html)
- [Java](https://jdk.java.net) installed and in the path
#### Building
from the project directory, execute this command in the console :
```
script\build
```
You'll find the resulting zip file in the `out` directory.
#### Installing
No affordance were made to ease the installation process, but it's quite simple.
- Uninstall any previously installed Clojure command line tool
- Unzip anywhere you like
- Add to the path

I'll soon make a proper Windows installer.
### Linux
!!! The official command line is good enough on Linux !!!

While it works on my machine, at present time, the Linux part of this project is more of a "this can be done" thing
#### Requirements
- a Linux computer or VM
- a recent [Nim compiler](https://nim-lang.org/install_unix.html)
#### Building
from the project directory, execute this command in the terminal :
```
script/build
```
You'll find the resulting zip file in the `out` directory.
There are two scripts `script/build`and `script/compile`. You might have to set executable permission on these.
#### Installing 
No affordances were made to ease the installation process. 
- Unpack anywhere you like
- symlink from one of your bin directories
- Set executable permissions where needed

## Changes
A few minor changes were made to the original scripts
- cache file names are md5 based instead of crc based
- the cache\_key includes the project\_version in order to refresh the cache on clojure/tool.deps version change
- we're purposefully ignoring ctrl-c, and let the JVM handle it.
- the cache file content of jvm\_file and main\_file are parsed again as a regular command line parameters string.

## Prior art
I'm not the first one : a [go implementation](https://github.com/frericksm/clj-windows) also exists.
# Copyright and License

Copyright © 2017 Rich Hickey, Alex Miller, Sacha De Vos and contributors

All rights reserved. The use and
distribution terms for this software are covered by the
[Eclipse Public License 1.0] which can be found in the file
epl-v10.html at the root of this distribution. By using this software
in any fashion, you are agreeing to be bound by the terms of this
license. You must not remove this notice, or any other, from this
software.

[Eclipse Public License 1.0]: http://opensource.org/licenses/eclipse-1.0.php
