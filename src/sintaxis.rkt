#lang eopl
;Autores: Juan Eduardo Calderon Jaramillo 2611001

;; Taller 2 — El intérprete de Cauca.
;; Especificación léxica, especificación gramatical, scanner y parser.
;; Este módulo no requiere ningún otro.
;;
;; Lo que se escribe aquí:
;;
;;   especificacion-lexica      comentarios que empiezan con //, espacios
;;                              en blanco, números enteros y flotantes con
;;                              signo, e identificadores que empiezan por
;;                              letra y siguen con letras, dígitos, guion
;;                              bajo o signo de interrogación
;;   especificacion-gramatical  las producciones de <programa>,
;;                              <expresion> y <primitiva>, con los nombres
;;                              de constructor que indican los recuadros
;;                              del enunciado (Partes 1 a 4 completas)
;;   scanner : string -> lista de tokens   se construye con
;;                                         sllgen:make-string-scanner
;;   parser  : string -> programa          se construye con
;;                                         sllgen:make-string-parser
;;
;; La llamada a sllgen:make-define-datatypes genera los datatypes
;; programa, expresion y primitiva a partir de la gramática, con sus
;; constructores y sus predicados.
;;
;; Decisiones de léxico:
;;  - Las palabras reservadas (if, then, else, end, let, in, proc, apply,
;;    letrec, case, of, otherwise, true, false y los nombres de las
;;    primitivas) son los strings que aparecen en la gramática. SLLGEN
;;    escoge el token más largo y, a igual longitud, prefiere la palabra
;;    reservada sobre el identificador. Por eso "if" es palabra reservada
;;    pero "ifx" es un identificador.
;;  - El guion abre un número negativo solo si lo sigue un dígito; si no,
;;    es la primitiva "-". Un identificador no puede contener guion:
;;    "aplicar-n" se lee como aplicar, -, n.
;;  - SLLGEN no tiene la clausura {...}+ del enunciado; las ramas de case
;;    se declaran con arbno (cero o más).

;; especificacion-lexica : lista de reglas léxicas de SLLGEN
(define especificacion-lexica
  '((espacio-blanco (whitespace) skip)
    (comentario ("//" (arbno (not #\newline))) skip)
    (identificador (letter (arbno (or letter digit "_" "?"))) symbol)
    ;; enteros positivos y negativos
    (numero (digit (arbno digit)) number)
    (numero ("-" digit (arbno digit)) number)
    ;; flotantes positivos y negativos
    (numero (digit (arbno digit) "." digit (arbno digit)) number)
    (numero ("-" digit (arbno digit) "." digit (arbno digit)) number)))

;; especificacion-gramatical : lista de producciones de SLLGEN
(define especificacion-gramatical
  '((programa (expresion) a-program)

    ;; --- Parte 1: lenguaje base ---
    (expresion (numero) lit-exp)
    (expresion (identificador) var-exp)
    (expresion ("true") true-exp)
    (expresion ("false") false-exp)
    (expresion (primitiva "(" (separated-list expresion ",") ")") prim-exp)
    (expresion ("if" expresion "then" expresion "else" expresion "end") if-exp)
    (expresion ("let" (arbno identificador "=" expresion) "in" expresion "end")
               let-exp)

    ;; --- Parte 3: procedimientos y aplicación ---
    (expresion ("proc" "(" (separated-list identificador ",") ")" expresion "end")
               proc-exp)
    (expresion ("apply" expresion "(" (separated-list expresion ",") ")")
               app-exp)

    ;; --- Parte 4: recursión y selección por valor ---
    (expresion ("letrec"
                (arbno identificador "(" (separated-list identificador ",") ")"
                       "=" expresion)
                "in" expresion "end")
               letrec-exp)
    (expresion ("case" expresion
                (arbno "of" numero "=>" expresion)
                "otherwise" "=>" expresion "end")
               case-exp)

    ;; --- primitivas de la base ---
    (primitiva ("+") sum-prim)
    (primitiva ("-") minus-prim)
    (primitiva ("*") mult-prim)
    (primitiva ("/") div-prim)
    (primitiva ("add1") add-prim)
    (primitiva ("sub1") sub-prim)
    (primitiva (">") mayor-prim)
    (primitiva (">=") mayorigual-prim)
    (primitiva ("<") menor-prim)
    (primitiva ("<=") menorigual-prim)
    (primitiva ("==") igual-prim)
    (primitiva ("not") not-prim)
    (primitiva ("and") and-prim)
    (primitiva ("or") or-prim)

    ;; --- Parte 2: primitivas nuevas ---
    (primitiva ("abs") abs-prim)
    (primitiva ("mcd") mcd-prim)
    (primitiva ("mcm") mcm-prim)
    (primitiva ("promedio") promedio-prim)
    (primitiva ("xor") xor-prim)
    (primitiva ("implica") implica-prim)
    (primitiva ("entre") entre-prim)))

;; Genera programa, expresion y primitiva con sus constructores y predicados.
(sllgen:make-define-datatypes especificacion-lexica especificacion-gramatical)

;; mostrar-datatypes : -> void
;; Lista en pantalla los datatypes que SLLGEN genera a partir de la
;; gramática. Sirve para revisar los nombres de los constructores.
(define mostrar-datatypes
  (lambda ()
    (sllgen:list-define-datatypes especificacion-lexica especificacion-gramatical)))

;; scanner : string -> lista de tokens
;; Convierte el texto de un programa en la lista de sus tokens. Ignora
;; espacios y comentarios; levanta error ante un carácter que no
;; pertenece al léxico.
(define scanner
  (sllgen:make-string-scanner especificacion-lexica especificacion-gramatical))

;; parser : string -> programa
;; Convierte el texto de un programa en su árbol de sintaxis abstracta.
;; Levanta error si el texto no pertenece a la gramática.
(define parser
  (sllgen:make-string-parser especificacion-lexica especificacion-gramatical))

;; primitiva->simbolo : primitiva -> symbol
;; Retorna el nombre del constructor de la primitiva (por ejemplo
;; sum-prim). Sirve para imprimir y comparar árboles en las pruebas.
(define primitiva->simbolo
  (lambda (prim)
    (cases primitiva prim
      (sum-prim () 'sum-prim)
      (minus-prim () 'minus-prim)
      (mult-prim () 'mult-prim)
      (div-prim () 'div-prim)
      (add-prim () 'add-prim)
      (sub-prim () 'sub-prim)
      (mayor-prim () 'mayor-prim)
      (mayorigual-prim () 'mayorigual-prim)
      (menor-prim () 'menor-prim)
      (menorigual-prim () 'menorigual-prim)
      (igual-prim () 'igual-prim)
      (not-prim () 'not-prim)
      (and-prim () 'and-prim)
      (or-prim () 'or-prim)
      (abs-prim () 'abs-prim)
      (mcd-prim () 'mcd-prim)
      (mcm-prim () 'mcm-prim)
      (promedio-prim () 'promedio-prim)
      (xor-prim () 'xor-prim)
      (implica-prim () 'implica-prim)
      (entre-prim () 'entre-prim))))

;; expresion->lista : expresion -> lista
;; Convierte una expresión del AST en una lista de símbolos y datos con
;; el nombre del constructor al frente, comparable con equal?.
;; Los datatypes de SLLGEN no se comparan bien con equal?, por eso las
;; pruebas del parser pasan por esta función.
(define expresion->lista
  (lambda (exp)
    (cases expresion exp
      (lit-exp (dato) (list 'lit-exp dato))
      (var-exp (id) (list 'var-exp id))
      (true-exp () (list 'true-exp))
      (false-exp () (list 'false-exp))
      (prim-exp (prim rands)
                (list 'prim-exp (primitiva->simbolo prim)
                      (map expresion->lista rands)))
      (if-exp (test t f)
              (list 'if-exp (expresion->lista test)
                    (expresion->lista t) (expresion->lista f)))
      (let-exp (ids rands body)
               (list 'let-exp ids (map expresion->lista rands)
                     (expresion->lista body)))
      (proc-exp (ids body)
                (list 'proc-exp ids (expresion->lista body)))
      (app-exp (rator rands)
               (list 'app-exp (expresion->lista rator)
                     (map expresion->lista rands)))
      (letrec-exp (nombres idss cuerpos body)
                  (list 'letrec-exp nombres idss
                        (map expresion->lista cuerpos)
                        (expresion->lista body)))
      (case-exp (control valores acciones default)
                (list 'case-exp (expresion->lista control) valores
                      (map expresion->lista acciones)
                      (expresion->lista default))))))

;; ast->lista : programa -> lista
;; Convierte un programa completo en su representación de lista,
;; (a-program <expresion>), con expresion->lista.
(define ast->lista
  (lambda (pgm)
    (cases programa pgm
      (a-program (exp) (list 'a-program (expresion->lista exp))))))

(provide (all-defined-out))