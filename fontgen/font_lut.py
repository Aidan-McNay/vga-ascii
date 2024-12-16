# =========================================================================
# font_lut.py
# =========================================================================
# A Python script to generate a font lookup table from a ttf file

import argparse
import freetype
import os
import sys

# -------------------------------------------------------------------------
# Argument Parsing
# -------------------------------------------------------------------------

parser = argparse.ArgumentParser(
    description="A converter to generate a CharLUT for a specific font"
)

parser.add_argument("-t", "--ttf", required=True, help="The 8x16 TTF font file to use")

args = parser.parse_args()

# -------------------------------------------------------------------------
# Load the font file, and get the font name and glyph indeces
# -------------------------------------------------------------------------

# Load the font file
face = freetype.Face(args.ttf)
face.set_char_size(1024, 1024)  # Set resolution
name = face.family_name.decode("utf-8")
glyph_indeces = [x for x in face.get_chars()]

print(f"Generating CharLUT for {name} ({len(glyph_indeces)} characters)...")

# -------------------------------------------------------------------------
# Get strings for case statement for each character
# -------------------------------------------------------------------------

case_statement_strs = []

for value, idx in glyph_indeces:
    face.load_glyph(idx, freetype.FT_LOAD_RENDER)

    # Access the data
    glyph_name = face.get_glyph_name(idx).decode("utf-8")
    glyph_value = "8'b{0:08b}".format(value)
    bitmap = face.glyph.bitmap
    width = bitmap.width
    rows = bitmap.rows
    pixels = bitmap.buffer

    if width != 8 or rows != 16:
        print(f"Character {glyph_name} not 8x16; continuing...")
        continue

    if value >= 256:
        print(f"Character {glyph_name} not 8-bit ASCII; continuing...")
        continue

    case_statement_str = f"      {glyph_value}: char_pix = "

    pixel_binary = ["{0:08b}".format(x) for x in pixels]
    pixels = [f"8'b{x[::-1]}" for x in pixel_binary]
    case_statement_str += "{ " + ", ".join(pixels) + " };"
    case_statement_strs.append(case_statement_str)

case_statement_str = "\n".join(case_statement_strs)

# -------------------------------------------------------------------------
# Dump a modified template
# -------------------------------------------------------------------------

filepath = os.path.abspath(__file__)
dirpath = os.path.dirname(filepath)
template_path = os.path.join(dirpath, "CharLUT_template.v.tmp")
output_path = os.path.join(dirpath, "CharLUT.v")

with open(template_path, "r") as file:
    template_contents = file.read()

output_content = template_contents.replace("<font_name>", name)
output_content = output_content.replace("<font_lookup>", case_statement_str)

with open(output_path, "w") as file:
    file.write(output_content)
