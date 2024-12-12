import os, strutils, unicode
import std/parseopt
import lmdb


type
  MatchMode = enum
    MatchModeFull, MatchModeFirstLetter

let db_path = os.joinPath(os.getAppDir(), "./pinyindb")
let dbenv = newLMDBEnv(db_path)
let  txn = dbenv.newTxn()

proc getpystr(name: Rune): string =
  let  dbi = txn.dbiOpen("", 0)
  var
    key = name.ord.intToStr
  return txn.get(dbi, key)

proc str2py(name: string): string =
  var
    uchr = ""
    filename = name.toRunes()
    ret: seq[string]
  for i, n in filename:
    try:
      uchr = getpystr(n)
      ret.add $uchr[0]
      # echo i, n, uchr
    except:
      ret.add n.toUTF8
      # echo i, n
  return ret.join("")
proc matchLineWithKeyword(line: string, keyword: string, mode: MatchMode): int =
  var
    py_line= $str2py(line)
    py_keyword = $str2py(keyword)
  if py_line == line:
    return -1
  var py_file = splitFile(py_line)
  if (py_file.name & py_file.ext).startsWith(keyword):
    return 1
  if py_keyword != keyword and (py_file.name & py_file.ext).startsWith(py_keyword):
    return 1
    
  return -1
proc writeHelp() =
  echo """
  Usage:
    program [options] <keyword>

  Options:
    -h, --help              Show help message
    -c, --show-match-count  Display match count for each line
    -f, --firstletter       Match using the first letter of pinyin
    -F, --firstletter-only  Match only using the first letter of pinyin
  """

proc main() =
  var
    showMatchCount = false
    matchFirstLetter = false
    matchFirstLetterOnly = false
    keyword: string

  var parser = initOptParser(commandLineParams())

  # Parse options
  for kind, key, val in parser.getopt():
    case kind
    of cmdArgument:
      keyword = key
    of cmdLongOption, cmdShortOption:
      case key
      of "help", "h": writeHelp(); quit(0)
      of "show-match-count", "c": showMatchCount = true
      of "firstletter", "f": matchFirstLetter = true
      of "firstletter-only", "F": matchFirstLetterOnly = true
      else:
#        echo "Unknown option: ", key
        quit(1)
    of cmdEnd: assert(false)

  # Ensure keyword is provided
  if keyword.len == 0:
    echo "Error: keyword missing"
    quit(1)

  while true:
    try:
      let line = stdin.readLine()
      if line.len == 0: break
      var matchCount = -1

      if not matchFirstLetterOnly:
        matchCount = matchLineWithKeyword(line, keyword, MatchModeFull)
        if matchCount == -1 and matchFirstLetter:
          matchCount = matchLineWithKeyword(line, keyword, MatchModeFirstLetter)
      else:
        matchCount = matchLineWithKeyword(line, keyword, MatchModeFirstLetter)

      if matchCount != -1:
        if showMatchCount:
          echo matchCount, "\t", line
        else:
          echo line
    except EOFError:
      break

main()
