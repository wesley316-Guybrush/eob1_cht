phrases = ['乾糧', '鐵糧']
for ch in phrases:
    b = ch.encode('cp950')
    esc = ''.join(f'\\x{x:02x}' for x in b)
    print(f'{ch}: hex={b.hex()}  C="{esc}"')
