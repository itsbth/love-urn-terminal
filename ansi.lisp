(import core/string str)
(import lua/utf8 utf8)

(defun matcher (pattern)
  (lambda (wh)
    (case (list (str/find wh pattern))
      [(?f ?t . ?matches) (list (str/sub wh (succ t)) matches)]
      [(nil) nil])))

(define utf8-sequence (format nil "^({#utf8/charpattern})+"))

; [((matcher "^\27%[([\48-\63]*)([\32-\47]*)([\64-\125])") -> ?csi) (print! (pretty csi)) (recur (nth csi 1) commands)]
; [((matcher utf8-sequence) -> ?seq) (print! (pretty seq)) (recur (nth seq 1) commands)])

(defun numeric? (n)
  (/= (tonumber n) nil))

(defun parse-params (params default)
  (map (compose (cut or <> default) tonumber) (str/split params ";")))

(defun handle-sgi (param inter)
  (loop [(params (parse-params param 0)) (cmds (list))]
        [(empty? params) cmds]
        (print! param inter (pretty params))
        (case params
          [(nil) (print! "nil when handling sgi, bug?") (recur '() cmds)]
          [(0 . ?rest) (recur rest (append cmds '(:reset)))]
          [(1 . ?rest) (recur rest (append cmds '(:bold)))]
          [(7 . ?rest) (recur rest (append cmds '(:reverse)))]
          [(23 . ?rest) (recur rest cmds)] ; disable italic, disable fraktur
          [(24 . ?rest) (recur rest cmds)] ; disable underline
          [(27 . ?rest) (recur rest cmds)] ; disable inverse
          [(38 2 ?r ?g ?b . ?rest) (recur rest (append cmds (list (list :setfg24 r g b))))]
          [(48 2 ?r ?g ?b . ?rest) (recur rest (append cmds (list (list :setbg24 r g b))))]
          [(39 . ?rest) (recur rest (append cmds '(:defaultfg)))]
          [(49 . ?rest) (recur rest (append cmds '(:defaultbg)))]
          [((?n . ?rest) :when (<= 30 n 37)) (recur rest (append cmds (list (list :setfg (- n 29)))))])))

(defun dispatch-csi (cmd param inter)
  (case cmd
    [:m (handle-sgi param inter)]
    [:H (list (append '(:set-cursor) (parse-params param 1)))]
    [:A (list (append '(:cursor-up) (parse-params param 1)))]
    [:B (list (append '(:cursor-down) (parse-params param 1)))]
    [:C (list (append '(:cursor-forward) (parse-params param 1)))]
    [:D (list (append '(:cursor-back) (parse-params param 1)))]
    [:J (list (list :erase-in-screen param))]
    [:K (list (list :erase-in-line param))]
    [:n (list '(:report-cursor-pos))]
    [:h '()] ; what is this?
    [:r '()] ; what is this?
    [:l '()])) ; what is this?

(defun handle-csi (text)
  (destructuring-bind [(_ ?end ?param ?inter ?cmd) (list (str/find text "^([\48-\63]*)([\32-\47]*)([\64-\125])"))]
    (list (str/sub text (succ end)) (dispatch-csi cmd param inter))))

(defun handle-osc (text)
  (destructuring-bind [(_ ?end ?param) (list (str/find text "^(.*)[\7\156]"))]
    (list (str/sub text (succ end)) (list (list :osc :meh)))))

(defun handle-text (text)
  (if-with [end (second (str/find text "^[^\27\n]+"))]
           (list (str/sub text (succ end)) (list (list :text (str/sub text 1 end))))
           (error! "handle-text error")))

(defun parse (text)
  (loop [(text text) (commands (list))]
        [(= 0 (str/len text)) commands]
        (case (str/split (str/sub text 1 2) "")
          [("\27" "[") (with [res (handle-csi (str/sub text 3))]
                             (recur (nth res 1) (append commands (nth res 2))))]
          [("\27" "]") (with [res (handle-osc (str/sub text 3))]
                             (recur (nth res 1) (append commands (nth res 2))))]
          [("\27" ?u) (recur (str/sub text 2) commands)]
          [("\n" ?_) (recur (str/sub text 2) (append commands '(:newline)))]
          [("\n") (recur (str/sub text 2) (append commands '(:newline)))]
          [_ (with [res (handle-text text)]
                   (recur (nth res 1) (append commands (nth res 2))))])))

