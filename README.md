# Fython

Fython is a dynamic, functional programming language heavily inspired by Python an Elixir. It was build on top of Elixir and runs on Erlang’s VM.

The language borrow a lot of ideas from Python and apply them in the world of functional programming. 

## Examples of code

### Hello World

```python
def run():
		print('hello world')

> run()
hello world
```

### Fibonacci

```python
def fib(a, _, 0):
    a

def fib(a, b, n):
    fib(b, a + b, n-1)

> fib(10)
55
```

### Reversed list with indexes

```python
def run(my_list):
    my_list
        |> Elixir.Enum.reverse() # we can call Elixir modules inside fython
        |> enumerate()
        |> map(lambda item: print(item))

> run(['foo', 'bar'])
(0, 'foo')
(1, 'bar')
```