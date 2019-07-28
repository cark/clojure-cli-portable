when defined(windows) :
    import compat_windows
elif defined(posix) :
    import compat_posix
import os
import osproc
import strutils
import helpText
import strformat
import sequtils
import md5
import times
import parseArgs

const project_version {.strdefine.} : string = "0.0.0.0"

let 
    install_dir = getAppDir()
    tools_cp = install_dir / "libexec" / "clojure-tools-" & project_version & ".jar"

var 
    config_dir = ""
    user_cache_dir = ""
    config_paths = newSeq[string]()
    config_str = ""
    cache_dir = ""
    tool_args = newSeq[string]()
    cp = ""
    jvm_cache_opts = newSeq[string]()
    main_cache_opts = newSeq[string]()

# portable args
var args : seq[string] = getArgs() 

type 
    Flag = enum
        print_classpath, describe, verbose, force, repro,
        tree, pom, resolve_tags, help
    FlagSet = set[Flag]

var 
    flags : FlagSet = {}
    jvm_opts = newSeq[string]()
    resolve_aliases = newSeq[string]()
    classpath_aliases = newSeq[string]()
    jvm_aliases = newSeq[string]()
    main_aliases = newSeq[string]()
    all_aliases = newSeq[string]()
    deps_data = ""
    force_cp = ""
    extra_args = newSeq[string]()

# returns the string surrounded with double quotes
func quoted(value : string) : string =
    "\"" & value & "\""

# returns the string at index in the seq
# returns the empty string when the index is > len(s)
func safeSeqAccess(s : seq[string], index : int) : string =
    if index < len(s) :
        s[index]
    else:
        ""

var i = 0
while i < (len args) :
    let arg = args[i]
    case arg
        of "-h", "--help", "-?" :
            if (main_aliases.len()>0 or all_aliases.len()>0) :
                extra_args = args[i..^1]
                break
            else : 
                incl(flags, help)
        of "-Sdeps" :
            i += 1
            deps_data = safeSeqAccess(args, i)
        of "-Scp" :
            i += 1
            force_cp = safeSeqAccess(args, i)
        of "-Spath" : incl(flags, print_classpath)
        of "-Sverbose" : incl(flags, verbose)
        of "-Sdescribe" : incl(flags, describe)
        of "-Sforce" : incl(flags, force)
        of "-Srepro" : incl(flags, repro)
        of "-Stree" : incl(flags, tree)
        of "-Spom" : incl(flags, pom)
        of "-Sresolve-tags" : incl(flags, resolve_tags)
        else :
            case arg[0..1] :
                of "-J" : add(jvm_opts, arg[2..^1])
                of "-R" : add(resolve_aliases, arg[2..^1])
                of "-C" : add(classpath_aliases, arg[2..^1])
                of "-O" : add(jvm_aliases, arg[2..^1])
                of "-M" : add(main_aliases, arg[2..^1])
                of "-A" : add(all_aliases, arg[2..^1])
                of "-S" : 
                    echo "Invalid option: ", arg
                    quit(1)
                else: 
                    extra_args = args[i..^1]
                    break
    i += 1

# find java
var java_command = findExe("java", true)
if java_command == "":
    var gotJava = false
    if existsEnv("JAVA_HOME")  :
        java_command = findExe(getEnv("JAVA_HOME") / "bin" / "java", true)
        gotJava = (java_command != "")  
    if not gotJava :
         echo "Couldn't find 'java'. Please set JAVA_HOME."  
         quit(1)

# display help
if contains(flags, help) :
    echo helpText.text 
    quit(0)

# *** We want to be totally transparent, ctrl-c is sent to the 
# whole process group. Java will receive it, so it can safely be ignored.
# The child process will exit first, tools won't be surprised, and 
# we produce no extra output.
proc ignoreIt() : void {.noconv.} =
    discard
setControlCHook(ignoreIt)

proc launch(command : string, args : openArray[string]) : int =
     var process = startProcess(command, "", args, nil, {poParentStreams, poInteractive})
     var exitCode = waitForExit(process)
     close(process)
     exitCode

# Execute resolve-tags command
if contains(flags, resolve_tags) :
    if existsFile("deps.edn") :
        launch(java_command, ["-Xms256m", "-classpath", tools_cp, "clojure.main", "-m",
            "clojure.tools.deps.alpha.script.resolve-tags", "--deps-file=deps.edn"])
            .quit()
    else: 
        echo "deps.edn does not exist."
        quit(1)

# Determine user config directory
if existsEnv("CLJ_CONFIG") :
    config_dir = getEnv("CLJ_CONFIG")
else :
    config_dir = portableConfigDir() 

# Ensure user config directory exists
if not existsDir(config_dir) :
    createDir(config_dir)

# Ensure user level deps.edn exists
if not existsFile(config_dir / "deps.edn") :
    copyFile(install_dir / "example-deps.edn", config_dir / "deps.edn")

# Determine user cache directory
if existsEnv("CLJ_CACHE") :
    user_cache_dir = getEnv("CLJ_CACHE")
else :
    user_cache_dir = portableUserCacheDir(config_dir)

# Chain deps.edn in config paths. repro=skip config dir
if contains(flags, repro) :
    config_paths = @[install_dir / "deps.edn", "deps.edn"]
else :
    config_paths = @[install_dir / "deps.edn", config_dir / "deps.edn", "deps.edn"]

config_str = map(config_paths, quoteShell).join(",")

# Determine whether to use user or project cache
if existsFile("deps.edn") :
    cache_dir = ".cpcache"
else :
    cache_dir = user_cache_dir

# Construct location of cached classpath file
# *** added project_version to the cache_key, so we rebuild cache on version change
var cache_key = join(resolve_aliases, "") & join(classpath_aliases, "") & 
    join(all_aliases, "") & join(jvm_aliases, "") & join(main_aliases, "") & 
    deps_data & project_version
for config_path in config_paths :
    if existsFile(config_path) :
        cache_key = cache_key & config_path
    else :
        cache_key = cache_key & "NIL"

# *** opting for md5 here, any hashing will do anyways
let 
    cache_key_hash = getMD5(cache_key)[0..7] # pick only 8 hex digits
    base_file = &"{cache_dir}/{cache_key_hash}"
    libs_file = base_file & ".libs"
    cp_file = base_file & ".cp"
    jvm_file = base_file & ".jvm"
    main_file = base_file & ".main"

# Print paths in verbose mode
if contains(flags, verbose) :
    echo "version      = " & project_version
    echo "install_dir  = " & install_dir
    echo "config_dir   = " & config_dir
    echo "config_paths = " & join(config_paths,", ")
    echo "cache_dir    = " & cache_dir
    echo "cp_file      = " & cp_file
    echo ""

# Check for stale classpath file
var stale = false
if contains(flags, force) or not existsFile(cp_file) :
    stale = true
else:
    let cp_time = getLastModificationTime(cp_file).toWinTime()
    for config_path in config_paths :
        if existsFile(config_path) and (cp_time < getLastModificationTime(config_path).toWinTime()) :
            stale = true
            break

# Make tools args if needed
if stale or contains(flags, pom) :
    if deps_data != "" :
        add(tool_args, "--config-data")
        add(tool_args, deps_data)
    if len(resolve_aliases) > 0 :
        add(tool_args, "-R" & join(resolve_aliases, ""))
    if len(classpath_aliases) > 0 :
        add(tool_args, "-C" & join(classpath_aliases, ""))
    if len(jvm_aliases) > 0 :
        add(tool_args, "-J" & join(jvm_aliases, ""))
    if len(main_aliases) > 0 :
        add(tool_args, "-M" & join(main_aliases, ""))
    if len(all_aliases) > 0 :
        add(tool_args, "-A" & join(all_aliases, ""))
    if force_cp != "" :
        add(tool_args, "--skip-cp")
    
# if stale, run make-classpath to refresh cached classpath
if stale and not contains(flags, describe) :
    if contains(flags, verbose) :
        echo "Refreshing classpath"   
    let exitCode = launch(java_command, @["-Xms256m", "-classpath", tools_cp, "clojure.main", "-m", 
        "clojure.tools.deps.alpha.script.make-classpath", "--config-files", config_str, "--libs-file", 
        libs_file, "--cp-file", cp_file, "--jvm-file", jvm_file, "--main-file", main_file] & tool_args)
    if exitCode != 0 : quit(exitCode)

# Build classpath
if contains(flags, describe) :
    cp = ""
elif force_cp != "" : 
    cp = force_cp
else: cp = readFile(cp_file)

# The actual business here
if contains(flags, pom) :
    launch(java_command, @["-Xms256m", "-classpath", tools_cp, "clojure.main", "-m", 
        "clojure.tools.deps.alpha.script.generate-manifest", "--config-files", config_str, 
        "--gen=pom"] & tool_args).quit()
elif contains(flags, print_classpath) : 
    echo cp
elif contains(flags, describe) :
    var path_vector = newSeq[string]()
    for config_path in config_paths :
        if existsFile(config_path) :
            add(path_vector, quoted(config_path))
    var path_vector_string = join(path_vector, " ")
    echo "{:version " & quoted(project_version)
    echo " :config-files [" & path_vector_string & "]"
    echo " :install-dir " & quoted(install_dir)
    echo " :config-dir " & quoted(config_dir)
    echo " :cache-dir " & quoted(cache_dir)
    echo " :force " & $(contains(flags, force))
    echo " :repro " & $(contains(flags, repro))
    echo " :resolve-aliases " & quoted(join(resolve_aliases, ""))
    echo " :classpath-aliases " & quoted(join(classpath_aliases, ""))
    echo " :jvm-aliases " & quoted(join(jvm_aliases, ""))
    echo " :main-aliases " & quoted(join(main_aliases, ""))
    echo " :all-aliases " & quoted(join(classpath_aliases, "")) & "}" 
elif contains(flags, tree) :
    launch(java_command, ["-Xms256m", "-classpath", tools_cp, "clojure.main", "-m", 
        "clojure.tools.deps.alpha.script.print-tree", "--libs-file", libs_file]).quit()
else:
    if existsFile(jvm_file) :
        jvm_cache_opts = paramsToSeq(readFile(jvm_file))
    if existsFile(main_file) :
        main_cache_opts = paramsToSeq(readFile(main_file))
    launch(java_command, jvm_cache_opts & jvm_opts & @["-Dclojure.libfile=libs_file",
        "-classpath", cp, "clojure.main"] & main_cache_opts & extra_args).quit()
