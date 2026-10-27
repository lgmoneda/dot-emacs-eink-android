# Compact Org reading fonts

These are renamed, subset copies of Iosevka Regular, Italic, Semibold and
Semibold Italic from the desktop's installed Iosevka collection. All four
files together are about 1.8 MB. The original collection is about 444 MB.

The family name is **Iosevka BOOX**. Latin (including Portuguese accents),
Greek, common mathematical symbols, arrows and outline bullets are retained.
Other scripts use the device's fallback fonts. No glyph shapes were changed.
The original copyright notices remain embedded. Redistribution is under the
SIL Open Font License; see [OFL.txt](OFL.txt).

On native Android Emacs, copy this `fonts/` directory alongside `init.el`,
run `M-x eink-install-reading-fonts`, then restart Emacs. The command copies
these files into the Emacs home directory's `~/fonts/`, which native Android
Emacs reads on startup. This is different from `user-emacs-directory`.

For a desktop preview, install these TTF files using the operating system's
font manager, or use the already installed original Iosevka font.

To rebuild from the desktop's collection:

```sh
uv run --with fonttools python tools/build-reading-fonts.py ~/Library/Fonts/Iosevka.ttc
```
