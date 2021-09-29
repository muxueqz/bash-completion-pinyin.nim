import unicode
import os
import strutils
import lmdb
import tables
# zhangmingyuan240@gmail.com 2020-05-03



var LIST_CHARS = """
{ "～":"~", "！":"!", "＠":"@", "＃":"#", "＄":"$",
        "％":"%", "＆":"&", "＊":"*", "（":"(", "）":")", "＿":"_",
        "－":"-", "＋":"+", "［":"[", "］":"]", "＜":"<", "＞":">",
        "？":"?", "，":",", "。":".", "／":"/", "、":"," }
"""

let dbenv = newLMDBEnv("./pinyindb")
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
#  for i in range(len(s)):
#      uchr = LIST_CHARS.get(s[i],s[i])
#      if uchr == s[i] :
#          uchr = getPY(uchr)
#          #  print('uchr', uchr)
#          if uchr != s[i]:
#              uchr = LIST_TEST.get(uchr,uchr)
#      # ret += uchr
#  #  print(ret)
#  # return ret.encode("UTF8")
#  # return getpystr(name)

proc main()=
  if paramCount() != 2:
    quit()

  var
    dironly = paramStr(1)
    cur = paramStr(2)
    ret: seq[string]
    py2file = initTable[string, string]()
    pinyin = ""
    dirname = splitFile(cur)[0]
    path = ""
    cur_name = [cur.splitFile().name, cur.splitFile().ext].join("")

  if dirname.len == 0:
    dirname = "./"
  elif dirname.startsWith("~"):
    dirname = expandTilde(cur)

  if not existsDir(dirname):
    quit()
  # echo dirname & cur
  # if existsDir(dirname & cur):
    # echo dirname & cur
    # quit()

  # echo dirname
  for kind, real_path in walkDir(dirname):
    if dironly == "x-d" and kind != pcDir:
      continue
    if path == dirname:
      continue
    if kind == pcDir:
      # continue
      path = real_path.splitFile()[1] & real_path.splitFile()[2] & "/"
    else:
      path = real_path.splitFile()[1] & real_path.splitFile()[2]
    pinyin = str2py(path)
    if pinyin.startsWith(cur_name) or
        path.startsWith(cur_name) or
        pinyin.startsWith(str2py(cur_name)) :
    # if pinyin.startsWith(cur_name):
      ret.add path
  if ret.len == 1:
    echo joinPath(dirname, ret[0])
  elif ret.len == 0:
    return
  else:
    var
      first_word = ret[0].toRunes[0]
      first_neq = 0
      space = 0
    for i in ret:
      if first_word != i.toRunes[0]:
        # echo "false"
        first_neq = 1
      if " " in i:
        space = 1
    if first_neq == 0:
      for i in ret:
        if space == 1:
          echo joinPath("'", dirname, i, "'")
        else:
          echo joinPath(dirname, i)
      return

    # return ret.join("\n")
    if ret.len > 0:
      echo ret.join("\n")
main()
