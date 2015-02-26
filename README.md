# Exlog

Elixir bindings and macros for Robert Virding's wonderful "Prolog in Erlang"
(https://github.com/rvirding/erlog)

This is alpha, highly experimental, untested and probably very buggy. Stay tuned.

## example

```elixir
iex(1)> use Exlog
iex(2)> e = Exlog.new
iex(3)> e = e |> assert!( father(:homer,:lisa) )
iex(4)> e = e |> assertz!( father(X) <- father(X,_) )
iex(5)> e |> provable?( father(:homer) )
true
iex(6)> e |> provable?( father(:ralph) )
false
iex(7)> # Note list notation here, it's mandatory.
iex(8)> e = e |> assertz!( nice_woman(X) <- [nice(X),woman(X)] )
iex(9)> e = e |> assert!( nice(:marge) ) |> assert!( woman(:marge) ) 
iex(10)> e = e |> assert!( nice(:troy) ) |> assert!( woman(:patty) )
iex(11)> {e,result} = e |> prove_all( nice_woman(X) )
iex(12)> result
[[X: :marge]]
```

You can even use Elixir variables and dot-accessed items in Exlog clauses:
```elixir
iex(13)> l = :lisa
iex(14)> e |> provable?( father(:homer,l) )
true
iex(15)> s = %{l: :lisa}
iex(16)> e |> provable?( father(:homer,s.l) )
true
```
