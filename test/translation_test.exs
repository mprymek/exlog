defmodule TranslationTest do
  use ExUnit.Case

  defdelegate [ex2erlog(clause)], to: Exlog

  @tag :translation

  test "all" do
    assert ex2erlog(quote do [:a,:b,:c] end ) |> Code.eval_quoted == { {:',',:a,{:',',:b,:c}}, []}

    assert ex2erlog(quote do [h(:a,:b),i(:c,:d),j(:e,:f)] end ) |> Code.eval_quoted ==
      {{:",", {:h, :a, :b}, {:",", {:i, :c, :d}, {:j, :e, :f}}}, []}

    assert ex2erlog(quote do f(X) end ) |> Code.eval_quoted == { {:f,{:X}}, []}

    assert ex2erlog(quote do f(:a,:b) end) |> Code.eval_quoted == { {:f,:a,:b}, []}

    assert ex2erlog( quote do f(:a,:b) <- g(:a,:b) end) |> Code.eval_quoted ==
      { {:':-',{:f,:a,:b},{:g,:a,:b}}, []}

    assert ex2erlog(quote do f(g(:a),:b) end) |> Code.eval_quoted ==
      { {:f,{:g,:a},:b}, []}

    assert ex2erlog(quote do f( g(:a) <- h(:b) )end) |> Code.eval_quoted ==
      { {:f,{:':-',{:g,:a},{:h,:b}}}, []}

    assert ex2erlog(quote do g(:a,:b) <- [h(:b,:c), i(:d,:e), j(:x,:y)] end) |> Code.eval_quoted ==
      { {:":-", {:g, :a, :b}, {:",", {:h, :b, :c}, {:",", {:i, :d, :e}, {:j, :x, :y}}}}, []}
  end
end
