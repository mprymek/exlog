defmodule TranslationTest do
  use ExUnit.Case

  defdelegate [ex2erlog(clause)], to: Exlog

  @tag :translation

  test "all" do
    # atom
    assert ex2erlog(quote do :a end ) |> Code.eval_quoted == { :a, []}

    # integer
    assert ex2erlog(quote do 1 end ) |> Code.eval_quoted == { 1, []}

    # float
    assert ex2erlog(quote do 1.2 end ) |> Code.eval_quoted == { 1.2, []}

    # list
    assert ex2erlog(quote do [:a,:b,:c] end ) |> Code.eval_quoted == { [:a,:b,:c], []}

    # functor with prolog variable
    assert ex2erlog(quote do f(X) end ) |> Code.eval_quoted == { {:f,{:X}}, []}

    # functor with atoms
    assert ex2erlog(quote do f(:a,:b) end) |> Code.eval_quoted == { {:f,:a,:b}, []}

    # nested functors
    assert ex2erlog(quote do f(g(:a),:b) end) |> Code.eval_quoted ==
      { {:f,{:g,:a},:b}, []}

    # functor with nested clause (used in assertz etc.)
    assert ex2erlog(quote do f( g(:a) <- h(:b) )end) |> Code.eval_quoted ==
      { {:f,{:':-',{:g,:a},{:h,:b}}}, []}

    # clause with singular body
    assert ex2erlog( quote do f(:a,:b) <- g(:a,:b) end) |> Code.eval_quoted ==
      { {:':-',{:f,:a,:b},{:g,:a,:b}}, []}

    # clause with compound body
    assert ex2erlog(quote do g(:a,:b) <- [h(:b,:c), i(:d,:e), j(:x,:y)] end) |> Code.eval_quoted ==
      { {:":-", {:g, :a, :b}, {:",", {:h, :b, :c}, {:",", {:i, :d, :e}, {:j, :x, :y}}}}, []}
  end
end
