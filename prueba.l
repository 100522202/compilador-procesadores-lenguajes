(defun main ()
(setq main_x 0)(setq main_fact 0)
   (setf main_x 5)
   (setf main_fact 1)
   (princ main_x)
   (loop while (> main_x 0) do
   (setf main_x (- main_x 1))
   )
   
   (princ main_fact)
)
