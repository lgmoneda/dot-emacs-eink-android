# Emacs for a 10.3-inch black-and-white Android tablet

A small first step toward editing Org, agenda files, and Org-roam notes.
Requires Emacs 29.1 or newer. Uses the built-in Org version. Agenda paths,
sync, capture templates, and Org-roam are intentionally left for the next step.

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
