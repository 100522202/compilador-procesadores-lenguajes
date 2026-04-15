(setq a 0)
(setq suma 0)
(defun main ()

   (setf a 1)
   (setf suma 0)
   (loop while (<= a 10) do
   (setf suma (+ suma a))
   (if (= (mod a 2) 0) (progn
   (progn
   (princ "par: ")
   (princ a)
   (print "")
)
   ) (progn
   (progn
   (princ "impar: ")
   (princ a)
   (print "")
)
   ))
   (setf a (+ a 1))
   )
   (progn
   (princ "suma=")
   (princ suma)
   (print "")
)
)
 (main)
