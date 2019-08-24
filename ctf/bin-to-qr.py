#!/usr/bin/env python3
from PIL import Image
from math import sqrt, ceil, floor

'''
    Converts a string sequence of 1s and 0s into a black and white
    square image (original purpose was a QR).
'''
def bin_to_qr(data_path, image_name='out'):
    data = open(data_path, 'r').read()
    data_length = len(data)
    print(f"Data length: {data_length}")

    canvas_size = 400
    rows_sqrt = sqrt(data_length)
    rows = ceil(rows_sqrt)

    print(f"Canvas size: {canvas_size}")
    print(f"Rows Sqrt: {rows_sqrt}")
    print(f"Rows: {rows}")

    row_size = floor(canvas_size / rows)
    if (rows_sqrt != rows):
        print(f"QR Code Binary length not a power of 2 (not square)")

    if (canvas_size < rows):
        print(f"Canvas space is smaller than image size. This will fail. Please increase \
                canvas size to at least {rows}")

    img = Image.new('L', (canvas_size, canvas_size))

    for i in range(rows):
        for j in range(rows):
            bit = data[(i * rows) + j]
            if bit == '0':
                color = 0x00000000
            elif bit == '1':
                color = 0xffffffff
            else:
                color = 0x77777777
            img.putpixel((j * row_size, i * row_size), color)

    img.save(f"{image_name}.png")

