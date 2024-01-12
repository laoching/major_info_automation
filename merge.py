#-*-coding: utf-8-*-

import os
import openpyxl
from opempyxl.cell.cell import ILLEGAL_CHARACTERS_RE
import re

wb = openpyxl.Workbook()
#ws = wb.create_sheet('생성')
sheet = wb.active
# path = "파일을 끌어올 경로"

# path에서 파일 목록 출력(마지막 하나는 폴더라서 제외)
flist = os.listdir(path)[:-1]

# 파일당 하나의 행에 데이터를 밀어넣기 위한 카운트 변수 추가
cnt = 1

for i in flist:
  tmp = []
  f = open(path+i, 'rb')
  #f = open(path+i, 'r+', encoding='unicode-escape')
  print(f)
  
  for j in f:
    j = j.decode(encoding='unicode-escape')
    j = j.strip()
    j = str(j)
    tmp.append(j)

  for k in range(len(tmp)):
    sheet.cell(row = cnt, column = 1, value = ILLEGAL_CHARACTERS_RE.sub(r'', tmp[k]))
  
  cnt += 1

f.close()

wb.save("C:/Users/Desktop/result.xlsx")
