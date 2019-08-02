@echo off
set %version%=%1
nim -d:release --opt:size c -d:project_version="%version%" --passL:"-s -w" -o:clojure.exe src/clojure

