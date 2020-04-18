### Motivation
Eu etou percebendo o quando programação funcional é poderosa
Mas eu estou sempre esbarrando em problems como:
    * syntax bizarra. Yeah. I we just dont follow python way to to this simple and consise?
    
## Elixir
Elixir is functional and at same time is so imprevisible.
It ignores competly 

Take the folowing example of trying to check if variable matchs a pattern match:
```
iex > a = %{}
iex > match?(a, [])
true
```
wait, wat?
The problema is that you must put '^' before the variable to elixir know that is a variable.
The reason for this, in few words, is that assaign a variable in elixir is a ppattern match itself.
So, its ok and we can accept this behaviou? I dont think so.
ref: https://elixirforum.com/t/how-can-you-assert-that-a-map-in-a-variable-matches-another-map-that-is-a-superset/11785/3

Ducktiping is the philosophy of whatever have wings like a duck, ... and quack like a duck, 
its a duck and should behaviour like you wolf expected.

Another example is fo pass functions as parameter:
   ```
... TODO
```

Why you need to inform how many params the function that you are passing have
if you dont need when you are normally calling and elixir finds the one for use?

This time wont tell you the reason because, we should not care, this 'quacks like a bug' 
(or sounds like the developers are laziness or simply dont care)


Want more examples? Hold your self in the chair for this one:
Tuples are not enumerable. Can you belive in this? 
If 

## Fython
Python is slow, but its not stateless. The functions can case side effects. 
Elixir is fast, but its so imprevisible and the syntax and some functions dont work as you wold expect.  

