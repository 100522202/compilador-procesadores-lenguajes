# Compilador / Intérprete - Procesadores de Lenguajes (PL)

Repositorio correspondiente a la **Práctica Final de Procesadores de Lenguajes (Universidad Carlos III de Madrid - UC3M)**.

---

## Descripción del Proyecto

Diseño e implementación de un compilador/intérprete en **C** haciendo uso de las herramientas de generación automática de analizadores **Flex (Lex)** y **Bison (Yacc)**.

El sistema realiza:
1. **Análisis Léxico:** Reconocimiento de tokens, palabras reservadas, identificadores y literales mediante expresiones regulares.
2. **Análisis Sintáctico y Semántico:** Validación de la gramática libre de contexto, gestión de precedencia de operadores y construcción del árbol sintáctico.
3. **Tabla de Símbolos:** Gestión de identificadores, ámbitos y comprobación de tipos.
4. **Evaluación / Generación de Código:** Procesamiento y ejecución del código fuente de entrada.

---

## Tecnologías Utilizadas

* **Lenguaje:** C (estándar C11/GNU11).
* **Herramientas de Análisis:** Flex (analizador léxico) y Bison (analizador sintáctico).
* **Compilación:** `gcc` y `make`.

---

## Compilación y Ejecución

```bash
# Compilar el proyecto
make

# Ejecutar pasando un fichero de prueba
./compilador < prueba.txt

# Limpiar archivos generados
make clean
```
