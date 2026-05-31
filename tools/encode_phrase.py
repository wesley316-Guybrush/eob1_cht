phrase = '落石擋路。'
b = phrase.encode('cp950')
print(f'phrase: {phrase}')
print(f'cp950 hex: {b.hex()}')
print(f'C escape: "' + ''.join(f'\\x{x:02x}' for x in b) + '"')
print(f'byte count: {len(b)}')
