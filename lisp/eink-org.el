;;; eink-org.el --- Desktop personal agenda on Android -*- lexical-binding: t; -*-

;; Adapted from dot-emacs/settings/org-custom-agenda-opt-settings.el.
(require 'org)
(require 'org-agenda)

(defun eink-org-insert-child-heading ()
  "Append a child heading without splitting the current heading or body.
Insert after existing children.  Require a parent heading."
  (interactive)
  (when (org-before-first-heading-p)
    (user-error "Move to a parent heading or its body first"))
  (let ((org-insert-heading-respect-content t))
    (org-insert-subheading nil)))

;; Cover both GUI Return events and their control-character spelling.
;; Prefix alternatives also work when Android intercepts modified Return.
(dolist (key '("C-<return>" "C-RET" "C-c o n"))
  (define-key org-mode-map (kbd key) #'org-insert-heading-respect-content))
(dolist (key '("C-M-<return>" "C-M-RET" "C-c o c"))
  (define-key org-mode-map (kbd key) #'eink-org-insert-child-heading))

(setq org-directory "/storage/emulated/0/Documents/OrgSync/")

(defgroup eink-org nil "Personal agenda on the tablet." :group 'org)
(defcustom eink-org-todo-file
  (expand-file-name "todo-files/todo.org" org-directory)
  "Synced TODO file. Override in local.el if necessary."
  :type 'file :group 'eink-org)

(defcustom eink-org-work-todo-file
  (expand-file-name "todo-files/nu.org" org-directory)
  "Synced work TODO file. Override in local.el if necessary."
  :type 'file :group 'eink-org)

(defun lgm/open-mobile-inbox ()
  "Open the synced mobile inbox Org file and go to the end."
  (interactive)
  (find-file (expand-file-name "mobile/inbox.org" org-directory))
  (goto-char (point-max)))

(defun lgm/open-mobile-todo ()
  "Open the synced mobile TODO Org file and go to the end."
  (interactive)
  (find-file (expand-file-name "mobile/mobile-todo.org" org-directory))
  (goto-char (point-max)))

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


(defun eink-org-skip-when-parent-scheduled ()
  "Skip entries whose parent has a SCHEDULED property."
  (save-restriction
    (widen)
    (let ((should-skip nil))
      (save-excursion
        (while (and (not should-skip) (org-up-heading-safe))
          (when (org-get-scheduled-time (point))
            (setq should-skip t))))
      (when should-skip
        (or (outline-next-heading) (point-max))))))

(add-to-list 'org-agenda-custom-commands
      '("nu" "Nubank Agenda"
         (
          ;; 📅 Deadlines
          (tags-todo "+DEADLINE>=\"<-60d>\"|+perfcycle"
                     ((org-agenda-overriding-header "📅 Deadlines\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺")
                      (org-agenda-entry-types '(:deadline :scheduled))
                      (org-agenda-sorting-strategy '(deadline-up))
                      (org-agenda-prefix-format "%?-16 (eink/scheduled-or-not (org-entry-get (point) \"DEADLINE\")) ")
                      (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                      (org-agenda-remove-tags t)))
          ;; ⏳ Week Tasks
          (agenda ""
		    ((org-agenda-time-grid nil)
		     (org-agenda-span 'week)
		     (org-deadline-warning-days 0)
		     (org-deadline-past-days 0)
		     (org-scheduled-past-days 0)
		     (org-agenda-entry-types '(:deadline :scheduled))
		     (org-agenda-overriding-header "⏳ Week tasks\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺")
		     (org-agenda-scheduled-leaders '("" ""))
		     (org-agenda-prefix-format "    %i %-4e %-10:c%(eink/org-has-children)")
		     (org-agenda-remove-tags t)
		     (org-agenda-skip-function '(eink/my-org-agenda-skip-if-parent-has-tag "bulk"))
		     ;; (org-agenda-skip-function #'add-clock-emoji-to-agenda)
		     ))
          ;; 🧩 Grouped section — tags view but grouped
          (tags "LEVEL>=1+TODO=\"TODO\"|+TODO=\"WAIT\""
		((org-agenda-overriding-header "")
		 (org-agenda-sorting-strategy '(priority-down))
		 (org-agenda-skip-function #'eink-org-skip-when-parent-scheduled)
		 (org-super-agenda-groups
		  '(
                    (:name "🌋 My Epics\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺"
                           :and (:tag "epic"
				      :tag "spinning"
				      :not (:tag "team"))
                           :transformer eink/org-agenda-remove-todo-keyword
                           :order 0)

                    (:name "📊 Team Epics\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺"
                           :and (:tag "team" :tag "epic" :tag "spinning" :todo "TODO")
                           :transformer eink/org-agenda-remove-todo-keyword
                           :order 1)

		    ;; --- Delegated (team+directreports OR delegated), TODO, not epic ---
                    (:name "🤝 Delegated Tasks\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺"
                           :and (:not (:todo "DONE") :tag "delegated" :not (:tag "epic"))
                           :order 2)

                    (:name "⚡ High Priority Tasks\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺"
                           :and (:todo "TODO"
                                 :priority "A"
				 :scheduled nil
				 :not (:tag "epic" :tag "delegated")
				 )
                           :and (:todo "TODO"
                                 :priority "A"
				 :scheduled past
				 :not (:tag "epic" :tag "delegated")
				 )
			   :transformer eink/org-agenda-remove-todo-keyword
			   :order 3)

                    ;; --- Blocked/WAIT (exclude epics/team) ---
                    (:name "💀 Blocked\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺"
                           :and (:todo "WAIT"
                                 :not (:tag "epic")
                                 :not (:tag "team")
				 :scheduled past
				 )
			   :and (:todo "WAIT"
                                 :not (:tag "epic")
                                 :not (:tag "team")
				 :scheduled nil
				 )
                           :order 4)

                    (:name "🚚 Batch Tasks\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺"
                           :and (:tag "batch"
                                 :not (:tag "epic")
                                 :not (:tag "delegated")
				 :scheduled nil)
                           :and (:tag "batch"
                                 :not (:tag "epic")
                                 :not (:tag "delegated")
				 :scheduled past)
                           :order 5)

                    ;; --- Tasks in Projects — TODO, not A, UNSCHEDULED, not epic/delegated ---
                    (:name "🚢 Tasks in Projects\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺"
                           :and (:tag "projects"
                                      :todo "TODO"
                                      :not (:priority "A")
                                      :scheduled nil
                                      :not (:tag "epic")
                                      :not (:tag "delegated"))
                           :and (:tag "projects"
                                      :todo "TODO"
                                      :not (:priority "A")
                                      :scheduled past
                                      :not (:tag "epic")
                                      :not (:tag "delegated"))
			   :transformer eink/org-agenda-add-deadline-prefix
                                    :order 6)

                             ;; --- Tasks in Management — TODO, not A, UNSCHEDULED, not epic/delegated ---
                             (:name "💼 Tasks in Management\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺"
                                    :and (:todo "TODO"
                                          :tag "manager"
                                          :not (:priority "A")
                                          :scheduled nil
                                          :not (:tag "epic")
                                          :not (:tag "cyclegoals")
                                          :not (:tag "delegated"))
                                    :and (:todo "TODO"
                                          :tag "manager"
                                          :not (:priority "A")
                                          :scheduled past
                                          :not (:tag "epic")
                                          :not (:tag "cyclegoals")
                                          :not (:tag "delegated"))
				    :transformer eink/org-agenda-add-deadline-prefix
                                    :order 7)

                             ;; --- Education ---
                             (:name "📚 Education\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺"
                                    :and (:todo "TODO"
                                          :tag "education"
                                          :scheduled nil
                                          :not (:tag "epic")
                                          :not (:tag "cyclegoals")
					  )
                                    :and (:todo "TODO"
                                          :tag "manager"
                                          :scheduled past
                                          :not (:tag "epic")
                                          :not (:tag "cyclegoals")
					  )

                                    :order 8)

			   ;; Season Goals
			     (:name "🎯 Season Goals\n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺"
				    :and (:tag "cyclegoals")
				    :transformer eink/org-agenda-clean-item
				    :order 9
				    )

			     ;; --- Late (exclude epics/team) ---
			     (:name "💀 Late, untracked or backlog \n⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺"
				    :and (:todo "TODO"
					  :scheduled past
					  )
				    :and (:todo "TODO"
					  :scheduled nil
					  )
				    :order 10)

		  ;; Discard everything else
		  (:discard (:anything t))
		  ))))
	  )
         ((org-agenda-compact-blocks nil))))


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

(defun eink-org--agenda-view (key file)
  "Open agenda KEY for FILE as the only window in the current frame."
  (unless (file-readable-p file)
    (user-error "Cannot read synced agenda file: %s" file))
  (unless (require 'org-super-agenda nil t)
    (user-error "Run M-x eink-install-packages, then restart Emacs"))
  (org-super-agenda-mode 1)
  ;; Keep the selected source for agenda refresh commands, too.
  (setq org-agenda-files (list file))
  (let ((org-agenda-window-setup 'current-window)
        (display-buffer-alist nil)
        (display-buffer-overriding-action '(display-buffer-same-window)))
    (org-agenda nil key)
    (delete-other-windows)))

(defun personal-agenda-view ()
  "Show the desktop personal agenda from the synced todo.org file."
  (interactive)
  (eink-org--agenda-view "d" eink-org-todo-file))

(defun work-agenda-view ()
  "Show the desktop work agenda from the synced nu.org file."
  (interactive)
  (eink-org--agenda-view "nu" eink-org-work-todo-file))

(defalias 'eink-org-agenda #'personal-agenda-view)
(global-set-key (kbd "<f7>") #'work-agenda-view)
(global-set-key (kbd "<f10>") #'personal-agenda-view)
(global-set-key (kbd "C-c o a") #'personal-agenda-view)

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
