{.passl: "-lz".}
{.passl: "-static".}
import zip/zipfiles
import strutils
import times
import os

proc buildManifest(cpString : string) : string = 
    when defined(windows):
        var paths = split(cpString, ";")
    when defined(posix):
        var paths = split(cpString, ":")
    var newPaths = newSeq[string]()
    for path in paths:
        var p : string
        if existsDir(path) :
            p = path
            if path[1] == ':':
                p="\\" & path
            add(p, DirSep)
        elif existsFile(path):
            if (path[1] == ':') :
                p = "\\" & path
            else:
                p = path
        else:
            echo "Neither a file or a directory : ", path
            echo "Classpath jars are sensitive to this."
            quit(1)
            
        add(newPaths, replace(p, " ", "%20"))

    var cp = join(newPaths, " \n ") & " "
            
    result = "Manifest-Version: 1.0\n" &
        "Class-Path: " & cp & "\n" &
        "Created-By: Clojure \n" &
        "\n"

proc buildClasspathJar(filename, cpString :string) : void =
    var tempName = changeFileExt(filename, "tmp")
    var manifest = buildManifest(cpString)
    # echo manifest
    writeFile(tempName, manifest)
    try :
        var z : ZipArchive
        if not open(z, filename, fmWrite) :
            echo "Couldn't create " & filename
            quit(1)
        try :
            addFile(z, "META-INF/MANIFEST.MF", tempName)
        finally : 
            close(z)
    finally :
        removeFile(tempName)

const maxCpLen = 30000 # Give it some leeway
proc fileToCp*(filename : string, forced:bool) : string =
    var cp = readFile(filename)
    var windows = false
    when defined(windows) :
        windows=true
    if forced or (len(cp) > maxCpLen and windows):
        var jarName = changeFileExt(filename, "jar")
        if not existsFile(jarName) or (getLastModificationTime(jarName).toWinTime() < getLastModificationTime(filename).toWinTime()) :
            buildClasspathJar(jarName, cp)
        return jarName
    else:
        return cp

