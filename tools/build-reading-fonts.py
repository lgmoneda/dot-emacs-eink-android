#!/usr/bin/env python3
"""Extract and subset four Iosevka faces from a desktop TTC (needs fonttools)."""
import argparse
from pathlib import Path
from fontTools import subset
from fontTools.ttLib import TTCollection

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('collection', type=Path)
parser.add_argument('--output', type=Path, default=Path('fonts'))
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
unicodes = set()
# Latin (including Portuguese), Greek, typography, math, arrows and outline symbols.
for low, high in [(0, 0x024F), (0x0300, 0x03FF), (0x1E00, 0x1EFF),
                  (0x2000, 0x23FF), (0x2500, 0x27BF), (0x2A00, 0x2AFF),
                  (0xFFFD, 0xFFFD)]:
    unicodes.update(range(low, high + 1))
wanted = {'Regular': 'Regular', 'Italic': 'Italic',
          'Semibold': 'Semibold', 'Semibold Italic': 'SemiboldItalic'}
found = set()
for font in TTCollection(args.collection, lazy=True).fonts:
    names = font['name']
    family = names.getDebugName(16) or names.getDebugName(1)
    style = names.getDebugName(17) or names.getDebugName(2)
    if family != 'Iosevka' or style not in wanted:
        continue
    options = subset.Options()
    options.name_IDs = ['*']
    options.name_legacy = True
    options.name_languages = ['*']
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=unicodes)
    subsetter.subset(font)
    replacements = {1: 'Iosevka BOOX', 2: style, 4: 'Iosevka BOOX ' + style,
                    6: 'IosevkaBOOX-' + style.replace(' ', ''),
                    16: 'Iosevka BOOX', 17: style}
    for record in font['name'].names:
        if record.nameID in replacements:
            record.string = replacements[record.nameID].encode(record.getEncoding())
    target = args.output / ('IosevkaBOOX-' + wanted[style] + '.ttf')
    font.save(target)
    found.add(style)
    print(target, target.stat().st_size)
if found != set(wanted):
    raise SystemExit('Missing requested Iosevka faces: ' + str(set(wanted) - found))
