;; Early init

;; [[file:index.org::*Early init][Early init:1]]
;; (require 'benchmark-init)
;; (add-hook 'after-init-hook 'benchmark-init/deactivate)

;; All our packages come from Nix
(setq package-enable-at-startup nil
      package-archives nil)
;; Early init:1 ends here

;; Setup Garbage Collection
;; Minimize the garbage collection when startup happens, but reset it back to normal after startup.

;; [[file:index.org::*Setup Garbage Collection][Setup Garbage Collection:1]]
;; Minimize garbage collection during startup
(setq gc-cons-threshold most-positive-fixnum)

;; Lower threshold back to 8 MiB (default is 800kB) after startup
(defvar dgibs/gc-cons-threshold-default (* 100 (expt 2 20)))
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold dgibs/gc-cons-threshold-default)))
;; Setup Garbage Collection:1 ends here

;; Wrap up Early init

;; [[file:index.org::*Wrap up Early init][Wrap up Early init:1]]
(provide 'early-init)
;; Wrap up Early init:1 ends here
