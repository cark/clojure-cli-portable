import os
import posix

proc getArgs*() : seq[string] =
    result = @[]
    var paramCount = paramCount()
    for i in 1..paramCount :
        add(result, paramStr(i))
        
proc portableConfigDir*() : string =
    if existsEnv("XDG_CONFIG_HOME") :
        getEnv("XDG_CONFIG_HOME") / "clojure"
    else :
        getenv("HOME") / ".clojure"

proc portableUserCacheDir*(config_dir : string) : string =
    if existsEnv("XDG_CACHE_HOME") :
        getEnv("XDG_CACHE_HOME") / "clojure"
    else :
        config_dir / ".cpcache"

proc exec*(command : string, args : openArray[string]) : void =
    var c : cstring = command
    var a : cstringArray = allocCStringArray(args)
    discard execv(c, a)

proc portableFileToCp*(filename : string) : string =
    readFile(filename)