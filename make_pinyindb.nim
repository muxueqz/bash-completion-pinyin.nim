import tables
import unicode
import lmdb
import normalize

import strutils

# pinyin.txt from https://github.com/mozillazg/pinyin-data/raw/refs/heads/master/pinyin.txt
var pinyin_db = open("pinyin.txt", fmRead)
var pinyin_tables = initTable[int, seq[string]]()
for line in pinyin_db.lines:
  if line.find('U') == 0:
    var
      line_seq = line.split(' ')[..1]
      code = ("0x" & line_seq[0][2..^2]).parseHexInt
      pinyin = line_seq[1].split(',')
      pinyin_first_letters : seq[string]
    if code == "0x6848".parseHexInt:
      echo code, pinyin, pinyin[0], pinyin[0].runeSubStr(0, 1).toNFKD()[0]
    for i in pinyin:
      # echo i[2..^1], i[2..^1].len
      # pinyin_first_letters.add($i[0])
      pinyin_first_letters.add($i.runeSubStr(0, 1).toNFKD()[0])
    # echo (code, pinyin, code.Rune)
    pinyin_tables[code] = pinyin_first_letters

let dbenv = newLMDBEnv("./pinyindb")
let  txn = dbenv.newTxn()
let  dbi = txn.dbiOpen("", 0)
  # out_json = %* pinyin_tables
  # out_json = %* {}
  # o_t = {"key":"t"}
# out_json = %* o_t
for k, v in pinyin_tables.pairs:
  # out_json[k.intToStr] = %* v.join
  txn.put(dbi, k.intToStr, v.join(""))
# writeFile("pinyin.db", $out_json)
# let g = txn.get(dbi, "foo")
# txn.del(dbi, "foo", "value")

# commit or abort transaction
txn.commit() # or txn.abort()

# close dbi and env
dbenv.close(dbi)
dbenv.envClose()
