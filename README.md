# Clojure-cli-portable
An unofficial Clojure command line replacement
## What is it
The new Clojure CLI is great, but we're having issues on Windows as described [here](https://github.com/cark/clojure-windows-cli-issues).

I first made an [exploratory wrapper](https://github.com/cark/clojure-win-cli-wrap) to the existing [Powershell implementation](https://github.com/clojure/tools.deps.alpha/wiki/clj-on-Windows), and it works well enough, but we're still paying a hefty startup time penalty by calling into Powershell. So this project was born, a reimplementation of the powershell/bash scripts as small binary executable, writen with [Nim](https://nim-lang.org/).
## Project goal
- We're exploring the possibilities and hope to have Cognitect adopt this or something like it. 
- The project was made portable to demonstrate the feasability of a single implementation for all platforms.
- Nim was chosen because it's easy to read, produces small executables, and is portable. 
- I purposefully tried to maintain the shape of the existing bash script (almost line for line), and kept the same variable names so that this would be easy to transition to.
## Benefits
- command line parity between windows and the official posix cli
- tools like Cider jack-in on deps.edn, and shadow-cljs with deps.edn work on Windows
- no need to lower the security of your Powershell by setting a permissive execution policy
- fast
- small
- source code is quite readable
- cross-compilation from linux and/or docker to linux and windows
- a pretty installer for windows
## Binaries 
- Windows binaries are provided in the [Releases page](https://github.com/cark/clojure-cli-portable/releases)
- An installer is also provided there
## Build from source
### All platforms
- the `version.txt` file must contain the current version string of the clojure tools
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
- Uninstall any previously installed Clojure command line tool
- Unzip anywhere you like
- Add to the path
### Linux
!!! The official command line is good enough on Linux !!!

While the Linux build works on my machine, it only serves to demonstrate the feasability of a single implementation for all platforms.
#### Requirements
- a Linux computer or VM
- a recent [Nim compiler](https://nim-lang.org/install_unix.html)
- (optional) mingw-w64 required for cross compilation to windows
- (optional) [NSIS](https://nsis.sourceforge.io/Main_Page) for cross-compilation of the windows installer

#### Building
First we need the official clojure-tools.
From the project directory, execute this command in the terminal :
```
script/download
```

Then we want to build the Linux version
From the project directory, execute this command in the terminal :
```
script/build
```
You'll find the resulting zip file in the `out/linux` directory.

We might want to build the windows version
From the project directory, execute this command in the terminal :
```
script/build_win
```
You'll find the resulting zip file in the `out/win` directory.

The windows installer. This step requires that the windows build be executed first.
From the project directory, execute this command in the terminal :
```
script/nsis
```
You'll find the resulting installer executable in the `out/win` directory.

All these steps may be done in a single call :
```
script/build_all
```
#### Installing 
- Unpack anywhere you like
- symlink from one of your bin directories
- Set executable permissions where needed
### Docker
We can build it all with the provided Dockerfile. This will :
- use the official docker ubuntu image
- apt get all the things required to compile for Linux and Windows
- cross compile binaries for both platforms 
- build the Windows installer

The first run will be pretty long as we need to setup the image.
The image will end up at a almost 4gb.
Following runs are pretty fast.
#### Requirements
- Docker up and running
#### Building
from the project directory, execute this command in the terminal :
```
script/docker_build
```
The result will be placed in `dockerout/`
### Mac
While I haven't tested this at all, I think this can be built on Mac too, with maybe some slight adjustments in
the build scripts... Once again, the official scripts are good enough there.
## Changes
A few minor changes were made to the original scripts
- the cache\_key includes the project\_version in order to refresh the cache on clojure cli version change
- cache file names are md5 based instead of crc based
- we're purposefully ignoring ctrl-c, and let the JVM handle it.
- added an experimental fix to [TDEP-120](https://clojure.atlassian.net/browse/TDEPS-120), as well as a new switch -Scp-jar that will force the creation and usage of a classpath jar

## Prior art
I'm not the first one : 
- a [go implementation](https://github.com/frericksm/clj-windows)
- a [node implementation](https://github.com/thheller/clojure-cli)
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
