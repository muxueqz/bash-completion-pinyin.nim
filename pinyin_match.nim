import os, strutils, unicode
import std/parseopt
import std/sets
import pinyin_db
import tables


type
  MatchMode = enum
    MatchModeFull, MatchModeFirstLetter

proc getpystr(name: Rune): string =
  var key = name.ord
  return pinyin_db.pinyin_db[name.ord]

proc str2py(name: string): seq[string] =
  result = @[""]
  for i, n in name.toRunes():
    var temp_result:seq[string] = @[]
    for prefix in result:
      var values = n.toUTF8.toOrderedSet
      try:
        values = n.getpystr.toOrderedSet
      except:
        discard
      for value in values:
        temp_result.add(prefix & value)
    result = temp_result

proc matchLineWithKeyword(line: string, keyword: string, mode: MatchMode): int =
  let 
    line_basename = line.lastPathPart
    py_lines = line_basename.runeSubStr(0, keyword.toRunes.len).str2py
    py_keyword = keyword.str2py[0]
  for py_file in py_lines:
    if (line.parentDir & py_file) == line:
      return -1
    if py_file.startsWith(keyword):
      return 1
    if py_keyword != keyword and py_file.startsWith(py_keyword):
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
