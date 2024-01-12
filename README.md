# kaleidoscope

Progetto di compilatori, sviluppo della grammatica per il linguaggio di programmazione **kaleidoscope**.

## Makefile

Per far compilare il progetto e creare il file `kcomp` con cui compilare i file di kaleidoscope si utilizza il comando

```shell
make
make all
```

Per far copilare un programma, linkarlo con il suo corrispettivo _caller_,  si utilizza lo script `compile`

## Grammatica di secondo livello

```
stmt :
assignment
| block
| ifstmt
| forstmt
| exp

ifstmt :
"if" "(" condexp ")" stmt
| "if" "(" condexp ")" stmt " else " stmt

forstmt:
" for " "(" init ";" condexp ";" assignment ")" stmt

init :
binding
| assignment

```