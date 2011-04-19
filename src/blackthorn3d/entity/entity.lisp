;;;; Blackthorn -- Lisp Game Engine
;;;;
;;;; Copyright (c) 2011, Elliott Slaughter <elliottslaughter@gmail.com>
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

(in-package :blackthorn3d-entity)

(defclass entity ()
  ((oid
    :accessor oid)
   (pos
    :accessor pos
    :initarg :pos)
   (dir
    :accessor dir
    :initarg :dir)
   (veloc
    :accessor veloc
    :initarg :veloc)))

(defclass entity-server (entity)
  ((oid
    :initform (make-server-oid))))

(defclass entity-client (entity)
  ((oid
    :initarg :oid)))

(defun make-client-entity (oid)
  (make-instance 'entity-client :oid oid))

(defun lookup-client-entity (oid)
  (error "unimplemented"))

(make-init-slot-serializer :entity-create
                           (make-client-entity) (:oid oid)
                           (:vec3 pos
                            :vec3 dir
                            :vec3 veloc))

(make-init-slot-serializer :entity-update-fields
                           (lookup-client-entity) (:oid oid)
                           (:vec3 pos
                            :vec3 dir
                            :vec3 veloc))
