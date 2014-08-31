;;; rings.el --- Buffer rings. Like tabs, but better.

;; Copyright 2013 Konrad Scorciapino

;; Author: Konrad Scorciapino
;; Keywords: utilities, productivity
;; URL: http://github.com/konr/rings
;; Version: 1.0.1

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;; Code goes here
(require 'cl)


(defmacro rings->> (x &optional form &rest more)
  "Like clojure's ->>"
  (if (null form) x
    (if (null more)
        (if (sequencep form)
            `(,(car form) ,@(cdr form) ,x)
          (list form x))
      `(rings->> (rings->> ,x ,form) ,@more))))

(defvar rings-used-rings '()
  "List of buffer rings")

(defun rings-add-buffer (key)
  "Add current buffer to ring attached to KEY.

This is done by setting the name of the ring as a buffer-local variable"
  (let ((variable-name (intern (format "rings-%s" key))))
    (unless (member variable-name rings-used-rings)
      (add-to-list 'rings-used-rings variable-name))
    (unless (boundp variable-name)
      (set (make-local-variable variable-name) t)
      (message "Added!"))))

(defun rings-remove-buffer (key)
 "Remove current buffer to ring attached to KEY.

This is done by killing local variable ring-KEY"
  (let ((variable-name (intern (format "rings-%s" key))))
    (when (boundp variable-name)
    (kill-local-variable variable-name)
    (message "Removed!"))))

(defun rings-toggle-buffer (key)
"Togger belonging of current-buffer to the KEY ring"
  (let ((variable-name (intern (format "rings-%s" key))))
    (if (boundp variable-name)
        (rings-remove-buffer key)
      (rings-add-buffer key))))

(defun rings-buffers (key)
  "Retrieve all the buffers attached to the KEY ring.

Note: this is done going through all buffer checkying if they belong to KEY ring."
  (remove-if-not
   (lambda (x) (assoc (intern (format "rings-%s" key)) (buffer-local-variables x)))
   (buffer-list)))

(defun rings-cycle (key)
  "Perform a 'Cycle' in KEY ring."
  (let ((buffers (sort (mapcar #'buffer-name (rings-buffers key)) #'string<))
        (current (buffer-name (current-buffer))))
    (if (not buffers) (message "Empty group!")
      (loop for all = (append buffers buffers) then (cdr all)
            until (or (not all) (equal current (car all)))
            finally
            (let ((new (or (cadr all) (car buffers))))
              (switch-to-buffer (get-buffer new))
              (rings->> buffers (mapcar (lambda (b)
                                     (if (equal b new) (format "((%s))" b) b
                                        ; <taylanub> konr: I'm not sure if that's a good idea; the message-area is
                                        ;  supposed to print the object in an unambiguous way ...
                                        ;
                                        ;(propertize current
                                        ;'font-lock-face '(:weight
                                        ;bold :foreground
                                        ;"#ff0000")) b
                                         )))
                   (mapcar (lambda (x) (concat x " ")))
                   (apply #'concat) message))))))

(defvar rings-protect-buffers-in-rings t)

(defun rings-protect-buffer-handler ()
  (if rings-protect-buffers-in-rings
      (let ((killable t))
        (mapc
         (lambda (ring)
           (when  (boundp ring)
             (setq killable nil)))
         rings-used-rings)
        (unless killable
          (previous-buffer))
        killable)
    t))

(add-hook 'kill-buffer-query-functions 'rings-protect-buffer-handler)

;;;###autoload
(defmacro rings-generate-toggler (key)
  "Generate a toggler function for the KEY ring."
  `(lambda () (interactive) (rings-toggle-buffer ,key)))

;;;###autoload
(defalias 'rings-generate-setter 'rings-generate-toggler
  "Generate a toggler function for the KEY ring.")

;;;###autoload
(defmacro rings-generate-adder (key)
  "Generate a adder function for the KEY ring."
 `(lambda () (interactive) (rings-add-buffer ,key)))

;;;###autoload
(defmacro rings-generate-remover (key)
  "Generate a remover function for the KEY ring."
  `(lambda () (interactive) (rings-remove-buffer ,key)))

;;;###autoload
(defmacro rings-generate-cycler (key)
  "Generate a cycler function for the KEY ring."
  `(lambda () (interactive) (rings-cycle ,key)))


(provide 'rings)
;;; rings.el ends here
