# Fython

Fython is a language build by, and for,  python lovers that are also enthusiastic of functional programing.

<hr>

### Python Functional 

The main reason to build this language is to see how looks like an language that merges the speed of Elixir and the simple and concise syntax of Python. 

Who has already been using python for some time, probably, have already find itself ...

<hr>

#### Syntax design principles



##### Indentation, as in python, is what defines a block. 

If you already will indent you code (we hope so), why bother creating a line that just contains a single `{ ` bracket? 

The use of `do` and `end` to define blocks in elixir suffer from the same problem, and also looks a little childish. Don't take it to bad side, we are talking just about the syntax. It just looks like something you would expect in a coding language build for those that just start programing.

##### Strings can be defined using single and double quotes

Raise your hand who haven't, in Elixer, at least once, lost some time searching for a problem in some code that turn out to only be a single quote (charlist) placed where you meant to have a double quote (string).

```elixir
# in elixir they mean different things
'text' != "text"
```

In Fython, to define a variable you can use both, single and double quotes to define a string, as the main popular languages does.

```elixir
# in fython they are the same thing
'text' == "text"  
```

##### Multi-line anonymous functions matter 

In Fython the lambdas can have multiple lines, even using indentation

```elixir
a = [1, 2, 3]
Enum.map(lambda i:
	a = 3
	i + a
)
```

##### Basic language elements must have a simple syntax

* Lists

Nothing especial about lists. They have the same syntax as python, elixir and the major languages.

```python
list = [1, 2, 3]
```

* Maps 

The visual is just like in python. If you come from elixir, you may pay attention when need to set a variable as a key of the map:

In elixir, to use a variable as a key, you need to pin that variable using a `^`. In Fython you only need put it in the key value, as in python. 

```python
a = "foo"
{a: "bar"}
```

To a key be an Atom it needs to have the `:` before the identifier. At first we're a little concert if it was not cause a problem to the readability of the map, but we realize that a good highlight IDE wold fix the problem easily.

* Tuples

Looks like in python. 

```python
("item_a", 1, 9.0)
```

* Atoms

```elixir
:my_atom
```

##### Functions calls must keeped simple

Differently form Elixir, you don't need to put a dot before every local functions call:

```  python
hi = lambda: :hello

hi() == :hello
    
# in elixir you need to this
hi.()
```

*Today, the syntax of the language is following this rule. But, its not sure if it will possible to keep this working, in the future, due to erlang/elixir limitations.*



#### Unpack and Spread Operators

`*` is called unpack operator while `**` is called spread. They are used to handle lists and maps, respectively.

```python
a = [1, 2, 3]
a = [*a, *a]
# a is now [1,2,3,1,2,3]

a = {"key": 2}

{**a, "key": 3}
# > {"key": 3}

{"key": 3, **a}
# > {"key": 2}

# the last one will overryde any previous key or spread
a = {"a": 2}
c = {"a": 3}
{**a, "a": 4, **c, **a}
# {"a": 2}

```



<hr>

### Roadmap

#### Bugs
- [x] `Critical`- Putting a comma at a end of a list makes the list empty. Need to fix it and ensure that map and tuple dont has same error.
- [ ] If you put pycharm in mode of use tab instead of 4 spaces the compile doesnt work properly. It just cant understand what is a statement anymore, and give a syntax error. Probably the fix is only in the lexer in the part that add the indent key to Token.
- [x] Map are being compiled empty if theres a comma at end of it. E.g: `{"a": 1,}`
- [ ] In the pos parser we need to convert any variable that is a elixir keyword to something else
- [x] Pretty error print is not working when have a comment in a nearby line.
- [ ] Support to `{"a": 2} |> Map.get("a") == 2`. Today we need to put pipe inside parentheses
- [x] List inside lists are not working
- [ ] Don't returning error if we have a file with a string missing end quote: `raise "this string is invalid`
- [x] Use a variable as the match of a case doest seems to work. Eg: 
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
- [x] `(values, [last]) = ...` the left part of this pattern is being evaluated as a empty map. It should be an error.
- [x] Access map value returned by a function (e.g: `advance()['current_char']`) is not working
- [ ] Cant pass a variable as argument if it's form another module: `Elixir.Enum.reduce(0, &Elixir.String.length/1))`. Probably the dot is not treated in conversor.

#### Must have
- [x] Remove dependency of Jason lib
- [x] Stop using PosParser to guess if a call is a local call. It can be a lot easier to just consider
all call local calls, but call of modules like Map.get(...)
- [x] Use real tuples in conversor instead of strings
- [x] Define atoms using strings: `:"oii"`. Must work with single and double quotes.
- [x] Support to range syntax
- [x] Support to try catch
- [x] Support to tuples
- [x] Support to pattern match in variable assign
- [x] Support to pattern match in function arguments
- [x] Create the pos_parser
- [x] convert the locall function calls to support call function without dot
- [x] convert a call function of a callfunction into a local call. Its necessary to support:
```
a = lambda:
    lambda : ""
a()()
```
- [ ] Support to struct
- [ ] PosParser -> Add logic to check imports, undefined vars, etc.
- [x] PosParser -> support for the pin variable in pattern matching: `e = "a""; {^e: 1} = {"a": 1}`
- [x] Support to dict access: ```a["key"]["nesteddict_key""]```
- [x] `and` and `or` operators must work with multiline
- [ ] `<-` Operator in function params must work inside nested pattern. like:
```
# we want to match the third element of this tuple and still get the entire tuple in the var full
def convert((:var, _, full <- [False, value])):
```

#### Good to have
- [x] support for list 'explode'. Eg: [*[1, 2]] must be converted to [1, 2]. Need do find a way to make this works
- [x] support for dict 'explode'. Eg: {\**{"a": 2}} must be converted to {"a": 2}. Need do find a way to make this works
- [ ] use python style keyword params to make elixir optional arguments like // ops
- [ ] list comprehensions
- [ ] dict/map comprehensions
- [ ] Support to `not in` 
- [x] Create the error visualizer.
