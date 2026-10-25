#lang eopl
;Autores: Carlos Humberto Gutierrez Mejia 2059817

;; Taller 2 — El intérprete de Cauca.
;; El TAD ambiente, la búsqueda de ligaduras y el ambiente inicial.
;; Requiere sintaxis.rkt y valores.rkt.
;;
;; Aquí se declara con define-datatype el tipo ambiente, con tres
;; variantes:
;;
;;   ambiente-vacio()
;;   ambiente-extendido(ids, valores, env)
;;     ids      (list-of symbol?)
;;     valores  list?
;;     env      ambiente?
;;   ambiente-recursivo(proc-names, idss, bodies, env)
;;     proc-names  (list-of symbol?)   los nombres declarados en el letrec
;;     idss        list?               la lista de parámetros de cada uno
;;     bodies      (list-of expresion?) los cuerpos, guardados sin evaluar
;;     env         ambiente?
;;
;; La variante recursiva no construye clausuras: las arma apply-env en el
;; momento de la búsqueda, y el ambiente que les entrega es el propio
;; ambiente-recursivo (EOPL, sección 3.4, figura 3.9).

(require "sintaxis.rkt")
(require "valores.rkt")

;; ambiente
;; Contrato: tipo de dato con tres variantes (ambiente-vacio),
;;           (ambiente-extendido ids valores env) y
;;           (ambiente-recursivo proc-names idss bodies env)
;; Propósito: representa una pila de ligaduras. Cada variante apunta al
;; ambiente "de afuera", de modo que la búsqueda recorre de lo más
;; reciente a lo más antiguo.
(define-datatype ambiente ambiente?
  (ambiente-vacio)
  (ambiente-extendido
   (ids (list-of symbol?))
   (valores list?)
   (env ambiente?))
  (ambiente-recursivo
   (proc-names (list-of symbol?))
   (idss list?)
   (bodies (list-of expresion?))
   (env ambiente?)))

;; buscar-extendido : symbol x (list-of symbol) x list x ambiente -> valor
;; Propósito: auxiliar de apply-env para la variante ambiente-extendido.
;; Recorre en paralelo los ids y los valores de UN marco; si encuentra el
;; id retorna su valor, y si lo agota delega la búsqueda al ambiente de
;; afuera (resto).
(define buscar-extendido
  (lambda (id ids vals resto)
    (cond
      [(null? ids) (apply-env resto id)]
      [(eqv? id (car ids)) (car vals)]
      [else (buscar-extendido id (cdr ids) (cdr vals) resto)])))

;; buscar-recursivo : symbol x (list-of symbol) x list x list x ambiente
;;                    x ambiente -> valor
;; Propósito: auxiliar de apply-env para la variante ambiente-recursivo.
;; Recorre en paralelo nombres, parámetros y cuerpos de los procedimientos
;; del letrec. Si id es uno de ellos, ARMA en ese momento la clausura
;; (cerradura params cuerpo amb-rec), donde amb-rec es el propio
;; ambiente-recursivo: así el cuerpo se ve a sí mismo (y a sus hermanos)
;; y hay recursión. Si no está, delega al ambiente de afuera (resto).
(define buscar-recursivo
  (lambda (id nombres idss bodies amb-rec resto)
    (cond
      [(null? nombres) (apply-env resto id)]
      [(eqv? id (car nombres))
       (cerradura (car idss) (car bodies) amb-rec)]
      [else (buscar-recursivo id (cdr nombres) (cdr idss) (cdr bodies)
                              amb-rec resto)])))

;; apply-env : ambiente x symbol -> valor
;; Busca el identificador en el ambiente, respetando el shadowing de las
;; ligaduras más recientes, y levanta eopl:error si no está ligado.
(define apply-env
  (lambda (env id)
    (cases ambiente env
      (ambiente-vacio ()
        (eopl:error 'apply-env "Variable no ligada: ~s" id))
      (ambiente-extendido (ids vals resto)
        (buscar-extendido id ids vals resto))
      (ambiente-recursivo (proc-names idss bodies resto)
        ;; env (el ambiente-recursivo completo) es el que se entrega
        ;; a la clausura recién armada.
        (buscar-recursivo id proc-names idss bodies env resto)))))

;; ambiente-inicial : -> ambiente
;; El ambiente con que arranca todo programa:
;; n = 10, m = 3, p = 7, q = 2, r = 5.
(define ambiente-inicial
  (lambda ()
    (ambiente-extendido '(n m p q r)
                        '(10 3 7 2 5)
                        (ambiente-vacio))))

(provide (all-defined-out))
