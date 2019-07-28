# module parseArgs

type
    ParseState = enum 
       psStart, psParsing, psInDblQuotes, psInQUotes, psBackSlashing, 
       psIgnorableSpace, psDone

# returns the parameters as a single string, extracted from the full 
# command line
func getParams*(commandLine : string) : string =
    var i = 0
    var stringLength = len(commandLine)
    var state = psStart
    while (i < stringLength) :
        let c = commandLine[i]
        case state :
            of psStart :
                case c :
                    of ' ' : discard
                    of '"' : state = psInDblQuotes
                    else : state = psParsing
            of psParsing :
                case c :
                    of '"' : state = psInDblQuotes
                    of ' ' : state = psIgnorableSpace
                    else: discard
            of psInDblQuotes :
                case c :
                    of '"' : state = psIgnorableSpace
                    else : discard
            of psIgnorableSpace :
                case c :
                    of ' ' : discard
                    else :  break
            else : discard
        i += 1
    return commandLine[i..stringLength - 1]

# returns a seq of parameters, hopefully emulating the posix command
# line interpretation
func paramsToSeq*(params :string) : seq[string] =
    var i = 0
    var arg = ""
    var stringLength = len(params)
    var state = psStart
    result = @[]
    while (i < stringLength) :
        let c = params[i]
        case state :
            of psStart :
                case c :
                    of ' ' : discard
                    of '"' : state = psInDblQuotes
                    of '\'' : state = psInQuotes
                    else : 
                        state = psParsing
                        add(arg,c)
            of psParsing :
                case c :
                    of ' ' :
                        state = psStart
                        add(result, arg)
                        arg = ""
                    of '\'' : state = psInQuotes
                    of '"' : state = psInDblQuotes
                    else : add(arg, c)
            of psInDblQuotes :
                case c :
                    of '"' : state = psParsing
                    of '\\' : state = psBackSlashing                        
                    else: add(arg, c)
            of psBackSlashing :
                case c :
                    of '\\' :
                        add(arg, '\\')
                        state = psInDblQuotes
                    of '"' :
                        add(arg, '"')
                        state = psInDblQuotes
                    else :
                        add(arg, '\\')
                        add(arg, c)
                        state = psInDblQuotes
            of psInQUotes :
                case c :
                    of '\'' : state = psParsing
                    else: add(arg, c)
            else : discard
        i += 1
    if arg != "" :
        add(result, arg)