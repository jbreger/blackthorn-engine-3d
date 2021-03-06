;;;; Blackthorn -- Lisp Game Engine
;;;;
;;;; Copyright (c) 2007-2011, Elliott Slaughter <elliottslaughter@gmail.com>
;;;;
;;;; Permission is hereby granted, free of charge, to any person
;;;; obtaining a copy of this software and associated documentation
;;;; files (the "Software"), to deal in the Software without
;;;; restriction, including without limitation the rights to use, copy,
;;;; modify, merge, publish, distribute, sublicense, and/or sell copies
;;;; of the Software, and to permit persons to whom the Software is
;;;; furnished to do so, subject to the following conditions:
;;;;
;;;; The above copyright notice and this permission notice shall be
;;;; included in all copies or substantial portions of the Software.
;;;;
;;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;;;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;;; NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;;;; DEALINGS IN THE SOFTWARE.
;;;;

(eval-when (:compile-toplevel :load-toplevel :execute)
  #+quicklisp
  (ql:quickload :trivial-features)
  #-quicklisp
  (asdf:oos 'asdf:load-op :trivial-features))

#+(and sbcl windows) (load-shared-object "msvcr71.dll")

#+quicklisp
(ql:quickload :atdoc)
#+quicklisp
(ql:quickload :cl-fad)
#+quicklisp
(ql:quickload :blackthorn3d)

#-quicklisp
(require :asdf)
#-quicklisp
(asdf:oos 'asdf:load-op :atdoc)
#-quicklisp
(asdf:oos 'asdf:load-op :cl-fad)
#-quicklisp
(asdf:oos 'asdf:load-op :blackthorn3d)

;;;
;;; Setup directories for build.
;;;

(defun cwd ()
  (truename (make-pathname)))

(defun append-directory (default-pathname &rest directories)
  (merge-pathnames
   (make-pathname :directory (cons :relative directories))
   default-pathname))

(defconstant +working-dir+ (cwd))

(defconstant +doc-dir+ (append-directory +working-dir+ "doc"))

(if (fad:file-exists-p +doc-dir+)
    (fad:delete-directory-and-files +doc-dir+))
(ensure-directories-exist +doc-dir+)

;;;
;;; Build documentation.
;;;

(atdoc:generate-html-documentation
 '(:blt3d-ent :blt3d-gfx :blt3d-input :blt3d-main :blt3d-math :blt3d-net :blt3d-phy :blt3d-res :blt3d-utils)
 +doc-dir+
 :index-title "Blackthorn API Reference"
 :heading "Blackthorn -- Lisp Game Engine")

#+disable
(atdoc:generate-latex-documentation
 '(:blt3d)
 +doc-dir+
 :title "Blackthorn API Reference")

(blt3d-main::exit)
