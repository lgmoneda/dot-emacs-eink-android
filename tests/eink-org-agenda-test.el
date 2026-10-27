;;; eink-org-agenda-test.el --- Agenda sources and window layout -*- lexical-binding: t; -*-
(require 'ert)
(require 'eink-org)

(ert-deftest eink-org-agenda-views-isolate-sources-and-fill-frame ()
  (let* ((root (make-temp-file "eink-agenda-" t))
         (eink-org-todo-file (expand-file-name "todo.org" root))
         (eink-org-work-todo-file (expand-file-name "nu.org" root))
         (org-agenda-files nil)
         (org-agenda-sticky nil)
         ;; Simulate a user rule that would normally display agendas at the side.
         (display-buffer-alist '(("Org Agenda" (display-buffer-in-side-window)))))
    (unwind-protect
        (save-window-excursion
          (with-temp-file eink-org-todo-file
            (insert "* TODO Personal only\n"))
          (with-temp-file eink-org-work-todo-file
            (insert "* TODO My epic :epic:spinning:\n"
                    "* TODO Team epic :epic:spinning:team:\n"
                    "* TODO Delegated item :delegated:\n"
                    "* TODO [#A] Important item\n"
                    "* WAIT Blocked item\n"
                    "* TODO Batch item :batch:\n"
                    "* TODO Project item :projects:\n"
                    "* TODO Management item :manager:\n"
                    "* TODO Study item :education:\n"
                    "* TODO Goal item :cyclegoals:\n"
                    "* TODO Ordinary item\n"
                    "* TODO Scheduled parent\nSCHEDULED: <2099-01-01 Thu>\n"
                    "** TODO Hidden child\n"))
          (split-window-below)
          (call-interactively (key-binding (kbd "<f7>")))
          (should (derived-mode-p 'org-agenda-mode))
          (should (= (length (window-list)) 1))
          (should-not (window-parameter nil 'window-side))
          (should (equal org-agenda-files (list eink-org-work-todo-file)))
          (dolist (title '("My epic" "Team epic" "Delegated item" "Important item"
                           "Blocked item" "Batch item" "Project item" "Management item"
                           "Study item" "Goal item" "Ordinary item"))
            (should (string-match-p title (buffer-string))))
          (should-not (string-match-p "Personal only\\|Hidden child" (buffer-string)))
          (org-agenda-redo)
          (should-not (string-match-p "Personal only" (buffer-string)))
          (split-window-below)
          (call-interactively (key-binding (kbd "<f10>")))
          (should (= (length (window-list)) 1))
          (should (equal org-agenda-files (list eink-org-todo-file)))
          (should (string-match-p "Personal only" (buffer-string)))
          (should-not (string-match-p "My epic\\|Team epic" (buffer-string))))
      (dolist (file (list eink-org-todo-file eink-org-work-todo-file))
        (when-let* ((buffer (get-file-buffer file))) (kill-buffer buffer)))
      (delete-directory root t))))
