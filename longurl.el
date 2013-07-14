;;; longurl.el --- a package to expand short URLs

;;; Copyright (C) 2013 Rudi Schlatte

;;; longurl.el is free software; you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 2, or (at your option)
;;; any later version.
;;;
;;; longurl.el is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License at <http://www.gnu.org/licenses/> for more
;;; details.

;;; Commentary:
;;;
;;; This package uses the API of http://longurl.org/ to expand
;;; abbreviated URLs often found on twitter or in mail messages.
;;; 
;;; There are two main entry points:
;;; 
;;; - `longurl-expand' takes an URL to expand and returns the expanded
;;;   URL and, when called interactively, also displays it in the echo
;;;   area.
;;; 
;;; - `longurl-expand-at-point' replaces the URL at point with the
;;;   expanded URL.
;;; 
;;; - Additionally, `longurl-list-services' returns a list of all
;;;   services (is.gd, tinyurl.com, ...) that longurl.org knows how to
;;;   expand.

;;; Code:

(require 'url)
(require 'url-http)
(require 'cl-lib)
(require 'thingatpt)

;;; The longurl.org guys like meaningful user-agent strings.  If you use
;;; `longurl-expand' from another package, you might consider rebinding
;;; these variables and letting them know about your code.  See
;;; <http://longurl.org/api#courteous-usage> for details.
(defvar longurl-package-name "Emacs-longurl")
(defvar longurl-package-version "0.1")

(defun longurl--query-server (query)
  "Return result of `QUERY' as parsed xml."
  (let* ((url-package-name longurl-package-name)
         (url-package-version longurl-package-version)
         (http-buf (url-retrieve-synchronously query)))
    (prog1
        (save-excursion
         (set-buffer http-buf)
         (goto-char (point-min))
         (re-search-forward "<?xml version=")
         (beginning-of-line)
         (libxml-parse-xml-region (point) (point-max)))
      (kill-buffer http-buf))))

(defun longurl-list-services ()
  "Return the list of services that longurl.org knows how to expand."
  (interactive)
  (cl-loop for service
           in (rest (rest (third (longurl--query-server
                                  "http://api.longurl.org/v2/services"))))
           collect (third service)))

(defun longurl-expand (url)
  "Expand URL and return the result.
Also print the expansion result in the echo area if called interactively."
  (interactive "MURL: ")
  (let ((result (third (third (longurl--query-server (format "http://api.longurl.org/v2/expand?url=%s" (url-encode-url url)))))))
    (when (called-interactively-p 'any)
      (message result))
    result))

(defun longurl-expand-at-point ()
  "Replace URL at point with expanded URL."(interactive)
  (let ((bounds (bounds-of-thing-at-point 'url)))
    (if bounds
        (let ((url (longurl-expand (thing-at-point 'url))))
          (when url
            (save-excursion
             (atomic-change-group
              (goto-char (cdr bounds))
              (insert url)
              (delete-region (car bounds) (cdr bounds))))))
        (message "No URL found at point, sorry."))))

(provide 'longurl)

;;; longurl.el ends here
