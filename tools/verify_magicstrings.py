data = open('/mnt/d/03_game_tmp/eob1_cht/win64-build/game/KYRA.DAT','rb').read()
zhongzhi_short = b'\xa4\xa4\xa4\xee'              # 中止
zhongzhi_full  = b'\xa4\xa4\xa4\xee\xac\x49\xaa\x6b'  # 中止施法
qingkong       = b'\xb2\x4d\xaa\xc5'              # 清空
likai          = b'\xc2\xf7\xb6\x7d'              # 離開
print(f'中止 only      (a4a4a4ee):            {data.find(zhongzhi_short)}')
print(f'中止施法       (a4a4a4ee ac49aa6b):  {data.find(zhongzhi_full)}')
print(f'清空           (b24daac5):            {data.find(qingkong)}')
print(f'離開           (c2f7b67d):            {data.find(likai)}')
