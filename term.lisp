(import core/string str)
(import lua/utf8 utf8)
(import data/struct (defstruct))
(import control/setq (over!))
(import scheme (*colors*) :export)

(defun rep (n v) :hidden
  (list->struct (map (lambda () v) (range :from 1 :to n))))

(defstruct term
  (fields (immutable width)
          (immutable height)
          lines
          (mutable cursor-x)
          (mutable cursor-y)
          (mutable current-fg))
  (constructor make (lambda (w h)
                      (with [cells (* w h)]
                            (make w h
                                  {}
                                  1 1
                                  (.> *colors* 7))))))

(defun move-cursor (term xo yo)
  (set-term-cursor-x! term (+ (term-cursor-x term) xo))
  (set-term-cursor-y! term (+ (term-cursor-y term) yo)))

(defun set-char (term x y ch)
  (if (and (<= 1 x (term-width term)) (<= 1 y (term-height term)))
    (over! (.> (term-lines term) y)
           (lambda (line)
             (with [line (or line (str/rep " " (term-width term)))]
                   (.. (str/sub line 1 (pred x)) ch (str/sub line (succ x))))))
    :error))

(defun write-char (term ch)
  (set-char term (term-cursor-x term) (term-cursor-y term) ch)
  (move-cursor term 1 0))

(defun write (term text)
  (do [(ch (str/split text ""))]
    (write-char term ch)))


