data = open('/mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT','rb').read()
qian_liang = b'\xb0\xae\xc2\xb3'  # 乾糧
tie_liang  = b'\xc5\x4b\xc2\xb3'  # 鐵糧
print(f'乾糧 (b0ae c2b3): {data.find(qian_liang)}')
print(f'鐵糧 (c54b c2b3): {data.find(tie_liang)}')
