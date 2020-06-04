## AST

### Meta

`pos` = (index, line, column)

{"file": string, "start": `pos`, "end": `pos`}

<hr>
### Nodes


#### Statements

(:statements, `meta`, [`node`*])

<hr>

#### Number

(:number, `meta`, [*number*])

<hr>

#### Atom

(:atom, `meta`, [*string*])

<hr>

#### List

(:list, `meta`, [`node`*])

<hr>

#### Pattern

(:pattern, `meta`, [`node`, `node`])

<hr>

#### If 

`[comp_node, true_case_node, false_case_node]` 

(:if, `meta`, [`node`, `node`, `node`])

<hr>

#### Var

First element means if the variable is pinned

(:var, `meta`, [True, `node`])

(:var, `meta`, [False, `node`])

<hr>

#### Unary 

(:unary, `meta`, [:minus, `node`])

(:unary, `meta`, [:plus, `node`])

(:unary, `meta`, [:not, `node`])

<hr>

#### BinOp

(:binop, `meta`, [`node`, :plus, `node`])

(:binop, `meta`, [`node`, :minus, `node`])

(:binop, `meta`, [`node`, :mul, `node`])

(:binop, `meta`, [`node`, :div, `node`])

(:binop, `meta`, [`node`, :pow, `node`])

(:binop, `meta`, [`node`, :eq, `node`])

(:binop, `meta`, [`node`, :ne, `node`])

(:binop, `meta`, [`node`, :lt, `node`])

(:binop, `meta`, [`node`, :lte, `node`])

(:binop, `meta`, [`node`, :gt, `node`])

(:binop, `meta`, [`node`, :gte, `node`])

(:binop, `meta`, [`node`, :and, `node`])

(:binop, `meta`, [`node`, :or, `node`])

<hr>

#### Def

`keyarg`  = (:myarg, `node`) 

(:def, `meta`, [[`node*`], [`keyarg*`], `statements`])

<hr>

#### Lambda

(:lambda, `meta`, [[`node*`], `statements`])

<hr>

#### Call

`keyword`= (:keywordname, `node`)

A *local* call

(:call, `meta`, [`node`, [`node*`], [`keyword*`], True])

A *global* call

(:call, `meta`, [`node`, [`node*`], [`keyword*`], False])

<hr>

#### String

(:string, `meta`, [*string*])

<hr>

#### Pipe

(:call, `meta`, [`node`, `node`])

<hr>

#### Map

`key_value` = (`node`, `node`)

(:map, `meta`, [`key_value*`])

<hr>

#### Case

`pair` = (`node`, `node`)

normal *case* expression

(:case, `meta`, [`node`, [`pair*`]])

*cond* expression

(:case, `meta`, [*None*, [`pair*`]])

<hr>

#### Tuple

(:list, `meta`, [`node`*])

<hr>

#### Raise

(:raise, `meta`, [`node`])

<hr>

#### StaticAccess

e.g: ```mymap["mykey"]```

(:static_access, `meta`, [`node`])

<hr>

#### Try

`expect` = `(string, string, statements)`is `(identifier, alias, statements)`

Without *finnaly*

(:try, `meta`, [`statements`, [`expect*`], *None*])

With *finnaly*

(:try, `meta`, [`statements`, [`expect*`], `statements`])

<hr>

#### Func

(:func, `meta`, [*string*, *number*])