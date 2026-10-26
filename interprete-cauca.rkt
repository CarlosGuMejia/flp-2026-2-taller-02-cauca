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
  Nota: scanner agrega ademas el marcador de fin de entrada propio de
  SLLGEN. Pegue aqui la salida exacta de su version de Racket.

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

  ---------------- Ejecucion del lenguaje base ----------------
  (interpretar "42")                                   => 42
  (interpretar "n")                                    => 10
  (interpretar "+(1, 2, 3)")                           => 6
  (interpretar "if >(n, m) then n else m end")         => 10
  (interpretar "let x = 2 y = 3 in *(x, y) end")       => 6
  (interpretar "if n then 1 else 2 end")               => error: condicion no booleana
  (interpretar "z")                                    => error: variable no ligada

  ---------------- Primitivas nuevas ----------------
  (interpretar "abs(-7)")                              => 7
  (interpretar "mcd(12, 18)")                          => 6
  (interpretar "mcd(1.5, 2)")                          => error: argumento no entero

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