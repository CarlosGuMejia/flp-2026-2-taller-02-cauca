#lang eopl
;Autores: Jesus David Lopez Diaz 2611029-3743

;; Taller 2 — El intérprete de Cauca.
;; Fachada: reúne los seis módulos de src/ y reexporta todo lo que
;; definen, de modo que quien la requiera vea todos los nombres sin
;; requerir los módulos uno por uno.
;;
;;   src/sintaxis.rkt    especificación léxica y gramatical, scanner, parser
;;   src/valores.rkt     el valor procedimiento
;;   src/ambiente.rkt    el TAD ambiente y el ambiente inicial
;;   src/primitivas.rkt  las primitivas y sus verificaciones
;;   src/interprete.rkt  la evaluación y la aplicación de procedimientos
;;   src/interfaz.rkt    el punto de entrada y el REPL
;;
;; Los require van en un solo sentido. Racket no carga dos módulos que se
;; requieran entre sí.

(require "src/sintaxis.rkt")
(require "src/valores.rkt")
(require "src/ambiente.rkt")
(require "src/primitivas.rkt")
(require "src/interprete.rkt")
(require "src/interfaz.rkt")

;; apply-procedure : procval x lista de valores -> valor
;; Verifica que la cantidad de argumentos coincida con la de parámetros
;; y evalúa el cuerpo en el ambiente de la clausura extendido con las
;; ligaduras de los parámetros, no en el ambiente de la llamada.
;; Levanta eopl:error si proc no es un procval o si la aridad no coincide.
;; Esta función no recibe el ambiente de la llamada, así que no puede usarlo.
(define apply-procedure
  (lambda (proc args)
    (if (not (procval? proc))
        (eopl:error 'apply-procedure
                    "No es un procedimiento: ~s" proc)
        (cases procval proc
          (cerradura (ids body env)
            (if (= (length ids) (length args))
                (evaluar-expresion body (ambiente-extendido ids args env))
                (eopl:error 'apply-procedure
                            "Se esperaban ~s argumentos y se recibieron ~s"
                            (length ids) (length args))))))))

;; evaluar-programa : programa -> valor
;; Punto de entrada: evalúa la expresión del programa en el ambiente
;; inicial.
(define evaluar-programa
  (lambda (pgm)
    (cases programa pgm
      (a-program (exp)
        (evaluar-expresion exp (ambiente-inicial))))))

;; evaluar-rands : lista de expresiones x ambiente -> lista de valores
;; Evalúa las expresiones de izquierda a derecha en el mismo ambiente.
;; El let fuerza ese orden: cada valor se calcula antes de seguir con el resto.
(define evaluar-rands
  (lambda (rands env)
    (if (null? rands)
        '()
        (let ((primero (evaluar-expresion (car rands) env)))
          (cons primero (evaluar-rands (cdr rands) env))))))

;; evaluar-expresion : expresion x ambiente -> valor
;; Recorre el árbol de sintaxis abstracta con cases y evalúa cada
;; variante según la semántica del enunciado. El if liga el resultado de
;; la condición a test-value, lo verifica con boolean? y solo entonces
;; ramifica; el case evalúa la expresión de control una sola vez.
(define evaluar-expresion
  (lambda (exp env)
    (cases expresion exp

      ;; literales y variables
      (lit-exp (dato) dato)
      (var-exp (id) (apply-env env id))
      (true-exp () #t)
      (false-exp () #f)

      ;; primitivas: los argumentos se evalúan de izquierda a derecha
      (prim-exp (prim rands)
        (evaluar-primitiva prim (evaluar-rands rands env)))

      ;; condicional: la condición debe ser un booleano
      (if-exp (test true-exp false-exp)
        (let ((test-value (evaluar-expresion test env)))
          (if (boolean? test-value)
              (if test-value
                  (evaluar-expresion true-exp env)
                  (evaluar-expresion false-exp env))
              (eopl:error 'if-exp
                          "La condicion debe ser booleana, se recibio: ~s"
                          test-value))))

      ;; let: los rands se evalúan en el ambiente actual
      (let-exp (ids rands body)
        (let ((vals (evaluar-rands rands env)))
          (evaluar-expresion body (ambiente-extendido ids vals env))))

      ;; proc: NO evalúa el cuerpo; captura el ambiente de la definición
      (proc-exp (ids body)
        (cerradura ids body env))

      ;; apply: el operador debe evaluar a un procedimiento
      (app-exp (rator rands)
        (let ((proc (evaluar-expresion rator env)))
          (if (procval? proc)
              (let ((args (evaluar-rands rands env)))
                (apply-procedure proc args))
              (eopl:error 'app-exp
                          "El operador no es un procedimiento: ~s"
                          proc))))

      ;; letrec: el cuerpo se evalúa en un ambiente-recursivo
      (letrec-exp (proc-names idss bodies body)
        (evaluar-expresion
         body
         (ambiente-recursivo proc-names idss bodies env)))

      ;; case: el control se evalúa UNA sola vez
      (case-exp (control valores acciones default)
        (let ((control-value (evaluar-expresion control env)))
          (if (number? control-value)
              (seleccionar-rama control-value valores acciones default env)
              (eopl:error 'case-exp
                          "El valor de control debe ser numerico, se recibio: ~s"
                          control-value)))))))

;; seleccionar-rama : numero x lista de numeros x lista de expresiones
;;                    x expresion x ambiente -> valor
;; Auxiliar de case-exp. Compara el valor de control con los literales en
;; orden: evalúa la acción de la primera coincidencia, o la rama otherwise
;; si ninguna coincide. Recibe el valor ya evaluado, así que el control
;; nunca se vuelve a evaluar.
(define seleccionar-rama
  (lambda (control-value valores acciones default env)
    (cond
      [(null? valores) (evaluar-expresion default env)]
      [(= control-value (car valores))
       (evaluar-expresion (car acciones) env)]
      [else
       (seleccionar-rama control-value (cdr valores) (cdr acciones)
                         default env)])))

(provide (all-defined-out))
