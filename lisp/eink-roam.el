;;; eink-roam.el --- Minimal synced Org-roam notes -*- lexical-binding: t; -*-

(require 'org)
(require 'cl-lib)
(declare-function eink-research-create-note "eink-research" ())
(declare-function org-roam-capture "org-roam-capture" (&optional goto keys &rest args))

(defvar org-roam-directory)
(defvar org-roam-db-location)
(defvar org-roam-capture-templates)
(defvar org-roam-completion-everywhere)
(defvar org-roam-db-gc-threshold)
(defvar org-roam-node-display-template)
(defvar org-roam-node-default-sort)
(defvar org-roam-node-annotation-function)

(setq org-roam-directory
      (expand-file-name "roam/roam-boox" org-directory)
      org-roam-db-location (expand-file-name "org-roam-boox.db" eink-state-directory)
      org-roam-completion-everywhere nil
      org-roam-db-gc-threshold (* 64 1024 1024)
      org-roam-node-display-template #'org-roam-node-title
      org-roam-node-default-sort nil
      org-roam-node-annotation-function nil
      org-roam-capture-templates
      `(("d" "default" plain "%?"
         :target
         (file+head "%(format-time-string \"%Y%m%d%H%M%S-${slug}.org\" (current-time) t)"
                    ,(concat "#+title: ${title}\n"
                             "#+STARTUP: linkpreviews latexpreview\n"
                             "#+filetags: \n"))
         :unnarrowed t)
        ("r" "literature note" plain "%?"
         :target
         (file+head "${citar-citekey}.org"
                    ,(concat ":PROPERTIES:\n:ROAM_REFS: @${citar-citekey}\n:END:\n"
                             "#+title: ${citar-title} (${citar-date}), ${citar-author}.\n"
                             "#+ref: cite:${citar-citekey}\n"
                             "#+STARTUP: linkpreviews latexpreview\n"
                             "#+filetags: :bibliographical_notes: \n"
                             "#+created: %U\n\n"))
         :unnarrowed t)))

(defun eink-roam-setup (&optional allow-missing-index)
  "Load Org-roam and enable incremental updates without scanning notes.
Unless ALLOW-MISSING-INDEX is non-nil, require an existing local index."
  (unless (file-directory-p org-roam-directory)
    (user-error "Cannot find %s; set org-roam-directory in local.el"
                org-roam-directory))
  (unless (and (fboundp 'sqlite-available-p) (sqlite-available-p))
    (user-error "Org-roam needs Emacs with built-in SQLite support"))
  (unless (require 'org-roam nil t)
    (user-error "Run M-x eink-install-packages, then restart Emacs"))
  (unless (or allow-missing-index (file-exists-p org-roam-db-location))
    (user-error "No Org-roam index yet; press C-c n s to build it first"))
  (unless (bound-and-true-p org-roam-db-autosync-mode)
    ;; Keep Org-roam's save/rename/delete hooks, but leave the full scan to
    ;; `eink-roam-sync'. Restore the real function immediately after setup.
    (cl-letf (((symbol-function 'org-roam-db-sync) #'ignore))
      (org-roam-db-autosync-mode 1))))

(defun eink-roam-find ()
  "Find an existing note or create one."
  (interactive)
  (eink-roam-setup)
  (let ((org-roam-capture-templates
         (list (assoc "d" org-roam-capture-templates))))
    (call-interactively #'org-roam-node-find)))

(defun eink-roam-insert ()
  "Insert an ID link to a note, creating the note if needed."
  (interactive)
  (eink-roam-setup)
  (let ((org-roam-capture-templates
         (list (assoc "d" org-roam-capture-templates))))
    (call-interactively #'org-roam-node-insert)))

(defun eink-roam-capture ()
  "Choose a default note or a bibliography-backed literature note."
  (interactive)
  (pcase (read-char-choice "BOOX note: [d] default, [r] literature: " '(?d ?r))
    (?d (eink-roam-setup)
        (org-roam-capture nil "d"))
    (?r (call-interactively #'eink-research-create-note))))

(defun eink-roam-backlinks ()
  "Toggle the backlinks buffer for the current note."
  (interactive)
  (eink-roam-setup)
  (org-roam-buffer-toggle))

(defun eink-roam-sync ()
  "Refresh the local index after external sync changes the notes."
  (interactive)
  (eink-roam-setup t)
  (org-roam-db-sync))

(global-set-key (kbd "C-c n f") #'eink-roam-find)
(global-set-key (kbd "C-c n i") #'eink-roam-insert)
(global-set-key (kbd "C-c n c") #'eink-roam-capture)
(global-set-key (kbd "C-c n l") #'eink-roam-backlinks)
(global-set-key (kbd "C-c n s") #'eink-roam-sync)

(provide 'eink-roam)
;;; eink-roam.el ends here
