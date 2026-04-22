# PL – Práctica Final (Markdown limpio)

## Procesadores del Lenguaje  
### Curso 2025-2026  
### Práctica Final – COMPLETA

**Traductor frontend:** subconjunto de lenguaje C a Lisp (código intermedio)  
**Traductor backend:** Lisp a notación postfix (código final)

---

## Trabajo a realizar

1. Leer instrucciones completas
2. Terminar frontend antes de backend
3. Renombrar:
   - trad.y
   - back.y

---

## Entrega

- trad.y
- back.y
- trad.pdf
- listado.pdf
- pruebas.zip

---

## Normas

- Trabajo en pareja
- No copiar ni usar IA sin declararlo
- Penalizaciones si no se cumple

---

## Evaluación

- Diseño: 30%
- Backend: 75%
- Frontend: 25%

⚠️ NO imprimir (main) automáticamente

---

## Flujo

```bash
./trad < test.c > test.l
clisp test.l

./trad < test.c | ./back > test.f
gforth test.f
```

---

## Importante

- No imprimir texto extra
- No debug en stdout
- Usar //@ para código embebido

---

## Traducción C → Lisp

### Variables
```c
int a;
```
```lisp
(setq a 0)
```

### Printf
```c
printf("hola %d", a);
```
```lisp
(princ "hola ")
(princ a)
```

### IF
```lisp
(if cond (progn ...))
```

### WHILE
```lisp
(loop while cond do ...)
```

### FOR
```lisp
(progn
   init
   (loop while cond do
      body
      step))
```

---

## Backend Lisp → Forth

### Variables
```forth
variable a
1 a !
```

### Operaciones
```forth
a @ b @ +
```

### IF
```forth
cond IF ... ELSE ... THEN
```

### WHILE
```forth
BEGIN cond WHILE ... REPEAT
```
