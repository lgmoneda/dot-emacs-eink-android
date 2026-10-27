;;; eink-capture.el --- Desktop personal captures on BOOX -*- lexical-binding: t; -*-

(require 'org-capture)
(defvar eink-org-todo-file)

(defcustom eink-fleeting-notes-file
  (expand-file-name "roam/roam-boox/20261027052444-eink_fleeting_notes.org"
                    org-directory)
  "Synced BOOX fleeting-notes file. Override in local.el if necessary."
  :type 'file :group 'org-capture)

;; Match the active desktop n/d templates; resolve tablet paths at capture time.
(setq org-capture-templates
      '(("n" "BOOX fleeting notes" entry (file eink-fleeting-notes-file)
         "* %? \n%t ")
        ("d" "Personal task" entry
         (file+olp eink-org-todo-file "Life" "Misc")
         "* TODO %i%?" :empty-lines 1)))

(global-set-key (kbd "C-c c") #'org-capture)

(provide 'eink-capture)
;;; eink-capture.el ends here
