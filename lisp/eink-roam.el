;;; eink-roam.el --- Minimal synced Org-roam notes -*- lexical-binding: t; -*-

(require 'org)

(defvar org-roam-directory)
(defvar org-roam-db-location)
(defvar org-roam-capture-templates)
(defvar org-roam-completion-everywhere)

(setq org-roam-directory
      "/content/storage/com.android.externalstorage.documents/primary:Documents/OrgSync/roam"
      org-roam-db-location (expand-file-name "org-roam.db" eink-state-directory)
      org-roam-completion-everywhere nil
      org-roam-capture-templates
      '(("d" "default" plain "%?"
         :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                            "#+title: ${title}\n")
         :unnarrowed t)))

(defun eink-roam-setup ()
  "Load Org-roam and enable local database updates on first use."
  (unless (file-directory-p org-roam-directory)
    (user-error "Cannot find %s; set org-roam-directory in local.el"
                org-roam-directory))
  (unless (and (fboundp 'sqlite-available-p) (sqlite-available-p))
    (user-error "Org-roam needs Emacs with built-in SQLite support"))
  (unless (require 'org-roam nil t)
    (user-error "Run M-x eink-install-packages, then restart Emacs"))
  (unless (bound-and-true-p org-roam-db-autosync-mode)
    (org-roam-db-autosync-mode 1)))

(defun eink-roam-find ()
  "Find an existing note or create one."
  (interactive)
  (eink-roam-setup)
  (call-interactively #'org-roam-node-find))

(defun eink-roam-insert ()
  "Insert an ID link to a note, creating the note if needed."
  (interactive)
  (eink-roam-setup)
  (call-interactively #'org-roam-node-insert))

(defun eink-roam-capture ()
  "Capture a note in the synced folder."
  (interactive)
  (eink-roam-setup)
  (call-interactively #'org-roam-capture))

(defun eink-roam-backlinks ()
  "Toggle the backlinks buffer for the current note."
  (interactive)
  (eink-roam-setup)
  (org-roam-buffer-toggle))

(defun eink-roam-sync ()
  "Refresh the local index after external sync changes the notes."
  (interactive)
  (eink-roam-setup)
  (org-roam-db-sync))

(global-set-key (kbd "C-c n f") #'eink-roam-find)
(global-set-key (kbd "C-c n i") #'eink-roam-insert)
(global-set-key (kbd "C-c n c") #'eink-roam-capture)
(global-set-key (kbd "C-c n l") #'eink-roam-backlinks)
(global-set-key (kbd "C-c n s") #'eink-roam-sync)

(provide 'eink-roam)
;;; eink-roam.el ends here
