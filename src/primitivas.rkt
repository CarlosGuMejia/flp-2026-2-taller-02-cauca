#lang eopl
;Autores: Carlos Humberto Gutierrez Mejia 2059817

;; Taller 2 — El intérprete de Cauca.
;; Las primitivas del lenguaje y las verificaciones de tipo y de
;; cantidad de argumentos que cada una exige. Requiere sintaxis.rkt.
;;
;; Aridades: +, -, *, / son n-arias; add1, sub1, not y abs son unarias;
;; las relacionales, and, or, xor e implica son binarias; entre es
;; ternaria; mcd y mcm son n-arias sobre enteros con al menos dos
;; argumentos; promedio es n-aria sobre números con al menos uno.
;;
;; Decisiones: + y * exigen al menos un argumento; - y / exigen al menos
;; dos. La división por cero levanta eopl:error. mcd y mcm solo aceptan
;; enteros exactos (2.0 se rechaza, 2 se acepta).

(require "sintaxis.rkt")

;; exigir-numeros : lista x symbol -> boolean
;; Retorna #t si todos los argumentos son números; si no, levanta
;; eopl:error a nombre de quien hizo la verificación.
(define exigir-numeros
  (lambda (args quien)
    (cond
      [(null? args) #t]
      [(number? (car args)) (exigir-numeros (cdr args) quien)]
      [else (eopl:error quien "Se esperaba un numero, se recibio: ~s"
                        (car args))])))

;; exigir-enteros : lista x symbol -> boolean
;; Retorna #t si todos los argumentos son enteros; si no, levanta error.
(define exigir-enteros
  (lambda (args quien)
    (cond
      [(null? args) #t]
      [(and (integer? (car args)) (exact? (car args)))
       (exigir-enteros (cdr args) quien)]
      [else (eopl:error quien "Se esperaba un entero, se recibio: ~s"
                        (car args))])))

;; exigir-booleanos : lista x symbol -> boolean
;; Retorna #t si todos los argumentos son booleanos; si no, levanta error.
(define exigir-booleanos
  (lambda (args quien)
    (cond
      [(null? args) #t]
      [(boolean? (car args)) (exigir-booleanos (cdr args) quien)]
      [else (eopl:error quien "Se esperaba un booleano, se recibio: ~s"
                        (car args))])))

;; exigir-cantidad : lista x int x symbol -> boolean
;; Retorna #t si llegaron exactamente n argumentos; si no, levanta error.
(define exigir-cantidad
  (lambda (args n quien)
    (if (= (length args) n)
        #t
        (eopl:error quien "Se esperaban ~s argumentos y se recibieron ~s"
                    n (length args)))))

;; exigir-minimo : lista x int x symbol -> boolean
;; Retorna #t si llegaron al menos n argumentos; si no, levanta error.
(define exigir-minimo
  (lambda (args n quien)
    (if (>= (length args) n)
        #t
        (eopl:error quien "Se esperaban al menos ~s argumentos y se recibieron ~s"
                    n (length args)))))

;; ---------------------------------------------------------------
;; Auxiliares aritméticos (no usan gcd, lcm ni abs de Racket)
;; ---------------------------------------------------------------

;; reducir-lista : (a x a -> a) x lista no vacía -> a
;; Pliega la lista de izquierda a derecha con f: (f (f x1 x2) x3)...
(define reducir-lista
  (lambda (f lst)
    (if (null? (cdr lst))
        (car lst)
        (reducir-lista f (cons (f (car lst) (car (cdr lst)))
                               (cdr (cdr lst)))))))

;; division-dos : numero x numero -> numero
;; Divide a entre b; levanta eopl:error si b es cero.
(define division-dos
  (lambda (a b)
    (if (= b 0)
        (eopl:error '/ "Division por cero")
        (/ a b))))

;; valor-absoluto : numero -> numero
;; Retorna |x|.
(define valor-absoluto
  (lambda (x) (if (< x 0) (- x) x)))

;; mcd-dos : entero x entero -> entero
;; Máximo común divisor por el algoritmo de Euclides; siempre >= 0.
(define mcd-dos
  (lambda (a b)
    (if (= b 0)
        (valor-absoluto a)
        (mcd-dos b (remainder a b)))))

;; mcm-dos : entero x entero -> entero
;; Mínimo común múltiplo; es 0 si alguno de los dos es 0.
(define mcm-dos
  (lambda (a b)
    (if (or (= a 0) (= b 0))
        0
        (quotient (valor-absoluto (* a b)) (mcd-dos a b)))))

;; ---------------------------------------------------------------
;; Auxiliares de verificación + aplicación (evitan repetir código)
;; ---------------------------------------------------------------

;; aplicar-unaria-num : lista x symbol x (num -> valor) -> valor
(define aplicar-unaria-num
  (lambda (args quien f)
    (exigir-cantidad args 1 quien)
    (exigir-numeros args quien)
    (f (car args))))

;; aplicar-binaria-num : lista x symbol x (num x num -> valor) -> valor
(define aplicar-binaria-num
  (lambda (args quien f)
    (exigir-cantidad args 2 quien)
    (exigir-numeros args quien)
    (f (car args) (car (cdr args)))))

;; aplicar-unaria-bool : lista x symbol x (bool -> valor) -> valor
(define aplicar-unaria-bool
  (lambda (args quien f)
    (exigir-cantidad args 1 quien)
    (exigir-booleanos args quien)
    (f (car args))))

;; aplicar-binaria-bool : lista x symbol x (bool x bool -> valor) -> valor
(define aplicar-binaria-bool
  (lambda (args quien f)
    (exigir-cantidad args 2 quien)
    (exigir-booleanos args quien)
    (f (car args) (car (cdr args)))))

;; aplicar-nearia-num : lista x symbol x int x (a x a -> a) -> valor
;; n-aria sobre números con al menos 'minimo' argumentos.
(define aplicar-nearia-num
  (lambda (args quien minimo f)
    (exigir-minimo args minimo quien)
    (exigir-numeros args quien)
    (reducir-lista f args)))

;; aplicar-nearia-ent : lista x symbol x (a x a -> a) -> valor
;; n-aria sobre enteros con al menos dos argumentos (mcd y mcm).
(define aplicar-nearia-ent
  (lambda (args quien f)
    (exigir-minimo args 2 quien)
    (exigir-enteros args quien)
    (reducir-lista f args)))

;; evaluar-primitiva : primitiva x lista de valores -> valor
;; Verifica la cantidad y el tipo de los argumentos y aplica la
;; primitiva. Se resuelve con cases sobre el datatype primitiva.
(define evaluar-primitiva
  (lambda (prim args)
    (let ((q (primitiva->simbolo prim)))
      (cases primitiva prim
        ;; aritméticas n-arias
        (sum-prim ()   (aplicar-nearia-num args q 1 +))
        (minus-prim () (aplicar-nearia-num args q 2 -))
        (mult-prim ()  (aplicar-nearia-num args q 1 *))
        (div-prim ()   (aplicar-nearia-num args q 2 division-dos))
        ;; unarias numéricas
        (add-prim ()   (aplicar-unaria-num args q (lambda (x) (+ x 1))))
        (sub-prim ()   (aplicar-unaria-num args q (lambda (x) (- x 1))))
        (abs-prim ()   (aplicar-unaria-num args q valor-absoluto))
        ;; relacionales binarias
        (mayor-prim ()      (aplicar-binaria-num args q (lambda (a b) (> a b))))
        (mayorigual-prim () (aplicar-binaria-num args q (lambda (a b) (>= a b))))
        (menor-prim ()      (aplicar-binaria-num args q (lambda (a b) (< a b))))
        (menorigual-prim () (aplicar-binaria-num args q (lambda (a b) (<= a b))))
        (igual-prim ()      (aplicar-binaria-num args q (lambda (a b) (= a b))))
        ;; lógicas
        (not-prim ()     (aplicar-unaria-bool args q (lambda (a) (not a))))
        (and-prim ()     (aplicar-binaria-bool args q (lambda (a b) (and a b))))
        (or-prim ()      (aplicar-binaria-bool args q (lambda (a b) (or a b))))
        (xor-prim ()     (aplicar-binaria-bool args q
                                               (lambda (a b) (not (eqv? a b)))))
        (implica-prim () (aplicar-binaria-bool args q
                                               (lambda (a b) (or (not a) b))))
        ;; enteros n-arias
        (mcd-prim () (aplicar-nearia-ent args q mcd-dos))
        (mcm-prim () (aplicar-nearia-ent args q mcm-dos))
        ;; promedio: n-aria sobre números, al menos uno
        (promedio-prim ()
          (begin
            (exigir-minimo args 1 q)
            (exigir-numeros args q)
            (/ (reducir-lista + args) (length args))))
        ;; entre(x, a, b): a <= x <= b
        (entre-prim ()
          (begin
            (exigir-cantidad args 3 q)
            (exigir-numeros args q)
            (let ((x (car args))
                  (a (car (cdr args)))
                  (b (car (cdr (cdr args)))))
              (and (<= a x) (<= x b)))))))))

(provide (all-defined-out))