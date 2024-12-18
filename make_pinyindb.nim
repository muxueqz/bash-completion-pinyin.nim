import tables
import unicode
import unidecode
import strformat

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
    # if code == "0x6848".parseHexInt:
    #   echo (code, pinyin, pinyin[0], pinyin[0].runeSubStr(0, 1).unidecode)
    for i in pinyin:
      pinyin_first_letters.add($i.runeSubStr(0, 1).unidecode)
    # echo (code, pinyin, code.Rune)
    pinyin_tables[code] = pinyin_first_letters


echo """
import tables
# var T* = initTable[int, string]()
var pinyin_db* = {
"""
for k, v in pinyin_tables.pairs:
  echo (fmt"""{k.intToStr}: "{v.join("")}",""")

echo """
   }.toTable
"""
