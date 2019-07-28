#!/bin/bash
nim -d:release --opt:size c -d:project_version="1.10.1.466" --passL:-s -o:clojure src/clojure

#nim c -d:project_version="1.10.1.466" -o:clojure src/clojure
