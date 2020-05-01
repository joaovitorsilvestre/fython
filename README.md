### ROADMAP

#### BUGS
- [ ] Support to `{"a": 2} |> Map.get("a") == 2`. Today we need to put pipe inside parenteses
- [x] List inside lists are not working

#### MUST HAVE
- [ ] Support to multiline if with elif and else
- [ ] Create the pos_parser. This will be executed after parser to check logic like imports, undefined vars, etc.
- [ ] Support to dict access with dots. Eg `a = {"oi": 2}`, `Map.get(a, "oi") == a.1`

#### GOD TO HAVE
- [ ] support for list 'explode'. Eg: [*[1, 2]] must be converted to [1, 2]. Need do find a way to make this works
- [ ] support for dict 'explode'. Eg: {*{1: 2}} must be converted to {1: 2}. Need do find a way to make this works

- [ ] Support add variable to map without need to refer the string if is the same name. Just like JS ES6
ex: 
```
a = 5
{"a": a} == {a}
```
- [ ] Support to `not in` 

- [x] Create the error visualizer.
