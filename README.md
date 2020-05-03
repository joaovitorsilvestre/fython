### ROADMAP

#### BUGS
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
- [ ] Remove dependency of Jason lib
- [ ] Support to multiline if with elif and else
- [ ] Support to tuples
- [ ] Support to pattern match
- [ ] Create the pos_parser. This will be executed after parser to check logic like imports, undefined vars, etc.
- [ ] Support to dict access with dots. Eg `a = {"oi": 2}`, `Map.get(a, "oi") == a.1`
- [ ] `and` and `or` operators must work with multiline

#### GOD TO HAVE
- [ ] support for list 'explode'. Eg: [*[1, 2]] must be converted to [1, 2]. Need do find a way to make this works
- [ ] support for dict 'explode'. Eg: {*{1: 2}} must be converted to {1: 2}. Need do find a way to make this works
- [ ] use python style keyword params to make elixir optional arguments like // ops
- [ ] list comprehentions
- [ ] Support add variable to map without need to refer the string if is the same name. Just like JS ES6
ex: 
```
a = 5
{"a": a} == {a}
```
- [ ] Support to `not in` 

- [x] Create the error visualizer.
