;;; eink-org.el --- Desktop personal agenda on Android -*- lexical-binding: t; -*-

;; Adapted from dot-emacs/settings/org-custom-agenda-opt-settings.el.
(require 'org)
(require 'org-agenda)

(defgroup eink-org nil "Personal agenda on the tablet." :group 'org)
(defcustom eink-org-todo-file
  "/content/storage/com.android.externalstorage.documents/primary:Documents/OrgSync/todo-files/todo.org"
  "Synced TODO file. Override in local.el if necessary."
  :type 'file :group 'eink-org)

(setq org-agenda-files (list eink-org-todo-file)
      org-agenda-window-setup 'current-window)

;; New states to to-do
(setq org-todo-keywords
      '((sequence "TODO(t)" "WAIT(w)" "DELEGATED(e)" "STARTED(s)" "|" "DONE(d)" "CANCELED(c)" "INACTIVE(i)" "FAIL(f)")))

(setq org-lowest-priority ?F)
(setq org-default-priority ?F)
(setq org-agenda-skip-scheduled-if-deadline-is-shown t)
(setq org-tags-exclude-from-inheritance '("epic"))
;; It didn't work as intended for tracking complex tasks and excluding the subtasks, but it is a cool feature to checkx
;; (setq org-enforce-todo-dependencies t)
;; (setq org-agenda-dim-blocked-tasks 'invisible)

(defun eink/my-org-agenda-skip-if-parent-has-tag (tag)
  "Skip this subtree when its direct parent has TAG."
  (when (save-excursion
          (and (org-up-heading-safe) (member tag (org-get-tags nil t))))
    (save-excursion (org-end-of-subtree t))))

(setq org-agenda-block-separator " ")

;; Identify with a symbol when a scheduled to-do has children
(with-eval-after-load 'org-agenda
  (defun eink/org-has-children ()
    (if (save-excursion (org-goto-first-child)) "> " "   ")
  )
  (add-to-list 'org-agenda-prefix-format '(
     agenda  . "%i%-3:(eink/org-has-children) %-12:c%?-12t% s "
  ))
  )

(defun eink/scheduled-or-not (resp)
  (interactive)
  (if resp
    ;;'"OK"
    (concat "  " (number-to-string (org-time-stamp-to-now resp)) " day(s)")
    '"  Not Scheduled"
    )
  )

;; Org-super-agenda
(when (require 'org-super-agenda nil t)
  (org-super-agenda-mode 1))

(setq org-agenda-block-separator " ")
(setq org-super-agenda-header-separator "\n----------------------------------\n")
(setq org-super-agenda-header-separator "\n")
;; to keep org sorting strategy in the org-super-agenda groups
(setq org-super-agenda-keep-order t)

;; Hide tags in agenda views
(setq org-agenda-remove-tags t)

(defun eink/org-agenda-remove-category (item)
  "Remove category prefix, priority, and fix TODO keyword display."
  (if (string-match "^\\([[:space:]]*\\)\\([^[:space:]]+:\\)[[:space:]]*\\(\\[#[A-Z]\\][[:space:]]*\\)?\\(.\\)[[:space:]]*" item)
      (let* ((prefix-end (match-end 0))
             (first-char (match-string 4 item))
             (replacement "  ")
             (rest (substring item prefix-end))
             ;; Check if we need to remove the orphaned first letter
             (new-rest (if (and first-char
                               (string-match-p "^\\(ODO\\|ONE\\)" rest))
                          (concat first-char rest)
                        rest))
             (new-item (concat replacement new-rest)))
        ;; Copy all text properties
        (set-text-properties 0 (length replacement)
                            (text-properties-at prefix-end item)
                            new-item)
        new-item)
    item))

(defun eink/org-agenda-remove-todo-keyword (item)
  "Remove TODO keyword from ITEM string in org-super-agenda display."
  (let* ((marker (org-find-text-property-in-string 'org-marker item))
         (todo (when (and marker (marker-buffer marker))
                 (org-with-point-at marker
                   (org-get-todo-state)))))
    (if (not todo)
        item
      (let* ((s (replace-regexp-in-string
                 (concat "\\(" (regexp-quote todo) "\\)[[:space:]]+")
                 ""
                 item nil nil 1))
             (p (string-match "\\[#"
                              s)))
        ;; If there's an extra space before the priority cookie, remove exactly one.
        (when (and p (>= p 2)
                   (eq (aref s (1- p)) ?\s)
                   (eq (aref s (- p 2)) ?\s))
          (setq s (concat (substring s 0 (1- p))
                          (substring s p))))
        s))))

(defun eink/org-agenda-clean-item (item)
  "Remove both category and TODO keyword from ITEM."
  (let* ((marker (org-find-text-property-in-string 'org-marker item))
         (todo (when (and marker (marker-buffer marker))
                 (org-with-point-at marker
                   (org-get-todo-state))))
         ;; First remove category
         (cleaned (replace-regexp-in-string
                   "^[[:space:]]*[^[:space:]]+:[[:space:]]*"
                   "  "
                   item)))
    ;; Then remove TODO keyword if present
    (if todo
        (replace-regexp-in-string
         (concat "\\b" (regexp-quote todo) "\\b[[:space:]]*")
         ""
         cleaned)
      cleaned)))

(defun eink/org-agenda-add-deadline-prefix (item)
  "Add deadline/scheduled prefix showing days until/since, preserving text properties."
  (let* ((marker (org-find-text-property-in-string 'org-marker item))
         (deadline (when (and marker (marker-buffer marker))
                     (org-with-point-at marker
                       (org-entry-get (point) "DEADLINE"))))
         (scheduled (when (and marker (marker-buffer marker))
                      (org-with-point-at marker
                        (org-entry-get (point) "SCHEDULED")))))
    (let* ((timestamp (or deadline scheduled))
           (prefix (if timestamp
                      (let* ((days (org-time-stamp-to-now timestamp))
                             (days-str (format "%d day(s)" days)))
                        (format "  %-16s " days-str))
                    "  Not Scheduled    "))
           (new-item (concat prefix item)))
      ;; Copy all text properties from the start of the original item to the prefix
      (set-text-properties 0 (length prefix)
                          (text-properties-at 0 item)
                          new-item)
      new-item)))

(setq org-agenda-custom-commands
      '(("d" "Personal Agenda"
         (
          ;; ───────────────────────────────
          ;; Deadlines
          (tags-todo "+DEADLINE>=\"<-60d>\""
                     ((org-agenda-overriding-header "Deadlines \n----------------------------------")
                      (org-agenda-sorting-strategy '(deadline-up))
                      (org-agenda-prefix-format "%?-16 (eink/scheduled-or-not (org-entry-get (point) \"DEADLINE\")) ")
                      (org-super-agenda-groups nil)))

          ;; ───────────────────────────────
          ;; Week tasks (scheduled) - ungrouped
          (agenda ""
	  	  ((org-agenda-time-grid nil)
	  	   (org-agenda-span 'week)
	  	   (org-deadline-warning-days 0)
	  	   (org-deadline-past-days 0)
		   (org-scheduled-past-days 0)
	  	   (org-agenda-entry-types '(:deadline :scheduled))
	  	   (org-agenda-overriding-header "Week tasks\n----------------------------------")
		   (org-agenda-scheduled-leaders '("" ""))
		   (org-agenda-prefix-format "    %i %-4e %-10:c%(eink/org-has-children)")
		   (org-agenda-remove-tags t)
		   (org-agenda-skip-function '(eink/my-org-agenda-skip-if-parent-has-tag "bulk"))
	  	   ))
          ;; ALL TODO items - grouped by org-super-agenda in ONE PASS
      ;; (tags "+goals|+epic"
	  (tags "LEVEL>=1+TODO=\"TODO\"|+TODO=\"WAIT\"|+TODO=\"DONE\"|LEVEL>=1+mobile"
		((org-agenda-overriding-header "")
		 (org-agenda-sorting-strategy '(priority-down)) ;; the change to fix projects backlog
		 (org-super-agenda-groups
		  '((:name "Tech Epic\n----------------------------------"
			   :and (:priority "A"
					   :tag "epic"
           				   :todo "TODO"
					   :not (:tag "family")
					   :not (:tag "cult"))
		  	   :transformer eink/org-agenda-remove-todo-keyword)

		  (:name "Family Epic\n----------------------------------"
			  :and (:priority "A" :tag "family" :tag "epic" :todo "TODO")
			  :transformer eink/org-agenda-remove-todo-keyword
			  :order 0)

		  (:name "Cult Journeys\n----------------------------------"
			  :and (:priority "A" :tag "cult" :tag "epic" :todo "TODO")
			  :transformer eink/org-agenda-remove-todo-keyword)

		  (:name "Late tasks\n------------------"
			 :and (:scheduled past
					  :not (:todo "DONE")
					  :not (:tag "epic"))
			 :transformer eink/org-agenda-add-deadline-prefix)

		  (:name "Mobile inbox\n----------------------------------"
			 :tag "mobile"
		  	 :transformer eink/org-agenda-remove-todo-keyword)

		  (:name "Backlog\n------------------"
			 :and (:scheduled nil
					  :not (:todo "DONE")
					  :not (:tag "epic")
					  :not (:deadline t)
					  :not (:tag "goals")
					  )
			 :transformer eink/org-agenda-remove-todo-keyword)

		  ;; Season Goals
		  (:name "Season Goals\n----------------------------------"
			 :and (:tag "goals" :not (:tag "family") :todo ("TODO" "DONE"))
			 :transformer eink/org-agenda-remove-category
			 )

		  (:name "Family goals\n----------------------------------"
			 :and (:tag "family" :tag "goals" :todo ("TODO" "DONE"))
			 :transformer eink/org-agenda-remove-category
			 )

		  ;; Backlog Projects (non-priority epics)
		  (:name "Backlog Projects\n----------------------------------"
			  :and (:tag "epic" :not (:priority "A") :todo ("TODO" "WAIT"))
			  :transformer eink/org-agenda-remove-todo-keyword)

		  ;; Discard everything else
		  (:discard (:anything t))))))
)

         ;; Agenda options for this view
         ((org-agenda-compact-blocks nil)))))


;; org-settings.el also enables priority inheritance on the desktop.
(defun eink-org-inherited-priority (heading)
  "Return the priority of HEADING or its nearest ancestor with a priority."
  (cond
   ((string-match org-priority-regexp heading)
    (* 1000 (- org-priority-lowest
               (org-priority-to-value (match-string 2 heading)))))
   ((not (org-up-heading-safe))
    (* 1000 (- org-priority-lowest org-priority-default)))
   (t (eink-org-inherited-priority (org-get-heading)))))
(setq org-priority-get-priority-function #'eink-org-inherited-priority)

(defun eink-org-agenda ()
  "Open the desktop personal agenda using the synced TODO file."
  (interactive)
  (unless (file-readable-p eink-org-todo-file)
    (user-error "Cannot read %s; set eink-org-todo-file in local.el" eink-org-todo-file))
  (unless (require 'org-super-agenda nil t)
    (user-error "Run M-x eink-install-packages, then restart Emacs"))
  (org-super-agenda-mode 1)
  (setq org-agenda-files (list eink-org-todo-file))
  (org-agenda nil "d"))

(global-set-key (kbd "<f10>") #'eink-org-agenda)
(global-set-key (kbd "C-c o a") #'eink-org-agenda)

(defcustom eink-org-agenda-on-startup t
  "Open the personal agenda after startup."
  :type 'boolean :group 'eink-org)

(defun eink-org-startup-agenda ()
  "Show the personal agenda alone after device settings have loaded."
  (when eink-org-agenda-on-startup
    (condition-case err
        (let ((org-agenda-window-setup 'current-window))
          (eink-org-agenda)
          (delete-other-windows))
      (error (display-warning 'eink-org
                              (format "Startup agenda: %s"
                                      (error-message-string err))
                              :warning)))))

(add-hook 'emacs-startup-hook #'eink-org-startup-agenda 90)

(provide 'eink-org)
;;; eink-org.el ends here
