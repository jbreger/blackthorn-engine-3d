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

(defclass Player (entity-server)
  ((client
        :accessor player-client
        :initarg :client
        :documentation "The socket symbol for the player's client")))

(defvar *client->player* '())
(defun register-player (p c)
    (setf (getf *client->player* c) p))
(defun remove-player (client)
    ; FIXME: Need to remove player entity as well!
    (remf *client->player* client))
        
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
                          (float (s-input-move-y client))))))
)

(defmethod update ((c blt3d-gfx:camera))
  (let ((client (player-client (blt3d-gfx:target c))))
    (blt3d-gfx:move-player c (vector (s-input-move-x client)
                                     (s-input-move-y client)))
    (blt3d-gfx:update-camera c (/ 1.0 120.0) (vector (s-input-view-x client)
                                                     (s-input-view-y client)))))

   
; simple monster experiment

(defclass alarm (entity-server)
    ((time-left
       :accessor time-left
       :initarg :time-left
       :documentation "How long until alarm is triggered, in seconds.")
     (then
       :accessor then
       :initform (get-internal-real-time))
     (callback
       :accessor callback
       :initarg :callback
       :documentation "Called when alarm goes off.")))
       
(defun kill (object)
    (declare (ignore object))) ;todo: implement object death
       
(defmethod update ((a alarm))
    (let* ((now (get-internal-real-time))
           (elapsed (- now (then a))))
   
        (when (> elapsed 0)
            (setf (then a) now)
            (setf (time-left a) 
              (- (time-left a) (/ elapsed internal-time-units-per-second))))
              
        (when (< (time-left a) 0)
            (if (not (eq (callback a) nil))
              (funcall (callback a)))
            (setf (callback a) nil)
            (kill a))))
       
(defclass cyclic-alarm (entity-server)
    ((alarm
      :accessor alarm
      :initarg :alarm)))
      
(defmacro make-server-only (type &rest options)
  `(make-server-entity ,type 
      ; init w/ bogus values since these fields are not needed for server obj
      :pos (make-point3 0.0 0.0 0.0)  
      :dir (make-vec3 1.0 0.0 0.0)
      :up  (make-vec3 0.0 1.0 0.0)
      ,@options))
      
      
(defun make-cyclic-alarm (period callback)
    (let ((external-alarm (make-server-only 'cyclic-alarm
                             :alarm nil)))
        (labels ((indirect-callback ()
            (setf (alarm external-alarm) (make-server-only 'alarm
                :time-left period
                :callback #'indirect-callback))
            (funcall callback)
            ))
            
            (setf (alarm external-alarm) (make-server-only 'alarm
                :time-left period
                :callback #'indirect-callback)))
            external-alarm))


(defun next-frame ()
  "Reset the state of things to begin processing the next frame"
  (forget-server-entity-changes))

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

(defun handle-disconnect (client)
  (remove-server-controller client)
  (remove-player client)
  (decf *client-count*)
  (format t "Client ~a disconnected. (Total: ~a)~%" client *client-count*))

(defun new-player (client-id)
    (let ((p (make-server-entity
         'Player
         :client client-id
         :pos (make-point3 0.0 0.0 0.0)
         :dir (make-vec3 1.0 0.0 0.0)
         :up  (make-vec3 0.0 1.0 0.0))))
    (register-player p client-id)))
  
(defun new-camera (player-entity)
    (make-server-entity
        'blt3d-gfx:camera
        :pos (make-point3 0.0 0.0 0.0)
        :dir (make-vec3 1.0 0.0 0.0)
        :up  (make-vec3 0.0 1.0 0.0)
        :ideal-coord (list 0.0 (cos (/ pi 2.5)) 7.0)
        :target player-entity
        :mode :third-person))

(defun finalize-server ()
  (socket-disconnect-all))

(defmacro with-finalize-server (() &body body)
  `(unwind-protect
        (progn ,@body)
     (finalize-server)))

(defun hello ()
    (format t "hello~%"))
     
(defun server-main (host port)
  (declare (ignore host))

  (make-cyclic-alarm 2.0 #'hello)
  
  (when (not (socket-server-start port))
    (format t "Unable to start the server~%")
    (return-from server-main))
  (socket-disconnect-callback #'handle-disconnect)
  (format t "Server running on port ~a.~%" port)

  (with-finalize-server ()
    (loop
       (next-frame)
       (iter (for thing in (list-entities))
             (update thing))

       ;; insert network code call here
       (iter (for (src message) in (message-receive-all :timeout 0))
             (handle-message-server src message))
       (message-send :broadcast (make-event :entity-create))
       (message-send :broadcast (make-event :entity-update))
       (message-send :broadcast (make-event :entity-remove))
       
       ;; check for clients to join
       ;; TODO: Check this for errors. It seems very likely to be missing cases...
       ;; Note -- The concurrency constraints make this very tricky to write!
       (forget-server-entity-changes)
       (let ((new-client (check-for-clients)))
         (when new-client
           (new-server-controller new-client)
           (send-all-entities new-client)
           (let ((camera (new-camera (new-player new-client))))
             (message-send :broadcast (make-event :entity-create))
             (message-send new-client (make-event :camera :camera camera)))))

       (sleep 1/120))))
