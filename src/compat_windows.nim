{.passl: "-lz".}
import winlean
import os
import parseArgs

func getCommandLine():string =
    return $(winlean.getCommandLineW())

proc getArgs*() : seq[string] =
    getCommandLine().getParams().paramsToSeq()

proc portableConfigDir*() : string =
    if existsEnv("HOME") :
        getEnv("HOME") / ".clojure"
    else :
        getenv("USERPROFILE") / ".clojure"
 
proc portableUserCacheDir*(config_dir : string) : string =
    config_dir / ".cpcache"

