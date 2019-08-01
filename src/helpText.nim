# module helpText

const text* = """
Usage: clojure [dep-opt*] [init-opt*] [main-opt] [arg*]
       clj     [dep-opt*] [init-opt*] [main-opt] [arg*]

    The clojure script is a runner for Clojure. clj is a wrapper
    for interactive repl use. These scripts ultimately construct and
    invoke a command-line of the form:

    java [java-opt*] -cp classpath clojure.main [init-opt*] [main-opt] [arg*]

    The dep-opts are used to build the java-opts and classpath:
        -Jopt          Pass opt through in java_opts, ex: -J-Xmx512m
        -Oalias...     Concatenated jvm option aliases, ex: -O:mem
        -Ralias...     Concatenated resolve-deps aliases, ex: -R:bench:1.9
        -Calias...     Concatenated make-classpath aliases, ex: -C:dev
        -Malias...     Concatenated main option aliases, ex: -M:test
        -Aalias...     Concatenated aliases of any kind, ex: -A:dev:mem
        -Sdeps EDN     Deps data to use as the last deps file to be merged
        -Spath         Compute classpath and echo to stdout only
        -Scp CP        Do NOT compute or cache classpath, use this one instead
        -Srepro        Ignore the ~/.clojure/deps.edn config file
        -Sforce        Force recomputation of the classpath (don't use the cache)
        -Spom          Generate (or update existing) pom.xml with deps and paths
        -Stree         Print dependency tree
        -Sresolve-tags Resolve git coordinate tags to shas and update deps.edn
        -Sverbose      Print important path info to console
        -Sdescribe     Print environment and command parsing info as data
        -Scp-jar       Generate a classpath jar, use it to start the JVM

    init-opt:
        -i, --init path     Load a file or resource
        -e, --eval string   Eval exprs in string; print non-nil values
        --report target     Report uncaught exception to "file" (default), "stderr", or "none",
                            overrides System property clojure.main.report

    main-opt:
        -m, --main ns-name  Call the -main function from namespace w/args
        -r, --repl          Run a repl
        path                Run a script from a file or resource
        -                   Run a script from standard input
        -h, -?, --help      Print this help message and exit

    For more info, see:
        https://clojure.org/guides/deps_and_cli
        https://clojure.org/reference/repl_and_main
"""