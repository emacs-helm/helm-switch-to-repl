;;; helm-switch-to-repl-eshell-mode.el --- Helm action to switch directory in Eshells -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Pierre Neidhardt

;; Author: Pierre Neidhardt <mail@ambrevar.xyz>
;; Maintainer: Pierre Neidhardt <mail@ambrevar.xyz>
;; URL: https://github.com/emacs-helm/helm-switch-to-repl
;; Version: 0.0.0
;; Package-Requires: ((emacs "26.1") (helm "3"))

;; This file is not part of GNU Emacs.

;;; License:
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <https://www.gnu.org/licenses/>

;;; Commentary:
;;
;; Helm "Switch-to-REPL" for Eshell.

;;; Code:
(require 'helm-switch-to-repl)

(declare-function eshell/cd "em-dirs.el")
(declare-function eshell-next-prompt "em-prompt.el")
(declare-function eshell-reset "esh-mode.el")

(cl-defmethod helm-switch-to-repl-cd-repl ((_mode (eql eshell-mode)))
  (eshell/cd helm-ff-default-directory)
  (eshell-reset))

(cl-defmethod helm-switch-to-repl-new-repl ((_mode (eql eshell-mode)))
  (eshell helm-current-prefix-arg))

(cl-defmethod helm-switch-to-repl-interactive-buffer-p ((buffer t) (_mode (eql eshell-mode)))
  (with-current-buffer buffer
    (helm-switch-to-repl--has-next-prompt? #'eshell-next-prompt)))

(cl-defmethod helm-switch-to-repl-shell-alive-p ((_mode (eql eshell-mode)))
  (get-buffer-process (current-buffer)))

(provide 'helm-switch-to-repl-eshell-mode)
;;; helm-switch-to-repl.el ends here
