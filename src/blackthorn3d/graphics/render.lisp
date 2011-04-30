;;;; Blackthorn -- Lisp Game Engine
;;;;
;;;; Copyright (c) 2011, Robert Gross <r.gross.3@gmail.com>
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

(in-package :blackthorn3d-graphics)


(defvar *main-cam* nil)
(defvar *main-cam-quat* nil)
(defvar *frustum* nil)

(defparameter cube-mesh nil)
(defparameter cube-mat nil)
(defparameter cube-tex nil)
(defparameter vao-cube nil)
(defparameter shader nil)

(defun init ()
  "Called to initialize the graphics subsystem"
  (setf %gl:*gl-get-proc-address* #'sdl:sdl-gl-get-proc-address)
  #+disabled
  (setf *main-cam* (make-instance 'camera 
                           :position (make-point3 10.0 20.0 10.0)
                           :direction (norm4 (vec4- (make-vec3 0.0 0.0 0.0)
                                                    (make-vec3 10.0 20.0 10.0)))
                           :up (make-vec3 0.0 1.0 0.0)
                           
                           :mode :third-person ))
  ;#+disabled
  (setf *main-cam* (make-instance 'camera
                                  :target (make-point3 0.0 1.0 0.0)
                                  :up (make-vec3 0.0 1.0 0.0)
                                  :ideal-coord (list 0.0 (/ pi 6) 15.0)
                                  :ks 100.0
                                  :mode :third-person))

  (setf *main-cam-quat* (axis-rad->quat (make-vec3 0.0 1.0 0.0) (/ pi 100)))
  (setf *frustum* (make-frstm 1.0 1000.0 8/6 (/ pi 2)))
  (setf cube-mesh (car (load-dae #p "res/models/orange-box2.dae"))))


(defun prepare-scene ()
  "Called after sdl is initialized, before first frame is drawn
   or when changing the 'scene' settings"
  (gl:viewport 0 0 800 600)

  (gl:enable :texture-2d)
  (gl:enable :blend)
  (gl:blend-func :src-alpha :one-minus-src-alpha)
  (gl:clear-color 0 0 0 0)
  (gl:enable :depth-test)
  (gl:depth-func :lequal)

  (setf cube-tex (image->texture2d 
                  (load-image #p"res/images/test-tex.png")))
  (setf cube-mat (make-instance 'material
                                :ambient #(.5 .38 0.0 1.0)
                                :diffuse #(1.0 .75 0.0 1.0)
                                :tex cube-tex))

  (load-frstm *frustum*)
  (gl:load-identity)
  (gl:light :light0 :position '(20.0 20.0 20.0 1.0))
  (gl:light :light0 :diffuse (make-vec3 1.0 1.0 1.0))
 ; (gl:enable :lighting)
  (gl:enable :light0)

  #+disabled
  (setf shader (make-shader (blt3d-res:file-contents
                             (blt3d-res:resolve-resource 
                              #p "res/shaders/FinalProjShader.vert"))
                            (blt3d-res:file-contents
                             (blt3d-res:resolve-resource
                              #p "res/shaders/FinalProjShader.frag"))))
  
  ;(make-vao-cube)
  )


(defun render-frame (entities)
  (gl:clear :color-buffer-bit :depth-buffer-bit)
  ;(gl:load-matrix (rt-inverse (camera-matrix *main-cam*)))
  ;(gl:load-matrix (camera-inverse *main-cam*))
  #+disabled(gl:load-matrix (look-at-matrix (make-point3 15.0 20.0 15.0)
                                  (make-point3 0.0 0.0 0.0)
                                  (make-vec3 0.0 1.0 0.0)))

    ;(gl:use-program shader)
  (gl:use-program 0)
 
  (dolist (e entities)
    (with-slots ((pos blt3d-ent:pos) 
                 (dir blt3d-ent:dir) 
                 (up blt3d-ent:up) 
                 (shape blt3d-ent:shape)) e
      (let ((x (cross up dir)))
        (setf (cam-target *main-cam*) pos)
        (update-camera *main-cam* (/ 1.0 (sdl:frame-rate)))
        (gl:load-matrix (cam-matrix *main-cam*))

        (gl:light :light0 :position '(6.0 6.0 6.0 1.0))

        (gl:color 1.0 0.0 0.0)
        (draw-plane 20)
        (gl:color 0.0 1.0 1.0)

        (gl:with-pushed-matrix
          (gl:translate (x pos) (y pos) (z pos))
          (gl:scale .1 .1 .1)
          ;(gl:mult-matrix (make-ortho-basis x up dir))
          (draw-object shape)))))

  #+disabled
  (gl:with-pushed-matrix
    (gl:rotate 90 1.0 0.0 0.0)
    (gl:scale .5 .5 .5)
    (use-material cube-mat)
    (draw-object cube-mesh))
  
  (gl:flush)
  (sdl:update-display))