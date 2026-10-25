#lang eopl
;Autores: Juan Eduardo Calderon Jaramillo 2611001, Carlos Humberto Gutierrez Mejia 2059817


;; Taller 2 — El intérprete de Cauca.
;; Batería de pruebas con rackunit. Llega escrita en el fork y no se
;; modifica: las pruebas del grupo se agregan después, en suites nuevas
;; que se suman a la cuenta de fallidas del final.
;;
;; Requiere solamente la fachada, nunca un módulo de src/ por separado.
;;
;; Se ejecuta con:  racket pruebas-cauca.rkt

(require rackunit)
(require rackunit/text-ui)
(require (only-in racket/base exn:fail?))
(require "interprete-cauca.rkt")

;; corre : string -> valor
(define corre (lambda (texto) (interpretar texto)))

(define base
  (test-suite
   "Parte 1: interprete base"
   (test-case "literales y variables del ambiente inicial"
              (check-equal? (corre "42") 42)
              (check-equal? (corre "-7") -7)
              (check-equal? (corre "3.5") 3.5)
              (check-equal? (corre "n") 10)
              (check-equal? (corre "r") 5))
   (test-case "booleanos"
              (check-equal? (corre "true") #t)
              (check-equal? (corre "false") #f))
   (test-case "primitivas aritmeticas n-arias"
              (check-equal? (corre "+(1, 2, 3)") 6)
              (check-equal? (corre "-(10, 3, 2)") 5)
              (check-equal? (corre "*(2, 3, 4)") 24)
              (check-equal? (corre "/(100, 5, 2)") 10))
   (test-case "primitivas unarias"
              (check-equal? (corre "add1(n)") 11)
              (check-equal? (corre "sub1(n)") 9)
              (check-equal? (corre "not(true)") #f))
   (test-case "primitivas relacionales"
              (check-equal? (corre ">(n, m)") #t)
              (check-equal? (corre ">=(m, m)") #t)
              (check-equal? (corre "<(q, r)") #t)
              (check-equal? (corre "<=(r, q)") #f)
              (check-equal? (corre "==(n, 10)") #t))
   (test-case "primitivas booleanas binarias"
              (check-equal? (corre "and(true, false)") #f)
              (check-equal? (corre "or(true, false)") #t))
   (test-case "condicional"
              (check-equal? (corre "if >(n, m) then n else m end") 10)
              (check-equal? (corre "if <(n, m) then n else m end") 3))
   (test-case "ligaduras locales"
              (check-equal? (corre "let x = 2 y = 3 in *(x, y) end") 6)
              (check-equal? (corre "let x = 1 in let x = 2 in x end end") 2)
              (check-equal? (corre "let x = 1 in +(x, n) end") 11))
   (test-case "el ejemplo del area del rectangulo"
              (check-equal? (corre "// el area de un rectangulo, con el condicional que valida los lados
let base = 8
    altura = 5
in
  if and(>(base, 0), >(altura, 0))
  then *(base, altura)
  else 0
  end
end") 40))
   (test-case "la condicion del if debe ser booleana"
              (check-exn exn:fail? (lambda () (corre "if n then 1 else 2 end"))))
   (test-case "una variable no ligada es un error"
              (check-exn exn:fail? (lambda () (corre "z"))))
   (test-case "los comentarios se ignoran"
              (check-equal? (corre "// esto no cuenta
7") 7))))

(define primitivas-nuevas
  (test-suite
   "Parte 2: primitivas nuevas"
   (test-case "abs"
              (check-equal? (corre "abs(-7)") 7)
              (check-equal? (corre "abs(7)") 7)
              (check-equal? (corre "abs(-3.5)") 3.5))
   (test-case "mcd"
              (check-equal? (corre "mcd(12, 18)") 6)
              (check-equal? (corre "mcd(7, 13)") 1)
              (check-equal? (corre "mcd(12, 18, 24)") 6))
   (test-case "mcm"
              (check-equal? (corre "mcm(4, 6)") 12)
              (check-equal? (corre "mcm(3, 5)") 15)
              (check-equal? (corre "mcm(2, 3, 4)") 12))
   (test-case "promedio"
              (check-equal? (corre "promedio(1, 2, 3, 4)") 5/2)
              (check-equal? (corre "promedio(10)") 10)
              (check-equal? (corre "promedio(n, m)") 13/2))
   (test-case "xor"
              (check-equal? (corre "xor(true, false)") #t)
              (check-equal? (corre "xor(true, true)") #f)
              (check-equal? (corre "xor(false, false)") #f))
   (test-case "implica"
              (check-equal? (corre "implica(true, false)") #f)
              (check-equal? (corre "implica(false, false)") #t)
              (check-equal? (corre "implica(true, true)") #t))
   (test-case "entre"
              (check-equal? (corre "entre(5, 1, 10)") #t)
              (check-equal? (corre "entre(1, 1, 10)") #t)
              (check-equal? (corre "entre(11, 1, 10)") #f))
   (test-case "las primitivas verifican el tipo de sus argumentos"
              (check-exn exn:fail? (lambda () (corre "mcd(1.5, 2)")))
              (check-exn exn:fail? (lambda () (corre "xor(1, true)")))
              (check-exn exn:fail? (lambda () (corre "abs(true)")))
              (check-exn exn:fail? (lambda () (corre "entre(1, 2)"))))))

(define procedimientos
  (test-suite
   "Parte 3: procedimientos y clausuras"
   (test-case "procedimiento de un parametro"
              (check-equal? (corre "let escalar = proc (v) *(v, 2) end
                                    in apply escalar (21) end") 42))
   (test-case "procedimiento sin parametros"
              (check-equal? (corre "let f = proc () 7 end in apply f () end") 7))
   (test-case "procedimiento de varios parametros"
              (check-equal? (corre "let f = proc (a, b, c) +(a, b, c) end
                                    in apply f (1, 2, 3) end") 6))
   (test-case "un procedimiento recibe otro como argumento"
              (check-equal? (corre "let aplicardos = proc (f, x) apply f (apply f (x)) end
                                        doble = proc (v) *(v, 2) end
                                    in apply aplicardos (doble, 5) end") 20))
   (test-case "un procedimiento retorna otro procedimiento"
              ;; el resultado de una aplicacion se liga antes de volver a
              ;; aplicarlo: <expresion> no puede empezar con parentesis
              (check-equal? (corre "let sumador = proc (a) proc (b) +(a, b) end end
                                    in let suma3 = apply sumador (3)
                                       in apply suma3 (4) end
                                    end") 7))
   (test-case "el cuerpo se evalua en el ambiente de la definicion"
              (check-equal? (corre "let factor = 10
in
  let escalar = proc (v) *(v, factor) end
  in
    let factor = 1000
    in
      apply escalar (5)
    end
  end
end") 50))
   (test-case "aplicar algo que no es procedimiento es un error"
              (check-exn exn:fail? (lambda () (corre "apply 5 (1)"))))
   (test-case "la cantidad de argumentos debe coincidir"
              (check-exn exn:fail?
                         (lambda () (corre "let f = proc (a, b) +(a, b) end
                                            in apply f (1) end"))))))

(define recursion-y-case
  (test-suite
   "Parte 4: recursion y seleccion por valor"
   (test-case "el ejemplo de potencia"
              (check-equal? (corre "letrec
  potencia (base, exp) = if ==(exp, 0)
                         then 1
                         else *(base, apply potencia (base, sub1(exp)))
                         end
in
  apply potencia (2, 10)
end") 1024))
   (test-case "recursion simple"
              (check-equal? (corre "letrec
  factorial (n) = if ==(n, 0) then 1 else *(n, apply factorial (sub1(n))) end
in apply factorial (5) end") 120))
   (test-case "recursion mutua en el mismo letrec"
              (check-equal? (corre "letrec
  par? (n) = if ==(n, 0) then true else apply impar? (sub1(n)) end
  impar? (n) = if ==(n, 0) then false else apply par? (sub1(n)) end
in apply par? (10) end") #t)
              (check-equal? (corre "letrec
  par? (n) = if ==(n, 0) then true else apply impar? (sub1(n)) end
  impar? (n) = if ==(n, 0) then false else apply par? (sub1(n)) end
in apply impar? (7) end") #t))
   (test-case "letrec con un procedimiento pasado como argumento"
              (check-equal? (corre "letrec
  aplicarn (f, x, veces) = if ==(veces, 0)
                           then x
                           else apply f (apply aplicarn (f, x, sub1(veces)))
                           end
in let doble = proc (v) *(v, 2) end
   in apply aplicarn (doble, 1, 5) end
end") 32))
   (test-case "el ejemplo de case"
              (check-equal? (corre "let dia = 3
in
  case dia
    of 1 => 100
    of 3 => 300
    of 7 => 700
    otherwise => 0
  end
end") 300))
   (test-case "case con la rama otherwise activa"
              (check-equal? (corre "let dia = 5
in case dia of 1 => 100 of 3 => 300 otherwise => 0 end end") 0))
   (test-case "case evalua la expresion de control una sola vez"
              (check-equal? (corre "case +(1, 2) of 2 => 20 of 3 => 30 otherwise => 0 end") 30))
   (test-case "el control de case debe ser numero"
              (check-exn exn:fail?
                         (lambda () (corre "case true of 1 => 1 otherwise => 0 end"))))))

;; ==========================================================
;; Pruebas del grupo — scanner, parser y fachada/REPL (Eduardo)
;; ==========================================================

;; ast : string -> lista
;; Parsea el texto y devuelve el AST como lista comparable con equal?.
(define ast (lambda (texto) (ast->lista (parser texto))))

;; tokens-de : string -> int
;; Cantidad de tokens de un texto, sin contar el marcador de fin de
;; entrada que SLLGEN agrega: se resta lo que produce el texto vacio.
(define tokens-de
  (lambda (texto) (- (length (scanner texto)) (length (scanner "")))))

(define scanner-pruebas
  (test-suite
   "Scanner"
   (test-case "numeros enteros y flotantes, positivos y negativos"
              (check-equal? (tokens-de "42") 1)
              (check-equal? (tokens-de "-7") 1)
              (check-equal? (tokens-de "3.5") 1)
              (check-equal? (tokens-de "-2.25") 1)
              (check-equal? (tokens-de "-7  3.5  -2.25") 3))
   (test-case "identificadores con guion bajo, digitos y signo de interrogacion"
              (check-equal? (tokens-de "x") 1)
              (check-equal? (tokens-de "x_1") 1)
              (check-equal? (tokens-de "par?") 1)
              (check-equal? (tokens-de "ifx") 1))
   (test-case "el guion no pertenece a un identificador"
              (check-equal? (tokens-de "aplicar-n") 3)
              (check-equal? (tokens-de "a-1") 2))
   (test-case "primitivas y operadores de varios caracteres"
              (check-equal? (tokens-de ">=") 1)
              (check-equal? (tokens-de "<=") 1)
              (check-equal? (tokens-de "==") 1)
              (check-equal? (tokens-de "=>") 1)
              (check-equal? (tokens-de "add1(n)") 4))
   (test-case "los comentarios y los espacios se descartan"
              (check-equal? (tokens-de "// solo comentario") 0)
              (check-equal? (tokens-de "// comentario\n42") 1)
              (check-equal? (tokens-de "   \n\t  7  ") 1))
   (test-case "una frase completa"
              (check-equal? (tokens-de "let x = 1 in x end") 7)
              (check-equal? (tokens-de "if >=(a, b) then 1 else 2 end") 12))))

(define parser-pruebas
  (test-suite
   "Parser"
   (test-case "literales, variables y booleanos"
              (check-equal? (ast "42") '(a-program (lit-exp 42)))
              (check-equal? (ast "-7") '(a-program (lit-exp -7)))
              (check-equal? (ast "3.5") '(a-program (lit-exp 3.5)))
              (check-equal? (ast "x") '(a-program (var-exp x)))
              (check-equal? (ast "true") '(a-program (true-exp)))
              (check-equal? (ast "false") '(a-program (false-exp))))
   (test-case "primitivas"
              (check-equal? (ast "+(1, x)")
                            '(a-program (prim-exp sum-prim ((lit-exp 1) (var-exp x)))))
              (check-equal? (ast "add1(n)")
                            '(a-program (prim-exp add-prim ((var-exp n)))))
              (check-equal? (ast "-(10, 3, 2)")
                            '(a-program (prim-exp minus-prim
                                                  ((lit-exp 10) (lit-exp 3) (lit-exp 2)))))
              (check-equal? (ast "promedio(1, 2)")
                            '(a-program (prim-exp promedio-prim ((lit-exp 1) (lit-exp 2)))))
              (check-equal? (ast "entre(x, 1, 9)")
                            '(a-program (prim-exp entre-prim
                                                  ((var-exp x) (lit-exp 1) (lit-exp 9))))))
   (test-case "condicional"
              (check-equal? (ast "if true then 1 else 2 end")
                            '(a-program (if-exp (true-exp) (lit-exp 1) (lit-exp 2)))))
   (test-case "let con varias ligaduras y let anidado"
              (check-equal? (ast "let x = 1 y = 2 in x end")
                            '(a-program (let-exp (x y) ((lit-exp 1) (lit-exp 2)) (var-exp x))))
              (check-equal? (ast "let x = 1 in let y = 2 in y end end")
                            '(a-program (let-exp (x) ((lit-exp 1))
                                                 (let-exp (y) ((lit-exp 2)) (var-exp y))))))
   (test-case "proc y apply, con cero y varios argumentos"
              (check-equal? (ast "proc (a, b) a end")
                            '(a-program (proc-exp (a b) (var-exp a))))
              (check-equal? (ast "proc () 7 end")
                            '(a-program (proc-exp () (lit-exp 7))))
              (check-equal? (ast "apply f (1, 2)")
                            '(a-program (app-exp (var-exp f) ((lit-exp 1) (lit-exp 2)))))
              (check-equal? (ast "apply f ()")
                            '(a-program (app-exp (var-exp f) ()))))
   (test-case "letrec con uno y con dos procedimientos"
              (check-equal? (ast "letrec f (x) = x in apply f (1) end")
                            '(a-program (letrec-exp (f) ((x)) ((var-exp x))
                                                    (app-exp (var-exp f) ((lit-exp 1))))))
              (check-equal? (ast "letrec f (x) = x g () = 1 in 0 end")
                            '(a-program (letrec-exp (f g) ((x) ()) ((var-exp x) (lit-exp 1))
                                                    (lit-exp 0)))))
   (test-case "case con varias ramas"
              (check-equal? (ast "case n of 1 => 10 of 2 => 20 otherwise => 0 end")
                            '(a-program (case-exp (var-exp n) (1 2)
                                                  ((lit-exp 10) (lit-exp 20)) (lit-exp 0)))))
   (test-case "el comentario no cambia el arbol"
              (check-equal? (ast "// hola\n42") (ast "42")))
   (test-case "el programa de la Parte 5 se analiza sin error"
              (check-true (programa? (parser "let umbral = promedio(n, m, p)
in
  letrec
    contar (k) = if <=(k, umbral)
                 then apply contar (add1(k))
                 else k
                 end
  in
    case apply contar (1)
      of 7 => abs(-(umbral, 7))
      otherwise => mcd(n, m)
    end
  end
end"))))
   (test-case "las 21 primitivas se reconocen"
              (for-each
               (lambda (texto) (check-true (programa? (parser texto))))
               '("+(1, 2)" "-(1, 2)" "*(1, 2)" "/(1, 2)" "add1(1)" "sub1(1)"
                 ">(1, 2)" ">=(1, 2)" "<(1, 2)" "<=(1, 2)" "==(1, 2)"
                 "not(true)" "and(true, false)" "or(true, false)"
                 "abs(1)" "mcd(1, 2)" "mcm(1, 2)" "promedio(1)"
                 "xor(true, false)" "implica(true, false)" "entre(1, 0, 2)")))
   (test-case "texto fuera de la gramatica es un error"
              (check-exn exn:fail? (lambda () (parser "if true then 1 end")))
              (check-exn exn:fail? (lambda () (parser "+(1, 2")))
              (check-exn exn:fail? (lambda () (parser "let x 1 in x end")))
              (check-exn exn:fail? (lambda () (parser "(1)")))
              (check-exn exn:fail? (lambda () (parser "apply f 1"))))))

(define fachada-y-repl
  (test-suite
   "Fachada e interfaz"
   (test-case "la fachada reexporta las funciones de cada modulo"
              (check-true (procedure? scanner))
              (check-true (procedure? parser))
              (check-true (procedure? interpretar))
              (check-true (procedure? interpretador))
              (check-true (procedure? evaluar-programa))
              (check-true (procedure? evaluar-expresion))
              (check-true (procedure? evaluar-primitiva))
              (check-true (procedure? apply-env))
              (check-true (procedure? apply-procedure))
              (check-true (procedure? ambiente-inicial)))
   (test-case "la fachada reexporta los predicados de los datatypes"
              (check-true (procedure? programa?))
              (check-true (procedure? expresion?))
              (check-true (procedure? primitiva?))
              (check-true (procedure? procval?))
              (check-true (procedure? ambiente?)))
   (test-case "parser produce un programa y interpretar compone parser y evaluar"
              (check-true (programa? (parser "42")))
              (check-equal? (interpretar "42") (evaluar-programa (parser "42")))
              (check-equal? (interpretar "+(n, m)") 13))))

;; Las suites que agregue el grupo se declaran arriba y se suman aquí.

;; ==========================================================
;; Pruebas del grupo — primitivas y ambientes (Carlos)
;; ==========================================================

(define carlos-primitivas-base
  (test-suite
   "Carlos: primitivas base"
   (test-case "aritmeticas n-arias"
              (check-equal? (corre "+(1, 2, 3, 4)") 10)
              (check-equal? (corre "-(20, 5, 5)") 10)
              (check-equal? (corre "*(1.5, 2)") 3.0)
              (check-equal? (corre "/(7, 2)") 7/2))
   (test-case "unarias"
              (check-equal? (corre "add1(-1)") 0)
              (check-equal? (corre "sub1(0)") -1))
   (test-case "relacionales"
              (check-equal? (corre ">(3, 3)") #f)
              (check-equal? (corre "<=(3, 3)") #t)
              (check-equal? (corre "==(2, 3)") #f))
   (test-case "logicas"
              (check-equal? (corre "not(false)") #t)
              (check-equal? (corre "or(false, false)") #f)
              (check-equal? (corre "and(true, true)") #t))
   (test-case "errores de las primitivas base"
              (check-exn exn:fail? (lambda () (corre "+(1, true)")))
              (check-exn exn:fail? (lambda () (corre "/(5, 0)")))
              (check-exn exn:fail? (lambda () (corre "add1(1, 2)")))
              (check-exn exn:fail? (lambda () (corre "not(1)")))
              (check-exn exn:fail? (lambda () (corre ">(1)"))))))

(define carlos-primitivas-nuevas
  (test-suite
   "Carlos: primitivas nuevas"
   (test-case "abs"
              (check-equal? (corre "abs(-10)") 10)
              (check-equal? (corre "abs(0)") 0)
              (check-equal? (corre "abs(-2.5)") 2.5)
              (check-exn exn:fail? (lambda () (corre "abs(1, 2)"))))
   (test-case "mcd"
              (check-equal? (corre "mcd(48, 18)") 6)
              (check-equal? (corre "mcd(-12, 18)") 6)
              (check-equal? (corre "mcd(0, 5)") 5)
              (check-exn exn:fail? (lambda () (corre "mcd(6)")))
              (check-exn exn:fail? (lambda () (corre "mcd(4, true)"))))
   (test-case "mcm"
              (check-equal? (corre "mcm(6, 8)") 24)
              (check-equal? (corre "mcm(0, 5)") 0)
              (check-equal? (corre "mcm(4, 6, 10)") 60)
              (check-exn exn:fail? (lambda () (corre "mcm(1.5, 2)"))))
   (test-case "promedio"
              (check-equal? (corre "promedio(2, 4)") 3)
              (check-equal? (corre "promedio(1, 2)") 3/2)
              (check-equal? (corre "promedio(1.5, 2.5)") 2.0)
              (check-equal? (corre "promedio(5)") 5)
              (check-exn exn:fail? (lambda () (corre "promedio()")))
              (check-exn exn:fail? (lambda () (corre "promedio(true)"))))
   (test-case "xor"
              (check-equal? (corre "xor(false, true)") #t)
              (check-equal? (corre "xor(and(true, true), false)") #t)
              (check-equal? (corre "xor(false, false)") #f)
              (check-exn exn:fail? (lambda () (corre "xor(true)"))))
   (test-case "implica"
              (check-equal? (corre "implica(false, true)") #t)
              (check-equal? (corre "implica(true, false)") #f)
              (check-equal? (corre "implica(or(false, true), false)") #f)
              (check-exn exn:fail? (lambda () (corre "implica(1, true)"))))
   (test-case "entre"
              (check-equal? (corre "entre(5, 5, 5)") #t)
              (check-equal? (corre "entre(0, 1, 10)") #f)
              (check-equal? (corre "entre(2.5, 2, 3)") #t)
              (check-exn exn:fail? (lambda () (corre "entre(true, 1, 2)")))
              (check-exn exn:fail? (lambda () (corre "entre(1, 2, 3, 4)"))))))

(define carlos-ambientes
  (test-suite
   "Carlos: ambientes y shadowing"
   (test-case "apply-env directo"
              (check-equal? (apply-env (ambiente-inicial) 'n) 10)
              (check-equal? (apply-env (ambiente-extendido '(a b) '(1 2)
                                                           (ambiente-vacio))
                                       'b)
                            2)
              (check-exn exn:fail? (lambda () (apply-env (ambiente-vacio) 'x))))
   (test-case "shadowing"
              (check-equal? (corre "let n = 99 in n end") 99)
              (check-equal? (corre "let n = 99 in m end") 3)
              (check-equal? (corre "let x = 1 in let x = 2 in let y = x in y end end end") 2))
   (test-case "variable no ligada"
              (check-exn exn:fail? (lambda () (corre "w")))
              (check-exn exn:fail? (lambda () (corre "let a = 1 in b end"))))
   (test-case "ambiente-recursivo"
              (check-equal? (corre "letrec f (a) = a in apply f (7) end") 7)
              (check-equal? (corre "letrec f (a) = +(a, n) in apply f (1) end") 11))))


(define fallidas
  (+ (run-tests base)
     (run-tests primitivas-nuevas)
     (run-tests procedimientos)
     (run-tests recursion-y-case)
     (run-tests scanner-pruebas)
     (run-tests parser-pruebas)
     (run-tests fachada-y-repl)
     (run-tests carlos-primitivas-base)
     (run-tests carlos-primitivas-nuevas)
     (run-tests carlos-ambientes)))

(eopl:printf "~%==========================================~%")
(eopl:printf "  pruebas fallidas en total: ~s~%" fallidas)
(eopl:printf "==========================================~%")