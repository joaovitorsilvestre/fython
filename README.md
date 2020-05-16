### Fython Syntax
<br>

#### Basic elements
| element | syntax   | obs |
|---------|----------|-----|
| string | "mystring" or 'mystring' | Differently from elixir, single quote also creates an string |
| int | 1 | |
| float | 5.0 |
| atom   | :myatom |     |
| list    | [1, 2, 3] |     |
| tuple   | (1, 2, 3) | For a single element tuple, you need to put a comma before the closing parenteses: ```(1,)```    |
| map     | {"a": 2} | Differently from elixir, in fython you must put quotes to have a string key, otherwise the compiler will search for a variable with the given name. If the variable is not found, an error will be raised.    |
| function call | sum(1, 2) | Lambda functions are called in the same way. Unlike elixir, that you need to put a dot in the call: `sum.(1, 2)` |

#### Basic operations
| operation | syntax   | result |
|-----|-----|-----|
| sum | 2 + 2 | 4 |
| subtract | 2 - 2 | 0 |
| multiply | 2 * 2 | 4 |
| multiply no precedence | (1 + 2) * 2 | 6 |
| division | 2 / 2 | 1 |
| division no precedence | (1 + 2) / 2 | 1.5 |
| power | 2 ** 2 | 4 |

#### Function and lambda definition
To define a function the required syntax is just like in python:
```
def sum (a, b):
    a + b
```

#### lambda
Defining a lambda and assign it to the variable sum:

```sum = lambda a, b: a + b```

Unlike python, you can use multiline lambdas. The only thing required to do it is to put all statements in a new line after the `:` token and ident the lines correctly. 
You can also pass the multiline lambda as argument to some function:
```
> list = [1, 2, 3]

> Enum.map(
    list, 
    lambda item:
        power_num = 2
        item ** power_num
)
output: [1, 4, 9]
```

As you have already notice, you dont need to put a `return` keyword at the end of lambdas or functions.
The last statement will automaticly be the return value.

#### Modules
The module name is not defined in the file itself. It will be the file name.
Given this project structure:
```
└── MyProject
    ├── Calcs
        ├── __init__.fy
        ├── utils.fy
```
This will be the modules created: `Calcs` and `Calcs.Utils`

### Grammar rules of the language
```
legend:
    *       0 or more
    +       1 or more
    ()?     optional
    |       or

statements          : NEWLINE* IDENT* statement (NEWLINE+ statement) NEWLINE*

statement           #: import-expr
                    #: KEYWORD:return expr?
                    : KEYWORD:raise expr
                    : expr

# not implemented yet
import-expr         : import IDENTIFIER (COMMA IDENTIFIER (as IDENTIFIER)?)*
                    | from IDENTIFIER import IDENTIFIER (as IDENTIFIER)? 
                      (COMMA IDENTIFIER (as IDENTIFIER)?)*

expr                : IDENTIFIER EQ expr
                    : comp-expr ((KEYWORD:and|KEYWORD:or) comp-expr)*
                    : expr IN expr
                    : if-expr
                    : pipe-expr

comp-expr           : KEYWORD:not comp-expr
                    : arith-expr ((EE|LT|GT|LTE|GTE) arith-expr)*

arith-expr          : term ((PLUS|MINUS) term)*

term                : factor ((MUL|DIV) factor)*

factor              : (PLUS|MINUS) factor
                    : power

power               : call(POW factor)*

call                : call-expr
                    : atom

call-expr           : atom (
                        LPAREN
                        (expr (COMMA expr)*)?
                        (IDENTIFIER DO expr (COMMA IDENTIFIER EQ expr)*)?
                        RPAREN
                    )?

atom                : INT|FLOAT|IDENTIFIER|STRING|ATOM
                    : LPAREN expr RPAREN
                    : tuple-expr
                    : list-expr
                    : map-expr
                    : func-def
                    : lambda-def
                    : case-def
                    : func-as-var-expr

list-expr           : LSQUARE (expr (COMMA expr)*)? RSQUARE

map-expr            : LCURLY ((expr DO expr) (COMMA (expr DO expr))*)? RCURLY

tuple-expr          : LPAREN expr? COMMA (expr COMMA)* RPAREN

if-expr             : expr KEYWORD:if expr DO expr
                    : (KEYWORD:else expr)?

case-def            : KEYWORD:case expr? DO NEWLINE
                    (expr ARROW NEWLINE? statement NEWLINE)+

pipe-expr           : expr (PIPE expr)+

func-def            : KEYWORD:def IDENTIFIER
                    LPAREN (IDENTIFIER (COMMA IDENTIFIER)*)? RPAREN DO
                    (NEWLINE statements)+

lambda-def          : KEYWORD:lambda (IDENTIFIER (COMMA IDENTIFIER)*)?
                    (DO expr)|(NEWLINE statements)+

func-as-var-expr    : ECOM DIV INT
```

### Readmap

#### bugs
- [x] Map are being compiled empty if theres a comma at end of it. E.g: `{"a": 1,}`
- [ ] In the pos parser we need to convert any variable that is a elixir keyword to something else
- [x] Pretty error print is not working when have a comment in a nearby line.
- [ ] Support to `{"a": 2} |> Map.get("a") == 2`. Today we need to put pipe inside parenteses
- [x] List inside lists are not working
- [ ] Dont returning error if we have a file with a string missing end quote: `raise "this string is invalid`
- [ ] Use a variable as the match of a case doest seems to work. Eg: 
```
a = 'RPAREN'
b = 'RPAREN'
case b:
    a -> False   # this is not working
```
- [ ] Some times the error arrow is showing in wrong place. Eg:
```
def add(a)
    a + b
```
- [ ] Lexer must save the value for KEYWORD arguments so we can show they in the expection.
`Expeted ... Received: KEYWORD` should be `Expeted ... Received: lambda`

#### MUST HAVE
- [x] Remove dependency of Jason lib
- [ ] Support to multiline if with elif and else
- [x] Support to tuples
- [ ] Support to pattern match
- [x] Create the pos_parser
- [x] PosParser -> convert the locall function calls to support call function without dot
- [ ] PosParser -> Add logic to check imports, undefined vars, etc.
- [ ] PosParser -> support for the pin variable in pattern matching: `e = "a""; {^e: 1} = {"a": 1}`
- [ ] Support to dict access with dots. Considering `a = {"oi": 2}`, `a.1` must have same effect as `Map.fetch(a, "oi") |> elem(1)`. We must use fetch insted of get to prevent returning None.
- [ ] `and` and `or` operators must work with multiline

#### GOD TO HAVE
- [ ] support for list 'explode'. Eg: [*[1, 2]] must be converted to [1, 2]. Need do find a way to make this works
- [ ] support for dict 'explode'. Eg: {\**{"a": 2}} must be converted to {"a": 2}. Need do find a way to make this works
- [ ] use python style keyword params to make elixir optional arguments like // ops
- [ ] list comprehentions
- [ ] support to put a variable as a key in a map and, if theres no key, the key is the variable name and the value is te variable. It must work just like JS ES6. Eg: 
```
a = 5
{"a": a} == {a}
```
- [ ] Support to `not in` 
- [x] Create the error visualizer.


#### Run in the erlang shell (have some problems :/ )
> cd /usr/lib/elixir/lib/elixir/ebin
> erl -pa /home/joao/fython/src/_compiled/
1> application:start(compiler).
2> application:start(elixir). 
3> 'Elixir.Fshell':start().
