;; package --- summary This is my emacs noob config for a scala developer
(require 'package)

(defun ross/use-package-ensure-already-installed
    (name _ensure state &optional _context)
  "Value for `use-package-ensure-function` that assumes the package
  is already installed.  This is true in our Nix environment."
  (let ((autoloads-file-name (format "%s-autoloads" name)))
    (with-demoted-errors "Error loading autoloads: %s"
      (load autoloads-file-name t t))))

(setq use-package-ensure-function #'ross/use-package-ensure-already-installed)

;; Add melpa to your packages repositories
;; (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; (package-initialize)

;;; standard configurations for things emacs does that annoy me:
;; don't create '#' prefixed lock files
(setq create-lockfiles nil)
;; save backups to a separate directory
(setq backup-directory-alist `(("." . "~/.emacs.d/.emacs.bak")))
;; turn off annoying sound at end of buffer on scroll
(setq ring-bell-function 'ignore)

;; set larger font size for curved monitor
(set-face-attribute 'default nil :height 140)


;; Install use-package if not already installed
;; (unless (package-installed-p 'use-package)
;;   (package-refresh-contents)
;;   (package-install 'use-package))

(require 'use-package)

;; Enable defer and ensure by default for use-package
;; Keep auto-save/backup files separate from source code:  https://github.com/scalameta/metals/issues/1027
(setq
 use-package-always-defer t
 use-package-always-ensure t
 backup-directory-alist `((".*" . ,temporary-file-directory))
 auto-save-file-name-transforms `((".*" ,temporary-file-directory t)))

(defun dgibs/load-updates ()
  "Loads the updated packages from Nix"
  (interactive)
  (load-file (concat user-emacs-directory "load-path.el")))

(defun dgibs/load-updates-and-reinit ()
  "Loads the updated packages from Nix and re-runs init"
  (interactive)
  (dgibs/load-updates)
  (load-file (concat user-emacs-directory "init.el")))


;; ensure command -> super, option -> meta. mostly a problem on home mac
(setq mac-option-key-is-meta t)
(setq mac-command-key-is-meta nil)
(setq mac-command-modifier 'super)
(setq mac-option-modifier 'meta)

(use-package delight
    :ensure t)


;; GUI specific Options
;; https://github.com/osener/emacs-afternoon-theme/tree/master
(use-package afternoon-theme
  :if window-system
  :init
  ;; Set default theme
  (load-theme 'afternoon :no-confirm :no-enable))

;; from here: https://github.com/protesilaos/modus-themes
(use-package modus-themes
  :ensure t
  :demand t
  :config
  (load-theme 'modus-vivendi-tinted :no-confirm))

(use-package vterm
  :commands vterm)
(use-package helm-switch-shell
  :after helm
  :bind ("s-v". helm-switch-shell)
  ("C-c v". helm-switch-shell)
  :config (setq helm-switch-shell-new-shell-type 'vterm))


;; Navigation
(use-package avy
  :ensure t
  :bind
  ("C-:" . avy-goto-char)
  ("C-'" . avy-goto-char2)
  ("s-g" . avy-goto-line)
  ("C-\"" . avy-goto-word-1))


(use-package display-line-numbers
  :demand t
  ;; tells it not to download and install since it is built into emacs
  :ensure f
  :config
  (defun display-line-numbers--turn-on ()
    "turn on line numbers but excempting certain majore modes defined in `display-line-numbers-exempt-modes'"
    (if (and
         (not (member major-mode '(treemacs)))
         (not (minibufferp)))
        (display-line-numbers-mode)))
  (global-display-line-numbers-mode))

;; Projectile
(use-package projectile
  :delight '(:eval (concat " " (projectile-project-name)))
  :init (projectile-mode +1)
  :config (setq projectile-project-search-path '(("~/repositories/" . 2) ))
  :bind-keymap ("C-c p" . projectile-command-map)
  )

(use-package flycheck-projectile
  :commands flycheck-projectile-list-errors)


;; Buffler
(defun burly-bookmark-windows-with-projectile-name (name)
  "Bookmark the current frame's window configuration as NAME."
  (interactive
   (list (completing-read "Save Burly wbookmark: " (burly-bookmark-names)
                          nil nil  (concat burly-bookmark-prefix (projectile-project-name)) )))
  (let ((record (list (cons 'url (burly-windows-url))
                      (cons 'handler #'burly-bookmark-handler))))
    (bookmark-store name record nil)))

(defun bufler-custom-groups ()
  "Customized bufler groups"
  (bufler-defgroups
    (group
     ;; Subgroup collecting all named workspaces.
     (auto-workspace))
    (group
     ;; Subgroup collecting all `help-mode' and `info-mode' buffers.
     (group-or "*Help/Info*"
	       (mode-match "*Help*" (rx bos "help-"))
	       (mode-match "*Info*" (rx bos "info-"))))
    (group
     ;; Subgroup collecting all special buffers (i.e. ones that are not
     ;; file-backed), except `magit-status-mode' buffers (which are allowed to fall
     ;; through to other groups, so they end up grouped with their project buffers).
     (group-and "*Special*"
		(lambda (buffer)
		  (unless (or (funcall (mode-match "Magit" (rx bos "magit-status"))
				       buffer)
			      (funcall (mode-match "Dired" (rx bos "dired"))
				       buffer)
			      (funcall (mode-match "Vterm" (rx bos "vterm"))
				       buffer)
			      (funcall (auto-file) buffer))
		    "*Special*")))
     (group
      ;; Subgroup collecting these "special special" buffers
      ;; separately for convenience.
      (name-match "**Special**"
		  (rx bos "*" (or "Messages" "Warnings" "scratch" "Backtrace") "*")))
     (group
      ;; Subgroup collecting all other Magit buffers, grouped by directory.
      (mode-match "*Magit* (non-status)" (rx bos (or "magit" "forge") "-"))
      (auto-directory))
     ;; Subgroup for Helm buffers.
     (mode-match "*Helm*" (rx bos "helm-"))
     ;; Remaining special buffers are grouped automatically by mode.
     (auto-mode))
    ;; All buffers under "~/.emacs.d" (or wherever it is).
    (dir user-emacs-directory)
    (group
     ;; Subgroup collecting buffers in `org-directory' (or "~/org" if
     ;; `org-directory' is not yet defined).
     (dir (if (bound-and-true-p org-directory)
	      org-directory
	    "~/org"))
     (group
      ;; Subgroup collecting indirect Org buffers, grouping them by file.
      ;; This is very useful when used with `org-tree-to-indirect-buffer'.
      (auto-indirect)
      (auto-file))
     ;; Group remaining buffers by whether they're file backed, then by mode.
     (group-not "*special*" (auto-file))
     (auto-mode))
    (group-and "Projectile"
	       ;; Subgroup collecting buffers in a projectile project.
	       (auto-projectile))
    (group
     ;; Subgroup collecting buffers in a version-control project,
     ;; grouping them by directory.
     (auto-project))
    ;; Group remaining buffers by directory, then major mode.
    (auto-directory)
    (auto-mode)))

(use-package bufler
  :commands (bufler bufler-switch-buffer)
  :after (projectile ace-window)
  :init (bufler-mode)
  :config
  (setf bufler-groups (bufler-custom-groups))
  :bind
  ("C-x b" . bufler-switch-buffer)
  ("C-x C-b" . bufler))

;; (use-package helm-bufler
;;   :after (helm bufler)
;;   :config (helm :sources '(helm-bufler-source)))

(use-package burly
  :after projectile
  :ensure t
  :bind
  ("C-c w s" . burly-open-bookmark)
  ("C-c w c" . burly-bookmark-windows)
  ("C-c w l" . list-bookmarks)
  :config
  (advice-add 'burly-bookmark-windows :override #'burly-bookmark-windows-with-projectile-name))

;; Helm
(use-package helm
  :init (helm-mode 1)
  :delight
  :bind
  ("C-x C-f" . helm-find-files)
					; ("C-x b" . helm-mini)
  ("M-x" . helm-M-x)
  ("M-y" . helm-show-kill-ring))

(use-package helm-ag)

(use-package helm-projectile
  :demand t
  :after (helm projectile)
  :config
  (helm-projectile-on)
  (setq helm-source-projectile-projects-actions
	(add-to-list 'helm-source-projectile-projects-actions
		     '("Switch to Vterm `s-v`" .
		       (lambda (project)
			 (let
			     ((default-directory project))
			   (projectile-run-vterm))))
		     t)
	)
  )

(use-package helm-swoop
  :commands (helm-swoop)
  :after helm
  :bind
  ("C-c C-s" . helm-multi-swoop-all)
  ("C-c s" . helm-swoop))

;; Helm Company ;;
(use-package helm-company
  :commands (helm-company)
  :after (company helm)
  :init
  (setq helm-company-candidate-number-limit 3000)
  (bind-key "TAB" #'helm-company
            company-active-map))

;; Helpful
(use-package helpful
  :demand t)

(use-package which-key
  :demand
  :delight
  :init
  (which-key-mode 1))

;; Metals
;; Enable scala-mode for highlighting, indentation and motion commands
(use-package scala-mode
  :interpreter ("scala" . scala-mode))

;; Enable sbt mode for executing sbt commands
(use-package sbt-mode
  :commands sbt-start sbt-command
  :config
  ;; WORKAROUND: https://github.com/ensime/emacs-sbt-mode/issues/31
  ;; allows using SPACE when in the minibuffer
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map)
  ;; sbt-supershell kills sbt-mode:  https://github.com/hvesalai/emacs-sbt-mode/issues/152
  (setq sbt:program-options '("-Dsbt.supershell=false")))

;; Enable nice rendering of diagnostics like compile errors.
(use-package flycheck
  :init (global-flycheck-mode)
  :delight flycheck-mode)

(use-package lsp-mode
  ;; Optional - enable lsp-mode automatically in scala files
  ;; You could also swap out lsp for lsp-deffered in order to defer loading
  :hook  (scala-mode . lsp)
  (lsp-mode . lsp-lens-mode)
  :config
  ;; Uncomment following section if you would like to tune lsp-mode performance according to
  ;; https://emacs-lsp.github.io/lsp-mode/page/performance/
  ;; (setq gc-cons-threshold 100000000) ;; 100mb
  ;; (setq read-process-output-max (* 1024 1024)) ;; 1mb
  ;; (setq lsp-idle-delay 0.500)
  ;; (setq lsp-log-io nil)
  ;; (setq lsp-completion-provider :capf)
  (setq lsp-prefer-flymake nil))


;; Add metals backend for lsp-mode
(use-package lsp-metals
  :ensure t
  :init
  ;; hack to get metals to load
  ;; https://github.com/Alexander-Miller/treemacs/issues/982#issuecomment-1291484963
  (require 'treemacs-extensions)
  :after lsp-mode
  :custom
  ;; Metals claims to support range formatting by default but it supports range
  ;; formatting of multiline strings only. You might want to disable it so that
  ;; emacs can use indentation provided by scala-mode.
  (lsp-metals-server-args '("-J-Dmetals.allow-multiline-string-formatting=off"))
  )

;; Enable nice rendering of documentation on hover
;;   Warning: on some systems this package can reduce your emacs responsiveness significally.
;;   (See: https://emacs-lsp.github.io/lsp-mode/page/performance/)
;;   In that case you have to not only disable this but also remove from the packages since
;;   lsp-mode can activate it automatically.
(use-package lsp-ui
  :after lsp-mode)

;; lsp-mode supports snippets, but in order for them to work you need to use yasnippet
;; If you don't want to use snippets set lsp-enable-snippet to nil in your lsp-mode settings
;; to avoid odd behavior with snippets and indentation
(use-package yasnippet
  :demand t
  :delight yas-minor-mode
  :config
  ;; enable yas global mode for better metals completion
  (yas-global-mode 1))

;; these disallow displaying of these specific minor modes in the modline
(use-package eldoc
  :delight eldoc-mode)

;; TODO: this isn't working, see here for details
;; https://elpa.gnu.org/packages/delight.html
(use-package auto-revert
  :delight auto-revert-mode)

(use-package auto-revert
  :delight global-auto-revert-mode)

;; Jump to definition that works even when metals doesn't
;; requires silver searcher or ripgrep. but we're using ripgrep
;; uses: M-. find def. M-? find references. M-, go back. C-M-, go forward
(use-package dumb-jump
  :ensure t
  :config
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate)
  :custom
  (dumb-jump-force-searcher 'rg))

;; TODO notes
;; fontain plugin for beautification (for presenation mode too)
;; hide X on tab bar
;; add tab numbers
;; spacing on tab bar
;; look at LOOK AND FEEL
;; kind icon: https://github.com/jdtsmith/kind-icon
;; ^ might require a switch to corfu. might still work with company.

;; Use company-capf as a completion provider.
;;
;; To Company-lsp users:
;;   Company-lsp is no longer maintained and has been removed from MELPA.
;;   Please migrate to company-capf.
;; (use-package company
;;   :hook (scala-mode . company-mode)
;;   :config
;;   (setq lsp-completion-provider :capf))

(use-package helm-lsp
  :after lsp-mode
  :hook (scala-mode . helm-mode)
  :config
  (define-key lsp-mode-map [remap xref-find-apropos] #'helm-lsp-workspace-symbol))

;; Posframe is a pop-up tool that must be manually installed for dap-mode
(use-package posframe)

;; Use the Debug Adapter Protocol for running tests and debugging
(use-package dap-mode
  :hook
  (lsp-mode . dap-mode)
  (lsp-mode . dap-ui-mode))

;; multiple cursors
(use-package multiple-cursors
  :config
  (global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
  (global-set-key (kbd "C->") 'mc/mark-next-like-this)
  (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
  (global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this))

;; open api
(use-package openapi-yaml-mode
  :load-path "external-packages/openapi-yaml-mode"
  :defer t)

;; projectile
(use-package projectile
  :init (projectile-mode +1)
  :config (setq projectile-project-search-path '(("~/repositories/" . 2) ))
  :bind-keymap ("C-c p" . projectile-command-map)
  )

(use-package flycheck-projectile
  :commands flycheck-projectile-list-errors)

;; Treemacs mods
(use-package treemacs
  :defer t
  :bind
  (:map global-map
	("C-x t t" . treemacs)))

(use-package treemacs-projectile
  :after (treemacs projectile))

(use-package treemacs-magit
  :after (treemacs magit))

(use-package treemacs-all-the-icons
  :after (all-the-icons treemacs))

;; Git
(use-package magit
  :bind (("C-x g" . magit-status)
         ("C-x C-g" . magit-status)))

(use-package forge
  :demand t
  :ensure t
  :after magit)

;;; prefix commit messages with jira ticket
;; (use-package git-commit-jira-prefix
;;   :load-path "libs/git-commit-jira-prefix"
;;   :after git-commit
;;   :commands git-commit-jira-prefix-init
;;   :init (git-commit-jira-prefix-init))

(use-package gh-notify
  :after forge
  :commands (gh-notify))

(use-package code-review
  :after (magit forge)
  :commands (code-review-start code-review-forge-pr-at-point)
  :bind ("C-c g r" . code-review-forge-pr-at-point))

(use-package git-timemachine
  :commands (git-timemachine git-timemachine-toggle)
  :bind ("C-c g t" . git-timemachine-toggle))

(use-package diff-hl
  :after magit
  :init
  (global-diff-hl-mode)
  :hook
  (magit-pre-refresh . diff-hl-magit-pre-refresh)
  (magit-post-refresh . diff-hl-magit-post-refresh))

(use-package git-link
  :commands (git-link git-link-commit git-link-homepage)
  :bind ("C-c g l" . git-link))

;; Window Management
(winner-mode 1)

;; Window Management  ;;
(use-package transpose-frame)

(use-package ace-window
  :ensure t
  :commands (ace-window)
  :bind ("M-o" . ace-window)
  :config
  (setq aw-dispatch-always t)
  (advice-add 'aw--switch-buffer  :override #'bufler-switch-buffer))

(use-package resize-window
  :commands (resize-window)
  :bind ("s-w" . resize-window))

(use-package dimmer
  :demand t
  :config
  (dimmer-configure-which-key)
  (dimmer-configure-helm)
  (dimmer-configure-company-box)
  (dimmer-configure-hydra)
  (dimmer-configure-magit)
  (dimmer-configure-org)
  (dimmer-configure-posframe)

  (dimmer-mode t))

;; format-all
;; format all code
;; note: this config was lifted from here which is why it is commented out.
;; https://ianyepan.github.io/posts/format-all/
(use-package format-all
  :ensure t
  :demand t
  :preface
  (defun ian/format-code ()
    "Auto-format whole buffer."
    (interactive)
    (if (derived-mode-p 'prolog-mode)
        (prolog-indent-buffer)
      (format-all-buffer)))
  :hook ((scala-mode . format-all-mode)
         (nix-mode . format-all-mode))
  )

;; no-littering
(use-package no-littering
  :ensure t
  :demand t
  :init
  (setq no-littering-etc-directory "~/.cache/emacs/etc/"
        no-littering-var-directory "~/.cache/emacs/var/")
  :config
  (setq auto-save-file-name-transforms
        `(("\\`/[^/]*:\\([^/]*/\\)*\\([^/]*\\)\\'"
           ,(concat temporary-file-directory "\\2") t)
          ("\\`\\(/tmp\\|/dev/shm\\)\\([^/]*/\\)*\\(.*\\)\\'" "\\3")
          (".*" ,(no-littering-expand-var-file-name "auto-save/") t)))
  (setq backup-directory-alist
        `(("\\`/tmp/" . nil)
          ("\\`/dev/shm/" . nil)
          (".*" . ,(no-littering-expand-var-file-name "backup/"))))
  (setq custom-file (no-littering-expand-etc-file-name "custom.el"))
  (require 'recentf)
  (add-to-list 'recentf-exclude
               (recentf-expand-file-name no-littering-var-directory))
  (add-to-list 'recentf-exclude
               (recentf-expand-file-name no-littering-etc-directory))
  (when (fboundp 'startup-redirect-eln-cache)
    (startup-redirect-eln-cache
     (convert-standard-filename
      (expand-file-name  "eln-cache/" no-littering-var-directory)))))


;; Looks & Feels
;; simple stuff

;;disable scroll
(use-package scroll-bar
  :config
  (scroll-bar-mode -1))

(use-package mode-line-bell
  :ensure
  :hook (on-first-input . mode-line-bell-mode))

(use-package golden-ratio-scroll-screen
  :ensure t
  :demand t
  :config
  (global-set-key [remap scroll-down-command] 'golden-ratio-scroll-screen-down)
  (global-set-key [remap scroll-up-command] 'golden-ratio-scroll-screen-up)
  )

(use-package hl-line
  :init
  (global-hl-line-mode)
)

;; Spaceline
(use-package spaceline
  :ensure t
  :demand t
  :config
  (spaceline-emacs-theme)
  (spaceline-toggle-nyan-cat-on)
  (spaceline-toggle-version-control-off)
  (use-package helm
    :config
    (spaceline-helm-mode))
  )

;; nyan-cat
(use-package nyan-mode
  :ensure t
  :demand t
  :init
  (nyan-mode 1)
  :config
  (nyan-start-animation)
  (nyan-bar-length 4)
  )

;; Fontaine
;; (use-package fontaine
;;   :ensure t
;;   :demand t
;;   :custom
;;   (fontaine-presets
;;    `((regular
;;       :default-height 120
;;       :line-spacing 0.25)
;;      (small
;;       :default-height 100
;;       :line-spacing 0.2)
;;      (presentation
;;       :default-height 210
;;       :line-spacing 0.125)
;;      (t ;; defaults
;;       :default-family
;;       ,(cond
;;         ((find-font (font-spec :name "FiraCode Nerd Font"))
;;          "FiraCode Nerd Font")
;;         ("Monospace")))))
;;   :config
;;   (fontaine-set-preset (or fontaine-current-preset 'regular)))



;; UNDO TREE
(use-package undo-tree
  :ensure t
  :demand t
  :delight
  :config
  (global-undo-tree-mode)
  (setq undo-tree-history-directory-alist
        `((".*\.gpg" . "/dev/null")
          (,(concat "\\`" (file-name-as-directory temporary-file-directory)))
          ("\\`/tmp/" . nil)
          ("\\`/dev/shm/" . nil)
          ("." . ,(no-littering-expand-var-file-name "undo-tree-hist/")))))

;; Verb
;;; verb --- this is where we configure verb to make queries in org mode

(use-package verb
  :ensure
  :demand t
  :after org
  :custom
  (verb-babel-timeout 30)
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   (append org-babel-load-languages
           '((verb . t)))))

;; JWTS and whatnot

(use-package request
  :ensure
  :demand t)

(defun dgibs/bubauth (env bannoPassword)
  "Run's Beelzebub tool to fetch an eauth token in ENV."
  (shell-command-to-string
   (concat "BEELZEBUB_PASS='" bannoPassword "' "
           "beelzebub login --force --env " env)))

(defun dgibs/get-ip-address ()
  "Get the current public IP Address."
  (request-response-data
   (request "https://api.ipify.org/"
     :sync t)))

(defun dgibs/get-jwt-url (institutionId userId env)
  "Construct the url needed to get a banno-jwt from an eauth cookie."
  (format "http://%s-centralus-aks-shared-nodes.banno-%s.com:32598/v0/gateway/jwt?institutionId=%s&consumerUserId=%s&requestMethod=get&requestUrl=/a/mobile/api/v0/institutions/%s/users/%s/abilities"
          env env institutionId userId institutionId userId))

(defun dgibs/envTobeelzEnv (env)
  "Convert a full Banno ENV name to a beelze name."
  (if (string= env "production")
      "PROD"
    (if (string= env "uat")
        "UAT"
      env)))


(defun dgibs/get-jwt (bannoPassword institutionId userId env)
  (let ((ipaddress (dgibs/get-ip-address))
        (eauth (dgibs/bubauth (dgibs/envTobeelzEnv env) bannoPassword))
        (nodeGatewayUrl (dgibs/get-jwt-url institutionId userId env)))
    (let ((cookies (format "eauth=%s" eauth)))
      (message (concat "eauth: " eauth))
      (message (concat "node-gateway: " nodeGatewayUrl))
      (message (concat "ipaddress: " ipaddress))
      `(,eauth ,(request-response-header
                 (request nodeGatewayUrl
                   :type "GET"
                   :headers `(("Cookie" . ,cookies)
                              ("X-Forwarded-For" . ,ipaddress))
                   :sync t
                   :success
                   (cl-function
                    (lambda (&key data &allow-other-keys)
                      (message "Node Gateway request success: %s" data)))
                   :error
                   (cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
                                  (message "Got error: %S" error-thrown))))
                 "X-BannoEnterprise0")))))


(defmacro dgibs/verb-get-var (name &optional default)
  `(progn
     (when (stringp ',name)
       (user-error "%s (got: \"%s\")"
                   "[verb-var] Variable name must be a symbol, not a string"
                   ',name))
     (let ((value (assoc-string ',name verb--vars)))
       (if (null value)
           (,default)
         (cdr value)))))

(defvar-local dgibs/banno-pass nil
  "Buffer local storage place for banno password so it doesn't need to be repeated anymore")
(defun dgibs/banno-pass-unset ()
  "Clears dgibs/banno-pass"
  (interactive)
  (setq dgibs/banno-pass nil))

(defvar-local dgibs/banno-jwt nil
  "Last Fetched banno Jwt")
(defvar-local dgibs/banno-eauth nil
  "Last Fetched banno eauth")
(defun dgibs/banno-jwt-unset ()
  "unset the banno jwt"
  (interactive)
  (setq dgibs/banno-jwt nil))
(defun dgibs/banno-jwt-and-eauth-unset ()
  "unset the banno jwt and eauth"
  (interactive)
  (setq dgibs/banno-jwt nil)
  (setq dgibs/banno-eauth nil))

(defun dgibs/is-jwt-expired (jwt)
  (let* ((middle (car (cdr (split-string jwt "\\."))))
         (jsonMiddle (base64-decode-string middle t))
         (exp (gethash "exp" (json-parse-string jsonMiddle)))
         (curTime (float-time)))
    (>= curTime exp)))

(defun dgibs/verb-jwt ()
  "Verb helper to get banno JWT assuming Beelzebub in installed."
  (interactive)
  (if (or (null dgibs/banno-jwt) (dgibs/is-jwt-expired dgibs/banno-jwt))
      (dgibs/verb-get-var jwt
                          (lambda ()
                            (pcase-let ((`(,eauth, fetchedJwt) (dgibs/get-jwt
                                                                (progn (when (null dgibs/banno-pass)
                                                                         (setq dgibs/banno-pass (read-passwd "Banno Password? ")))
                                                                       dgibs/banno-pass)
                                                                (verb-var institutionId)
                                                                (verb-var consumerUserId)
                                                                (verb-var env))))
                              (if (null fetchedJwt)
                                  (error "%s: %s" "Failed to get JWT" fetchedJwt)
                                (progn
                                  (setq dgibs/banno-jwt fetchedJwt)
                                  (setq dgibs/banno-eauth eauth)
                                  fetchedJwt)))))
    dgibs/banno-jwt))

;;TODO: replace this with the uuidgen package
(defun dgibs/generate-uuid ()
  (s-trim (shell-command-to-string "uuidgen")))

;; Copilot
(use-package copilot
  :ensure t
  :demand t
  :custom
  (copilot-idle-delay 0.5)
  ;; :bind
  ;; (:map ross/toggles-map
  ;;  ("<tab>" . copilot-mode))
  :bind
  (:map copilot-completion-map
	("C-g" . 'copilot-clear-overlay)
	("M-p" . 'copilot-previous-completion)
	("M-n" . 'copilot-next-completion)
	("<tab>" . 'copilot-accept-completion)
	("M-f" . 'copilot-accept-completion-by-word)
	("M-<return>" . 'copilot-accept-completion-by-line)))

;; Open-AI
(use-package org-ai
  :ensure t
  :commands (org-ai-mode
             org-ai-global-mode)
  :init
  ;;(add-hook 'org-mode-hook #'org-ai-mode) ; enable org-ai in org-mode
  :bind-keymap ("C-c M-a" . org-ai-global-prefix-map)
  ;;(org-ai-global-mode) ; installs global keybindings on C-c M-a
  :config
  (setq org-ai-default-chat-model "gpt-4") ; if you are on the gpt-4 beta:
  (org-ai-install-yasnippets)) ; if you are using yasnippet and want `ai` snippets

(use-package nix-mode
  :ensure t
  :mode "\\.nix\\'")
