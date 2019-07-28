import "../parseArgs", unittest

suite "getParams" :
    test "just the exe" :
        check("" == getParams("clojure.exe"))
    test "empty string" :
        check("" == getParams(""))
    test "exe and params" :
        check("asdf sdfs" == getParams("clojure.exe asdf sdfs"))
    test "exe spaces param" :
        check("asdf sdfs" == getParams("clojure.exe    asdf sdfs"))
    test "space exe param" :
        check("asdf sdfs" == getParams("  clojure.exe asdf sdfs"))
    test "quotedexe" :
        check("" == getParams("\"blah.exe\""))
    test "quotedexe params" :
        check("blah foo buh" == getParams("\"blah.exe\" blah foo buh"))
    test "space quotedexe params" :
        check("blah foo buh" == getParams("   \"blah.exe\" blah foo buh"))
    test "quotedexe spaces params" :
        check("blah foo buh" == getParams("\"blah.exe\"    blah foo buh"))
    test "quotedexe quotedparams" :
        check("\"blah foo buh\"" == getParams("\"blah.exe\" \"blah foo buh\""))
    
suite "paramsToSeq" :
    test "empty-string" :
        check(newSeq[string]() == paramsToSeq(""))
    test "single param" :
        check(@["blah"] == paramsToSeq("blah"))
    test "space single param" :
        check(@["blah"] == paramsToSeq(" blah"))    
    test "couple params" :
        check(@["blah", "foo", "bar"] == paramsToSeq("blah foo bar"))
    test "couple params extra spaces" :
        check(@["blah", "foo", "bar"] == paramsToSeq("blah    foo    bar"))
        check(@["blah", "foo", "bar"] == paramsToSeq("    blah    foo    bar   "))
    test "quotes single param" :
        check(@["blah"] == paramsToSeq("'blah'"))
    test "dblquotes single param" :
        check(@["blah"] == paramsToSeq("\"blah\""))
    test "quotes concat normal param" :
        check(@["blahfoo"] == paramsToSeq("'blah'foo"))
    test "normal concat quotes param" :
        check(@["blahfoo"] == paramsToSeq("blah'foo'"))
    test "quote concat dblquotes" :
        check(@["blahfoo"] == paramsToSeq("blah\"foo\""))
    test "dblquote with internal dblquote" :
        check(@["blah\"foo"] == paramsToSeq("\"blah\\\"foo\""))
    test "dblquote with internal backslash" :
        check(@["blah\\foo"] == paramsToSeq("\"blah\\\\foo\""))
    test "bit of everything":
        check(@["mamma", "blah\\foo", "tutu"] == paramsToSeq("mamma \"blah\\\\foo\"  tutu  "))
    test "some more of everything" :
        check(@["-Sdeps", "{:deps {nrepl {:mvn/version \"0.6.0\"}"] ==
            paramsToSeq("-Sdeps '{:deps {nrepl {:mvn/version \"0.6.0\"}'"))
    test "cider":
        check(@["-Sdeps", "{:deps {nrepl {:mvn/version \"0.6.0\"} refactor-nrepl {:mvn/version \"2.5.0-SNAPSHOT\"} cider/cider-nrepl {:mvn/version \"0.22.0-beta4\"}}}",
            "-m", "nrepl.cmdline", "--middleware", "[\"refactor-nrepl.middleware/wrap-refactor\", \"cider.nrepl/cider-middleware\"]"] == 
            paramsToSeq("-Sdeps '{:deps {nrepl {:mvn/version \"0.6.0\"} refactor-nrepl {:mvn/version \"2.5.0-SNAPSHOT\"} cider/cider-nrepl {:mvn/version \"0.22.0-beta4\"}}}' -m nrepl.cmdline --middleware '[\"refactor-nrepl.middleware/wrap-refactor\", \"cider.nrepl/cider-middleware\"]'"))
    test "shadowcljs":
        check(paramsToSeq("-Sdeps \"{:aliases {:shadow-cljs-inject {:extra-deps {thheller/shadow-cljs {:mvn/version \\\"2.8.28\\\"}}}}}\" -A:dev:shadow-cljs-inject -m shadow.cljs.devtools.cli --npm watch test") ==
        @["-Sdeps", "{:aliases {:shadow-cljs-inject {:extra-deps {thheller/shadow-cljs {:mvn/version \"2.8.28\"}}}}}",
        "-A:dev:shadow-cljs-inject", "-m", "shadow.cljs.devtools.cli", "--npm", "watch", "test"])

