;;;; Blackthorn -- Lisp Game Engine
;;;;
;;;; Copyright (c) 2011 Chris McFarland <askgeek@gmail.com>
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

(in-package :blackthorn3d-main)

        
(defgeneric update (a-server-entity))

(defmethod update ((e entity-server))
    (declare (ignore e)))

(defmethod update ((p Player))
    (with-slots (client) p
      #+disabled
      (setf (pos p)
        (vec4+ (pos p)
               (make-vec3 (float (s-input-move-x client)) 
                          0.0 
                          (float (s-input-move-y client)))))))

(defun is-alive-p (thing)
  (oid-in-use-p (oid thing)))
                          
(defmethod update ((c blt3d-gfx:camera))
  (let* ((player (blt3d-gfx:target c))
         (client (player-client player)))
    (when (not (is-alive-p player))
      (remove-entity c)
      (return-from update))
    (blt3d-gfx:move-player c (vector (s-input-move-x client)
                                     (s-input-move-y client)))
    (blt3d-gfx:update-camera c (/ 1.0 120.0) (vector (s-input-view-x client)
                                                     (s-input-view-y client)))))
      
(defmacro make-server-only (type &rest options)
  `(make-server-entity ,type 
      ; init w/ bogus values since these fields are not needed for server obj
      :pos (make-point3 0.0 0.0 0.0)  
      :dir (make-vec3 1.0 0.0 0.0)
      :up  (make-vec3 0.0 1.0 0.0)
      ,@options))
      
(defun next-frame ()
  (sleep 1/120)
  )

(defvar *client-count* 0)

(defun check-for-clients ()
  (let ((client (socket-server-connect :timeout 0)))
    (when client
      (incf *client-count*)
      (format t "Client ~a joined! (Total: ~a)~%" client *client-count*))
    client))

(defun read-string (msg)
  (message-value msg))

(defun send-string (dst str)
  (message-send dst (make-message :string str)))

(defun send-all-entities (destination)
  (message-send destination (make-event :entity-create :include-all t)))

(defun handle-message-server (src message)
  (ecase (message-type message)
    (:string
     (let ((str (read-string message)))
       (format t "The message from ~a was ~a~%" src str)
       (send-string src (concatenate 'string "ACK: " str))))
    (:event-input
     (let* ((inputs (message-value message))
            (move-x-amt (input-amount (find :move-x inputs :key #'input-type)))
            (move-y-amt (input-amount (find :move-y inputs :key #'input-type)))
            (view-x-amt (input-amount (find :view-x inputs :key #'input-type)))
            (view-y-amt (input-amount (find :view-y inputs :key #'input-type))))
            
        (s-input-update src move-x-amt move-y-amt view-x-amt view-y-amt)
       ))))

(defvar *delay-disconnected-clients* nil)
       
(defun handle-disconnect (client)
  (remove-server-controller client)
  ;(remove-player client)
  (push client *delay-disconnected-clients*)
  (decf *client-count*)
  (format t "Client ~a disconnected. (Total: ~a)~%" client *client-count*))
  
(defun new-camera (player-entity)
    (make-server-entity
        'blt3d-gfx:camera
        :pos (make-point3 0.0 0.0 0.0)
        :dir (make-vec3 1.0 0.0 0.0)
        :up  (make-vec3 0.0 1.0 0.0)
        :ideal-coord (list 0.0 (cos (/ pi 2.5)) 7.0)
        :target player-entity
        :shape-name :cylinder
        :mode :third-person))

(defun finalize-server ()
  (socket-disconnect-all))

(defmacro with-finalize-server (() &body body)
  `(unwind-protect
        (progn ,@body)
     (finalize-server)))
     
(defun check-for-new-clients ()
  (forget-server-entity-changes)
         (let ((new-client (check-for-clients)))
           (when new-client
             (new-server-controller new-client)
             (send-all-entities new-client)
             (let ((camera (new-camera (new-player new-client))))
               (message-send :broadcast (make-event :entity-create))
               (message-send new-client (make-event :camera :camera camera)))))
         (forget-server-entity-changes))
     
(defun synchronize-clients ()
  (iter (for (src message) in (message-receive-all :timeout 0))
               (handle-message-server src message))
               
 (message-send :broadcast (make-event :entity-create))
 (message-send :broadcast (make-event :entity-update))
 (message-send :broadcast (make-event :entity-remove)))
     
(defun update-entities ()
  (iter (for thing in (list-entities))
        (update thing)))       
       
(defun combinations (input-list)
  (iter outer (for x on input-list) 
    (iter (for y in (rest x)) 
      (in outer (collect (list (first x) y))))))
       
(defun check-collisions ()

  #+disabled
  (format t "---------------------------------------------------------------~%")
  (iter (for (e1 e2) in (combinations (list-entities)))
      (when (blackthorn3d-physics:collide-p e1 e2)
        (format t "")
        #+disabled
        (format t "~a collides with ~a!~%" e1 e2))
  )
)

(defun remove-disconnected-clients ()
  (iter (for client in *delay-disconnected-clients*)
    (format t "Removing client: ~a~%" client)
    (remove-player client))
  (setf *delay-disconnected-clients* nil))
      
(defun server-main (host port)
  (declare (ignore host))
  
  ;; Start the server, or print a message and quit if we can't use desired port
  (when (not (socket-server-start port))
    (format t "Unable to start the server~%")
    (return-from server-main))
  (socket-disconnect-callback #'handle-disconnect)
  (format t "Server running on port ~a.~%" port)

  (with-finalize-server ()
    (loop
       (next-frame)
       (check-for-new-clients)
       (remove-disconnected-clients)
       (update-entities)
       (check-collisions)
       (synchronize-clients)

       )))
