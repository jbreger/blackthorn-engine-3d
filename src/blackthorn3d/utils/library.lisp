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

(in-package :blackthorn3d-utils)

;;;
;;; Runtime dependencies which must be loaded into the lisp executable prior
;;; to calling any SDL functionality. Normally this is done when loading the
;;; system definiton, but must be done manually for distributed executables.
;;;

; from http://code.google.com/p/lispbuilder/source/browse/trunk/lispbuilder-sdl/cffi/library.lisp
(defun load-sdl-dlls ()
  #+darwin
  (let ((frameworks
         (merge-pathnames
          (make-pathname :directory '(:relative :up "Frameworks")))))
    (if (fad:directory-exists-p frameworks)
        (pushnew frameworks cffi:*darwin-framework-directories* :test #'equal)))
  #+darwin
  (cffi:define-foreign-library cocoahelper
    (:darwin (:or (:framework "cocoahelper")
                  (:default "cocoahelper"))))
  #+darwin
  (cffi:use-foreign-library cocoahelper)
  (cffi:define-foreign-library sdl
    (:darwin (:or (:framework "SDL")
                  (:default "libSDL")))
    (:windows "SDL.dll")
    (:unix (:or "libSDL-1.2.so.0.7.2"
                "libSDL-1.2.so.0"
                "libSDL-1.2.so"
                "libSDL.so"
                "libSDL")))
  (cffi:use-foreign-library sdl)
  #+darwin (lispbuilder-sdl-cocoahelper::cocoahelper-init))

; from http://code.google.com/p/lispbuilder/source/browse/trunk/lispbuilder-sdl-image/cffi/library.lisp
(defun load-sdl-image-dlls ()
  (cffi:define-foreign-library sdl-image
    (:darwin (:or (:framework "SDL_image")
                  (:default "libSDL_image")))
    (:windows (:or "SDL_image.dll" "SDL_image1.2.dll"))
    (:unix (:or "libSDL_image-1.2.so.0"
                "libSDL_image1.2"
                "libSDL_image.so")))
  (cffi:use-foreign-library sdl-image))

; from http://code.google.com/p/lispbuilder/source/browse/trunk/lispbuilder-sdl-mixer/cffi/library.lisp
(defun load-sdl-mixer-dlls ()
  (cffi:define-foreign-library sdl-mixer
    (:darwin (:or (:framework "SDL_mixer")
                  (:default "libSDL_mixer")))
    (:windows "SDL_mixer.dll")
    (:unix (:or "libSDL_mixer"
                "libSDL_mixer.so"
                "libSDL_mixer-1.2.so"
                "libSDL_mixer-1.2.so.0")))
  (cffi:use-foreign-library sdl-mixer))

#+windows
(defun load-xbox ()
   "Load the xbox 360 input device"
    (cffi:define-foreign-library xbox360
      (:windows "xbox360.dll"))
	(cffi:use-foreign-library xbox360))

(defun load-dlls ()
  "Loads dlls needed to run SDL, SDL_image, and SDL_gfx."
  (load-sdl-dlls)
  (load-sdl-image-dlls)
  (load-sdl-mixer-dlls)
  #+windows (load-xbox))

(eval-when (:load-toplevel)
  (load-dlls))
