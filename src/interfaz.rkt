#lang eopl
;Autores: Juan Eduardo Calderon Jaramillo 2611001

;; Taller 2 — El intérprete de Cauca.
;; El punto de entrada y el REPL. Requiere sintaxis.rkt e interprete.rkt.

(require "sintaxis.rkt")
(require "interprete.rkt")

;; interpretar : string -> valor
;; Analiza el texto de un programa con el parser y evalúa el árbol
;; resultante con evaluar-programa.
(define interpretar
  (lambda (texto)
    (evaluar-programa (parser texto))))

;; interpretador : -> void
;; REPL de Cauca, que se abre con (interpretador). Lee un programa del
;; flujo de entrada con el parser de flujo de SLLGEN, lo evalúa con
;; evaluar-programa e imprime el resultado. sllgen:make-rep-loop retorna
;; un procedimiento sin argumentos que ejecuta el ciclo, por eso va
;; aplicado al final.
(define interpretador
  (lambda ()
    ((sllgen:make-rep-loop
      "cauca> "
      evaluar-programa
      (sllgen:make-stream-parser especificacion-lexica
                                 especificacion-gramatical)))))

(provide (all-defined-out))