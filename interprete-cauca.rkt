#lang eopl
;Autores: Juan Eduardo Calderon Jaramillo 2611001-3743,Jesus David Lopez Diaz 2611029-3743, Carlos Humberto Gutierrez Mejia 2059817-3743

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

(provide (all-from-out "src/sintaxis.rkt"
                       "src/valores.rkt"
                       "src/ambiente.rkt"
                       "src/primitivas.rkt"
                       "src/interprete.rkt"
                       "src/interfaz.rkt"))

;;; ==========================================================
;;; Ejemplos
;;; ==========================================================

#|
  Las pruebas con rackunit viven en pruebas-cauca.rkt.
  Cada tokens/AST se obtiene con la fachada: (require "interprete-cauca.rkt").
  ast->lista convierte el AST en una lista legible (viene de sintaxis.rkt).

  ---------------- Scanner (5) ----------------
  (scanner "add1(n)")
    => 4 tokens de programa: add1, "(", identificador n, ")"
  (scanner "-7  3.5  -2.25")
    => 3 tokens numero: -7, 3.5, -2.25 (el guion pegado a un digito
       forma parte del numero)
  (scanner "// un comentario\n42")
    => 1 token numero: 42 (el comentario y los espacios se descartan)
  (scanner "let x = 1 in x end")
    => 7 tokens: let, x, "=", 1, in, x, end
  (scanner "aplicar-n")
    => 3 tokens: identificador aplicar, "-", identificador n
       (un identificador no puede llevar guion)
  Los conteos de tokens no incluyen el marcador de fin de entrada, si
  SLLGEN lo agrega.

  ---------------- Parser (5) ----------------
  (ast->lista (parser "42"))
    => (a-program (lit-exp 42))
  (ast->lista (parser "+(1, x)"))
    => (a-program (prim-exp sum-prim ((lit-exp 1) (var-exp x))))
  (ast->lista (parser "if true then 1 else 2 end"))
    => (a-program (if-exp (true-exp) (lit-exp 1) (lit-exp 2)))
  (ast->lista (parser "let x = 1 y = 2 in x end"))
    => (a-program (let-exp (x y) ((lit-exp 1) (lit-exp 2)) (var-exp x)))
  (ast->lista (parser "case n of 1 => 10 otherwise => 0 end"))
    => (a-program (case-exp (var-exp n) (1) ((lit-exp 10)) (lit-exp 0)))

  Otros arboles utiles para el informe:
  (ast->lista (parser "proc (a, b) a end"))
    => (a-program (proc-exp (a b) (var-exp a)))
  (ast->lista (parser "apply f (1)"))
    => (a-program (app-exp (var-exp f) ((lit-exp 1))))
  (ast->lista (parser "letrec f (x) = x in apply f (1) end"))
    => (a-program (letrec-exp (f) ((x)) ((var-exp x))
                              (app-exp (var-exp f) ((lit-exp 1)))))

  ---------------- Ejecucion del lenguaje base (18) ----------------
  Literales, variables y booleanos
  (interpretar "42")                                   => 42
  (interpretar "-7")                                   => -7
  (interpretar "3.5")                                  => 3.5
  (interpretar "n")                                    => 10
  (interpretar "true")                                 => #t
  (interpretar "false")                                => #f
  Primitivas aritmeticas n-arias
  (interpretar "+(1, 2, 3)")                           => 6
  (interpretar "-(10, 3, 2)")                          => 5
  (interpretar "*(2, 3, 4)")                           => 24
  (interpretar "/(100, 5, 2)")                         => 10
  Primitivas unarias
  (interpretar "add1(n)")                              => 11
  (interpretar "sub1(n)")                              => 9
  (interpretar "not(true)")                            => #f
  Primitivas relacionales
  (interpretar ">(n, m)")                              => #t
  (interpretar ">=(m, m)")                             => #t
  (interpretar "<(q, r)")                              => #t
  (interpretar "<=(r, q)")                             => #f
  (interpretar "==(n, 10)")                            => #t
  Primitivas logicas
  (interpretar "and(true, false)")                     => #f
  (interpretar "or(true, false)")                      => #t
  Condicional y ligaduras locales
  (interpretar "if >(n, m) then n else m end")         => 10
  (interpretar "let x = 2 y = 3 in *(x, y) end")       => 6
  (interpretar "let x = 1 in let x = 2 in x end end")  => 2   (shadowing)
  (interpretar "let x = 1 in +(x, n) end")             => 11  (ambiente inicial)
  El ejemplo del area del rectangulo (enunciado)       => 40
  Casos de error
  (interpretar "if n then 1 else 2 end")               => error: la condicion debe ser booleana
  (interpretar "z")                                    => error: variable no ligada
  (interpretar "+(1, true)")                           => error: se esperaba un numero
  (interpretar "/(1, 0)")                              => error: division por cero

  ---------------- Primitivas nuevas ----------------
  (interpretar "abs(-7)")                  => 7
  (interpretar "abs(0)")                   => 0
  (interpretar "abs(-2.5)")                => 2.5
  (interpretar "abs(true)")                => error: se esperaba un numero
  (interpretar "mcd(12, 18)")              => 6
  (interpretar "mcd(7, 13)")               => 1
  (interpretar "mcd(12, 18, 24)")          => 6
  (interpretar "mcd(1.5, 2)")              => error: se esperaba un entero
  (interpretar "mcm(4, 6)")                => 12
  (interpretar "mcm(3, 5)")                => 15
  (interpretar "mcm(2, 3, 4)")             => 12
  (interpretar "mcm(1.5, 2)")              => error: se esperaba un entero
  (interpretar "promedio(1, 2, 3, 4)")     => 5/2
  (interpretar "promedio(10)")             => 10
  (interpretar "promedio(n, m)")           => 13/2
  (interpretar "promedio(true)")           => error: se esperaba un numero
  (interpretar "xor(true, false)")         => #t
  (interpretar "xor(true, true)")          => #f
  (interpretar "xor(false, false)")        => #f
  (interpretar "xor(1, true)")             => error: se esperaba un booleano
  (interpretar "implica(true, false)")     => #f
  (interpretar "implica(false, false)")    => #t
  (interpretar "implica(true, true)")      => #t
  (interpretar "implica(1, true)")         => error: se esperaba un booleano
  (interpretar "entre(5, 1, 10)")          => #t
  (interpretar "entre(1, 1, 10)")          => #t
  (interpretar "entre(11, 1, 10)")         => #f
  (interpretar "entre(1, 2)")              => error: cantidad de argumentos

  ---------------- Procedimientos ----------------
  (interpretar "let f = proc () 7 end in apply f () end")   => 7
  (interpretar "apply 5 (1)")                          => error: no es procedimiento

  ---------------- Recursion y case ----------------
  (interpretar "letrec potencia (base, exp) = if ==(exp, 0) then 1
                else *(base, apply potencia (base, sub1(exp))) end
                in apply potencia (2, 10) end")        => 1024
  (interpretar "case +(1, 2) of 2 => 20 of 3 => 30 otherwise => 0 end")
                                                       => 30
|#