(import lua/basic (dofile _G))
(import lua/string (sub))
(import io)

(import love/graphics g)
(import love/love (defevent))
(import love/math (random))
(import love/timer (get-time))

(import pty)
(import ansi)
(import term)

(define term (term/make-term 60 25))

(define tty (pty/new))
(with [env (pty/getenviron tty)]
      (.<! env "TERM" "screen")
      (.<! env "COLUMNS" "60")
      (pty/setenviron tty env))
(pty/startproc tty "bash")

(define shader-source ,(io/read-all! "pp.glsl"))

(define shader (g/new-shader shader-source))

(define font (g/new-font "Glass_TTY_VT220.ttf" 10))

(defun random-range (from to)
  (with [diff (- to from)]
        (+ from (* diff (random)))))

(define cv (g/new-canvas 480 320))

(defevent :draw ()
          (g/set-canvas cv)
          (g/set-shader)
          (g/set-color 0 0 0 #x7F)
          (g/rectangle :fill 0 0 480 320)
          (g/set-color 255 255 255 255)
          (g/set-font font)
          (for-pairs (idx line) (term/term-lines term)
                     (when (number? idx)
                       (g/print line 0 (* 10 (pred idx)) 0 1 1)))
          (g/set-canvas)
          (self shader :send :time (get-time))
          (g/set-shader shader)
          (g/draw cv 0 0 0 2 2))
; (with [scr (g/new-screenshot)]
;       (self scr :encode :png (.. "scr" idx ".png"))
;       (over! idx succ)))

(defun chance (dt n)
  (> (* dt n) (random)))

(defevent :update (dt)
          (when (chance dt 10)
            (self shader :send :roffset (list (random-range -0.002 0.002) (random-range -0.002 0.002)))
            (self shader :send :goffset (list (random-range -0.002 0.002) (random-range -0.002 0.002)))
            (self shader :send :boffset (list (random-range -0.002 0.002) (random-range -0.002 0.002))))
          (when (pty/readok tty)
            (do [(msg (ansi/parse (pty/read tty)))]
              ; (when (or (not (list? msg)) (/= (car msg) :text))
              (print! (pretty msg))
              (case msg
                [(:text ?txt) (term/write term txt)]
                [(:set-cursor ?y ?x) (term/set-term-cursor-x! term x)
                                     (term/set-term-cursor-y! term y)]
                [(:set-cursor ?y) (term/set-term-cursor-x! term 1)
                                  (term/set-term-cursor-y! term y)]
                [(:cursor-forward ?n) (term/move-cursor term n 0)]
                [(:cursor-backward ?n) (term/move-cursor term (- n) 0)]
                [(:cursor-up ?n) (term/move-cursor term 0 n)]
                [(:cursor-down ?n) (term/move-cursor term 0 (- n))]
                [:newline (term/set-term-cursor-y! term (succ (term/term-cursor-y term)))
                          (term/set-term-cursor-x! term 1)]
                [:report-cursor-pos (pty/send (.. "\27[" (term/term-cursor-y term) ";" (term/term-cursor-x term) "R"))]
                [_ nil]))))

(defevent :keypressed (key)
          (case key
            [:backspace (pty/send tty "\x08")]
            [:return (pty/send tty "\n")]
            [:tab
              (print! (pretty term))
              (for-pairs (idx line) (term/term-lines term)
                         (when (number? idx)
                           (print! (pretty line))))]
            [:left (pty/send tty "\27[D")]
            [_ nil]))

(defevent :textinput (ch)
          (when (pty/sendok tty)
            (pty/send tty ch)))
