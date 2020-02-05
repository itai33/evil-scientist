;;; evil-tex.el --- Useful features for editing TeX in evil-mode -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2020 Yoav Marco, Itai Y. Efrat
;;
;; Author: Yoav Marco <http://github/yoavm448>, Itai Y. Efrat <http://github/itai33>
;; Maintainers: Yoav Marco <yoavm448@gmail.com>, Itai Y. Efrat <itai3397@gmail.com>
;; Created: February 01, 2020
;; Modified: February 01, 2020
;; Version: 0.0.1
;; Keywords:
;; Homepage: https://github.com/itai33/evil-tex
;; Package-Requires: ((evil "1.0") (auctex "11.88") (dash "2.14.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Useful features for editing TeX in evil-mode
;;
;;; Code:


;; To start, let us try to define a text object for an enviornment,
;; although there might be a better way to do this than regex


;;; Code:

(require 'evil)

;; FIXME how to better load local files
(load "evil-tex-util")

(defun evil-tex-brace-movement ()
  "Brace movement similar to TAB in cdlatex.

Example: (| symbolizes point)
\bar{h|} => \bar{h}|
\frac{a|}{} => \frac{a}{|}
\frac{a|}{b} => \frac{a}{b|}
\frac{a}{b|} => \frac{a}{b}|"
  (interactive)
  ;; go to the closing } of the current scope
  (search-backward "{" (line-beginning-position))
  (forward-sexp)
  ;; encountered a {? go to just before its terminating }
  (when (looking-at "{")
    (forward-sexp)
    (backward-char)))


;; stolen code from https://github.com/hpdeifel/evil-tex
(evil-define-text-object evil-tex-inner-dollar (count &optional beg end type)
  "Select inner dollar"
  :extend-selection nil
  (evil-select-quote ?$ beg end type count nil))

(evil-define-text-object evil-tex-a-dollar (count &optional beg end type)
  "Select a dollar"
  :extend-selection t
  (evil-select-quote ?$ beg end type count t))

(evil-define-text-object evil-tex-inner-math (count &optional beg end type)
  "Select innter \\[ \\] or \\( \\)."
  :extend-selection nil
  (evil-select-paren (rx (or "\\(" "\\["))
                     (rx (or "\\)" "\\]"))
                     beg end type count nil))

(evil-define-text-object evil-tex-a-math (count &optional beg end type)
  "Select a \\[ \\] or \\( \\)."
  :extend-selection nil
  (evil-select-paren (rx (or "\\(" "\\["))
                     (rx (or "\\)" "\\]"))
                     beg end type count t))


(evil-define-text-object evil-tex-a-macro (count &optional beg end type)
  "Select a TeX macro"
  :extend-selection nil
  (let ((beg (evil-tex-macro-beginning-begend))
        (end (evil-tex-macro-end-begend)))
    (if (and beg end)
        (list (car beg) (cdr end))
      (error "No enclosing macro found"))))

(evil-define-text-object evil-tex-inner-macro (count &optional beg end type)
  "Select inner TeX macro, i.e the argument to the macro."
  :extend-selection nil
  (let ((beg (evil-tex-macro-beginning-begend))
        (end (evil-tex-macro-end-begend)))
    (cond
     ((or (null beg) (null end))
      (error "No enclosing macro found"))
     ((= (cdr beg) (car end))          ;; macro has no content
      (list (1+ (car beg))             ;; return macro boundaries excluding \
            (cdr beg)))
     (t (list (cdr beg) (car end))))))


(evil-define-text-object evil-tex-an-env (count &optional beg end type)
  "Select a LaTeX environment"
  :extend-selection nil
  (let ((beg (evil-tex-env-beginning-begend))
        (end (evil-tex-env-end-begend)))
    (list (car beg) (cdr end))))

(evil-define-text-object evil-tex-inner-env (count &optional beg end type)
  "Select a LaTeX environment"
  :extend-selection nil
  (let ((beg (evil-tex-env-beginning-begend))
        (end (evil-tex-env-end-begend)))
    (list (cdr beg) (car end))))


(defun evil-tex-change-env-interactive ()
  "Like `evil-tex-change-env' but prompts you for NEW-ENV."
  (interactive)
  (-> (LaTeX-current-environment)
      (format "Change %s to: ")
      (read-string)
      (evil-tex-change-env)))


(defvar evil-tex-outer-map (make-sparse-keymap))
(defvar evil-tex-inner-map (make-sparse-keymap))

(set-keymap-parent evil-tex-outer-map evil-outer-text-objects-map)
(set-keymap-parent evil-tex-inner-map evil-inner-text-objects-map)

(define-key evil-tex-inner-map "e"  'evil-tex-inner-env)
(define-key evil-tex-inner-map "$"  'evil-tex-inner-dollar) ;; TODO merge with normal math
(define-key evil-tex-inner-map "c"  'evil-tex-inner-macro)
(define-key evil-tex-inner-map "m" 'evil-tex-inner-math)

(define-key evil-tex-outer-map "e"  'evil-tex-an-env)
(define-key evil-tex-outer-map "$"  'evil-tex-a-dollar) ;; TODO merge with normal math
(define-key evil-tex-outer-map "c"  'evil-tex-a-macro)
(define-key evil-tex-outer-map "m" 'evil-tex-a-math)

(evil-define-key 'operator evil-tex-mode-map
  "a" evil-tex-outer-map
  "i" evil-tex-inner-map)

(evil-define-key 'visual evil-tex-mode-map
  "a" evil-tex-outer-map
  "i" evil-tex-inner-map)

(define-minor-mode evil-tex-mode
  "Minor mode for latex-specific text objects in evil.

Installs the following additional text objects:
\\<evil-tex-outer-map>
  \\[evil-tex-a-math]   Display math      \\=\\[ .. \\=\\]
  \\[evil-tex-a-dollar] Inline math       $ .. $ TODO Merge with normal math
  \\[evil-tex-a-macro]  TeX macro         \\foo{..}
  \\[evil-tex-an-env]   LaTeX environment \\begin{foo}..\\end{foo}"
  :keymap (make-sparse-keymap)
  (evil-normalize-keymaps))


;;;###autoload
(defun turn-on-evil-tex-mode ()
  "Enable evil-tex-mode in current buffer."
  (interactive)
  (evil-tex-mode 1))

;;;###autoload
(defun turn-off-evil-tex-mode ()
  "Disable evil-tex-mode in current buffer."
  (interactive)
  (evil-tex-mode -1))



(provide 'evil-tex)

;;; evil-tex ends here
