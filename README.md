# Emacs for a 10.3-inch black-and-white Android tablet

A small first step toward editing Org, agenda files, and Org-roam notes.
Requires Emacs 29.1 or newer. Uses the built-in Org version. The personal agenda reads your synced TODO file.
Org-roam provides basic note finding, capture, links, and backlinks.

## First launch

In the tablet's Emacs, run `M-: user-emacs-directory RET` to find its config
directory. Native Android Emacs and Termux Emacs can use different homes.
Copy `init.el`, `early-init.el`, and `lisp/` into that directory, preserving
the directory layout. Keep a copy of any existing configuration first.
Restart Emacs. The basic editor works without downloading anything.

Run `M-x eink-install-packages` with internet access, then restart Emacs.
This explicitly downloads the packages below and their dependencies from GNU
ELPA and MELPA. Normal startup does not refresh archives or install packages.
If installation fails, resolve the connection error and run the command again;
already installed packages are skipped. Use `M-x emacs-init-time` to inspect
startup time after restarting.

Open a disposable `.org` file with `C-x C-f`. Check typing, selection, undo,
save, touch scrolling, and the keys below. Use `M-x` if Android or your keyboard
intercepts a shortcut. Report the Emacs version, native Android or Termux,
and any display or keyboard problems from this first trial.

## Familiar editing keys

| Keys | Action |
| --- | --- |
| `C-x b`, `M-y` | Consult buffers and kill ring |
| `M-s l`, `M-g o`, `M-g i` | Search lines, outline, and headings/index |
| `M-.` | Preview the selected Consult result explicitly |
| `C-.`, `C-;` | Embark actions |
| `C-:`, `M-z`, `M-s s`, `C-?` | Avy character or line jumps |
| `C-+`, `C-=` | Expand selection; mark word |
| `C->`, `C-<`, `C-c C->` | Multiple cursors: next, previous, all |
| `C-x , m`, `C-x , n` | Edit selected lines or their ends |
| `M-[`, `M-]` | Previous/next change |
| `C-c w`, `C-c l`, `C-c s` | Copy word, copy line, scratch |
| `C-Return` | New line after the current line |
| `C-x 2`, `C-x 3` | Split and select the new window |
| `C-Tab`, `C-S-Tab`, `M-s w` | Next, previous, or selected window |
| `C-7`, `C-8`, `C-9` | Bury buffer, previous buffer, next buffer |
| `C-M-=`, `C-M--` | Increase/decrease text size |
| `F6` | Edit init.el |

Vertico, Orderless, and Marginalia provide completion in the minibuffer.
Orderless retains space-separated matching and initials; the desktop's custom
prefix matching operators and Prescient ranking are not included yet.
Consult file searches need the corresponding external program: `rg` for
`M-s r`, `grep` for `M-s g`, and `find` for `M-s d`. In-buffer search needs none.

## Performance and display choices

Black text on white; headings retain weight and links use underlines. Text
starts at 16 pt without a device-specific font. Completion shows eight rows
with a fixed height. Consult previews require `M-.` to reduce screen refreshes.
The selected completion row uses white text on black. Matching text is
underlined and follows the row's text color: white when selected, black otherwise.
No blinking cursor, line numbers, child-frame completion, animation, background
indexing, or global file polling. Touch and the menu bar remain available.

Most editing packages load on first use. The larger desktop setup—Straight,
Smartparens, Anzu, Super-save, Writeroom, language servers, AI tools, and media
packages—is omitted apart from the optional Codex session below. Standard Emacs undo and bracket
commands remain available. Files are saved explicitly with `C-x C-s`;
normal Emacs recovery auto-saves and versioned backups are enabled.

## Codex in agent-shell

Run `M-x eink-install-packages` again after pulling this update, then restart
Emacs. It now includes `agent-shell`; package.el installs its dependencies.
The package loads only when you start a session.

The native Android Emacs app must already be able to launch Termux programs.
Install the backend in Termux:

```sh
pkg update
pkg install nodejs-lts npm codex git ripgrep
npm install -g @agentclientprotocol/codex-acp
codex
```

Complete Codex sign-in there. Back in Emacs, open your study directory or an
Org note, then press `C-c a a` (`M-x eink-codex`). The session starts in the
current directory. You can also use `M-x agent-shell-openai-start-codex`
after agent-shell is loaded. Like the desktop config, it defaults to
`gpt-6.1-sol`, login authentication, and `agent-full-access` mode (commands and
file changes can run without approval). Only Codex appears in the agent menu.
Override these defaults with `with-eval-after-load` in `local.el` if needed.

The desktop `C-c a` prefix is preserved:

| Keys | Action |
| --- | --- |
| `C-c a a` | Start Codex |
| `C-c a f` | Send current file |
| `C-c a r` | Send selected region |
| `C-c a o` | Send another file |
| `C-c a l`, `C-c a d` | Send context at point (DWIM) |
| `C-c a c` | Compose a prompt |
| `C-c a q` | Prompt queue |
| `C-c a s`, `C-c a i` | Screenshot / clipboard image (needs device support) |

File completion is enabled, the welcome message is hidden, and automatic
context sources are disabled, as on the desktop. Context can still be sent
explicitly with the keys above. Work profiles, Claude, voice transcription,
pet, dashboard, Draw.io, Corfu, and Olivetti extensions are not included.

On Android, the config sets `CODEX_PATH` to the Termux Codex executable unless
you already set it. The adapter uses this instead of its bundled desktop
binary. This complements the Termux PATH setup in `early-init.el`.
If sign-in is requested again, native Emacs may have a different home from
Termux; complete the agent's authentication flow in that environment.

Agent-shell keeps its default appearance; desktop color styling is not copied.
On Android, common agent UI arrows and status symbols display as ASCII to
avoid missing-font boxes. This buffer-local fallback preserves the original
text and folding behavior; it does not change colors or fonts.

Native Android launches the adapter's `dist/index.js` with Termux's Node
directly. This was tested on the tablet and avoids the npm launcher failure
(exit code 127). It assumes the standard Termux global npm installation path.
Agent-shell data is directed into ignored
`var/agent-shell/`, separated by working directory. Codex manages its own
credentials and session history outside this repo; never add them to Git.
No agent-shell extensions or PDF extraction tools are required for text chats.

## Private device settings

Put device paths and personal preferences in `local.el` inside
`user-emacs-directory`. It loads last and is ignored by Git. For example:

```elisp
(set-face-attribute 'default nil :height 180)
```

Customize writes to ignored `custom.el`. History, saved positions, recovery
copies, and backups go in ignored `var/`; installed packages go in ignored
`elpa/`. Keep personal Org files outside this public repository. Review
`git status` and the exact diff before publishing any changes.

## Personal Org agenda

Copy the updated `init.el` and `lisp/` to your tablet config directory.
Run `M-x eink-install-packages` once to install `org-super-agenda` and its
dependencies, then restart Emacs. Press **F10**, **C-c o a**, or run
`M-x eink-org-agenda`. `M-x org-agenda RET d` also opens the personal view.
`C-c a` remains the agent-shell prefix.

The source is the desktop's **active** `settings/org-custom-agenda-opt-settings.el`,
loaded by `settings/org-settings.el`; the older `org-custom-agenda-settings.el`
is commented out there. Desktop F10 and startup both open command `d`.
The port keeps its deadlines, week schedule, and ordered groups: Family Epic,
Tech Epic, Cult Journeys, Late tasks, Mobile inbox, Backlog, Season Goals,
Family goals, and Backlog Projects. Items enter the first matching group;
empty groups are hidden. TODO states, priorities A-F, inherited priorities,
and the non-inherited `epic` tag follow the desktop settings.
The week block retains the desktop's effective direct-parent `bulk` exclusion.
Headings use plain separators and a `>` child marker for tablet font support.

Only `todo.org` is included. The desktop also adds Org-roam files tagged
`agenda`; those tasks will appear only when those files are synced and added
here. Emacs opens the personal agenda as the only visible window after startup,
using the device settings from `local.el`. If the file or package is missing,
startup completes with a warning. To disable automatic opening, put
`(setq eink-org-agenda-on-startup nil)` in `local.el`.
Desktop window splitting and the work agenda are not included.

The shared Org directory is `/storage/emulated/0/Documents/OrgSync/`.
The agenda uses:
`/storage/emulated/0/Documents/OrgSync/todo-files/todo.org`.
To select another path, put this in the tablet's ignored `local.el`:

```elisp
(setq org-directory "/storage/emulated/0/Documents/OrgSync/"
      org-roam-directory (expand-file-name "roam/roam-boox" org-directory)
      eink-org-todo-file (expand-file-name "todo-files/todo.org" org-directory)
      org-agenda-files (list eink-org-todo-file))
```

`M-x lgm/open-mobile-inbox` opens `mobile/inbox.org` under `org-directory`.
`M-x lgm/open-mobile-todo` opens `mobile/mobile-todo.org` there. Both commands
move to the end of the file, as on the desktop.

After sync updates the file, press `g` in the agenda to regenerate it.
If Emacs already has an older copy open, revert that source buffer first
(`M-x revert-buffer`; resolve any unsaved edits before reverting).
Agenda generation does not save the source file. Standard Org commands can
edit it, so save deliberately when using bidirectional sync.

## Synced Org-roam notes

Copy the updated `init.el` and `lisp/` to the tablet, run
`M-x eink-install-packages`, then restart. Use a recent Org-roam version that
supports a function in `org-roam-node-display-template`.
Org-roam loads on first use, keeping agenda startup light. Press `C-c n s`
once to build the local index; this first scan can take time. Find, insert,
capture, and backlinks then use that index without scanning the collection
on first use after a restart. If no index exists, they ask you to build it.
The tablet Emacs must have built-in SQLite support; check with
`M-: (sqlite-available-p) RET` (the result must be `t`).

| Keys | Action |
| --- | --- |
| `C-c n f` | Find a note or create one |
| `C-c n i` | Insert a note link |
| `C-c n c` | Capture a note |
| `C-c n l` | Toggle backlinks |
| `C-c n s` | Refresh index after syncing |

The editable BOOX notes folder is `/storage/emulated/0/Documents/OrgSync/roam/roam-boox`.
Override it in `local.el`:
```elisp
(setq org-roam-directory (expand-file-name "roam/roam-boox" org-directory))
```

The database stays in the tablet's ignored `var/org-roam-boox.db`, outside the
synced folder. Notes use standard Org IDs; new notes get timestamp-and-title
filenames. Finish capture with `C-c C-c`, or cancel with `C-c C-k`.
Completion displays titles and aliases without annotations or Org-roam's
recent-file sorting. A direct title formatter avoids per-node template
expansion. Indexing uses a bounded 64 MiB garbage-collection threshold;
override `org-roam-db-gc-threshold` in `local.el` if needed.
After setup, saving notes in Emacs updates the index. After external sync,
revert any stale source buffers and use `C-c n s` to index downloaded changes.
Each `C-c n s` performs one full scan, including on first use.
There is no background folder polling. This does not add roam notes to the
agenda; the agenda still reads `todo.org`.


## Desktop note library without tablet indexing

Sync these desktop folders to the tablet:

| Desktop Dropbox folder | Tablet folder under `OrgSync/` |
| --- | --- |
| `Agenda/roam/` | `roam/` (desktop library) |
| `Agenda/roam/roam-boox/` (included above) | `roam/roam-boox/` (editable BOOX notes) |
| `Agenda/desktop-org-roam-catalog/` | `desktop-org-roam-catalog/` |

Keep `roam-boox/` inside the desktop-library sync tree. The desktop indexes
all of `roam/`, while the tablet indexes only `roam/roam-boox/`. No separate
sync pair is needed for BOOX notes.

The BOOX notes have a separate database, `var/org-roam-boox.db`. The old
`var/org-roam.db` is left untouched and is no longer used by this config.
Remove any old `org-roam-directory` or `org-roam-db-location` override from
`local.el` that still selects the desktop library. Use `C-c n s` to index
only the small BOOX collection. The desktop library is never scanned by
catalog search, insertion, or ID navigation.

On the desktop, reload `settings/org-settings.el` (or restart Emacs), then run:

```
M-x lmoneda/org-roam-export-desktop-catalog
```

This exports the current desktop database to
`~/Dropbox/Agenda/desktop-org-roam-catalog/catalog.json`. It includes indexed
`.org` file nodes, heading nodes, titles, aliases, IDs, citation associations, and relative paths;
other file types and the editable `roam-boox/` subtree are excluded. It does
not read note contents or scan the collection. Export again after adding,
renaming, or moving notes. Use `C-u M-x lmoneda/org-roam-export-desktop-catalog`
to synchronize the desktop index first, when necessary. Export is explicit,
not automatic on every save.

After Dropbox/OrgSync copies the export and notes, use these tablet commands:

| Command | Keys | Action |
| --- | --- | --- |
| `desktop-roam-open-node` | `C-c d f` | Search node titles and aliases; jump to the ID |
| `desktop-roam-open-file` | `M-x` | Search file-level titles and aliases |
| `desktop-roam-insert-link` | `C-c d i` | Insert a standard `id:` link in a BOOX note |
| `desktop-roam-reload-catalog` | `M-x` | Reload the catalog explicitly |

The catalog is cached in memory and reloaded when the synced export changes.
There is no directory walk or note parsing during search. Opening a node or
following an `id:` link searches only the selected file for its ID, so
heading navigation tolerates changed character positions. Standard `C-c C-o`
works for desktop IDs even before loading Org-roam. Unrecognized IDs retain
normal Org/BOOX behavior. Missing files or stale IDs report a sync error
instead of starting a library scan.

Desktop notes open read-only by default, including through ID links. Set
`desktop-roam-read-only` to nil in `local.el` to allow editing. The library
and catalog paths can also be overridden there:

```elisp
(setq desktop-roam-directory (expand-file-name "roam" org-directory)
      desktop-roam-catalog-file
      (expand-file-name "desktop-org-roam-catalog/catalog.json" org-directory))
```

Only standard `id:` links use the catalog. Absolute desktop `file:` links
are not translated. This is a reading/search catalog, not a desktop
backlink database on the tablet. Syncing relative images or attachments
alongside the desktop library remains useful for reading them.


## Research library and citations

Sync `~/Dropbox/Research/` to
`/storage/emulated/0/Documents/Research/`, preserving `library.bib` and the
`Literature/` folder. Run `M-x eink-install-packages` after updating this
config to install Citar, then restart Emacs. The bibliography is loaded
only when you insert/follow a citation or browse it.

| Command | Keys | Action |
| --- | --- | --- |
| `org-cite-insert` | `C-c r` in Org | Insert a citation such as `[cite:@zhang2021dive]` |
| `eink-research-open` | `C-c n b` | Choose a reference, then its paper, notes, DOI, or URL |
| `eink-research-create-note` | `M-x` | Create/resume an editable BOOX reading note |

`C-c C-o` on an Org citation uses Citar to follow it. PDFs and EPUBs are
handed to Android's external app chooser, where you can select your reader.
Actual BOOX reader launching and saving annotations back to the synced PDF
must be verified on the device.

The associations come from these sources:

- `library.bib` contains citation keys, bibliographic metadata, DOI/URL
  links, and any explicit `file` fields.
- A file named `Literature/<citekey>.pdf` is matched automatically. Explicit
  relative `file` paths are resolved against `Literature/` and `Research/`.
  Absolute Dropbox Research paths are translated to the tablet path.
- Desktop note associations are stored in the note's `ROAM_REFS` property
  (for example, `ROAM_REFS: cite:zhang2021dive`) and cached in the desktop
  Org-roam database. The catalog now exports those
  citation keys too; matching does not depend on the note's filename.
- BOOX reading notes use `<citekey>.org` in `roam/roam-boox/`. They contain
  a persistent Org ID and `ROAM_REFS: @<citekey>`, so the desktop also
  recognizes their paper association after sync and indexing.

The first catalog from before research support still works for
citekey-named notes. To include timestamp-named or other desktop literature
notes, run `M-x lmoneda/org-roam-export-desktop-catalog` with the updated
desktop exporter and sync the regenerated `catalog.json`. The initial
catalog has already been regenerated with these associations.

Desktop notes stay read-only. Use `M-x eink-research-create-note` to write
your own reading notes, even when a desktop note already exists for that
paper. Only the BOOX note is indexed on creation; browsing citations does
not load Org-roam or scan the desktop library. Resource indicators and
recursive paper-folder searches are disabled to keep selection light.
Citar lists filenames only in the small BOOX note folder and the configured
Research/Literature folders; it does not parse desktop notes.

Syncing a PDF does not by itself associate it with a reference. Papers with
other filenames need a matching BibTeX `file` field or a citekey filename.
Files in nested Research folders work through explicit `file` fields;
they are not recursively discovered. No bibliography entries, PDFs, or
existing notes are rewritten by this configuration.

Override the two Research paths in `local.el` if necessary:

```elisp
(setq eink-research-directory "/storage/emulated/0/Documents/Research/"
      eink-research-bibliography-file
      (expand-file-name "library.bib" eink-research-directory))
```

## Org reading appearance

![Org reading style preview in Emacs on macOS](docs/org-reading-preview.png)

This is an Emacs preview on macOS, using the real Dom Casmurro note. It is
not a screenshot from the BOOX.

The tablet adapts the desktop's `aesthetics-settings.el`, `org-settings.el`,
and Mindre typography: Iosevka, a large title, compact metadata, indented
outlines, circle/diamond bullets, boxed tags, hidden emphasis markers, and
`▼` folding indicators. Text and labels stay black on white. Tables and code
retain a fixed-pitch font. Styling is buffer-local and does not change the
agenda's layout or the Org file's contents.

After copying the updated `init.el` and `lisp/`, run `M-x eink-install-packages`
to install Org-modern. The other reading improvements also work without it.
For the desktop font, copy the bundled `fonts/` folder alongside `init.el`,
then run `M-x eink-install-reading-fonts` on the tablet and restart Emacs.
The four compact Iosevka BOOX faces total about 1.8 MB; copying the desktop's
large `.ttc` collection is unnecessary. Native Android Emacs discovers user
fonts in `~/fonts/` at startup ([Emacs Android font documentation](https://www.gnu.org/software/emacs/manual/html_node/emacs/Android-Fonts.html)).
If neither Iosevka BOOX nor Iosevka is available, the device font is retained.

Notes open as folded outlines. Expand a heading with `TAB`; the metadata
and emphasis markers remain in the underlying file. Keyword abbreviations
reveal their original text when point is on them, so they remain editable.
Active-line highlighting is disabled in Org buffers to reduce visual noise.
The desktop theme's colors are replaced by weight, spacing and outlines.

| Keys | Action |
| --- | --- |
| `C-c v i` | Show up to two local images from the expanded, visible text |
| `C-u C-c v i` | Use the current subtree instead of the visible window |
| `C-c v h` | Hide these previews and release their decoded image cache |

Image previews are centered, capped at 750 pixels and the window width,
and skip files above 8 MiB. They support local PNG, JPEG, GIF and WebP files
when the Emacs build can decode them. Legacy image paths containing
`Dropbox/Agenda/roam/` are resolved against `desktop-roam-directory` if their
original location does not exist. Source links are not rewritten. Sync
`roam/resources/` and other image folders with the desktop library.

Desktop `#+STARTUP: inlineimages`, `linkpreviews`, and `latexpreview` settings
are left in the file but do not trigger automatic previews while visiting
notes on the tablet. Images are loaded only by explicit command, and there
is no automatic LaTeX compilation. The image limit and file-size limit bound
how much is requested; the decoder's memory usage still depends on the
original image dimensions. No animations, file watchers or custom idle
refresh jobs are added.

Optional overrides in `local.el`:

```elisp
(setq eink-org-reading-line-spacing 0.12
      eink-org-image-max-width 750
      eink-org-image-limit 2
      eink-org-image-max-bytes (* 8 1024 1024))
```

Reopen an Org buffer (or run `M-x eink-org-reading-setup`) after changing
reading typography settings. Use `C-c v h` then `C-c v i` after changing
image limits. The actual font fallback and contrast still need to be checked
on the BOOX screen.
