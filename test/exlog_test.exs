defmodule ExlogTest do
  use ExUnit.Case
  use Exlog

  setup_all do
    e = Exlog.new
    {:ok, %{e: e}}
  end

  test "erlog", %{e: e} do
    {{:succeed, []}, e} = :erlog.prove {:assert,{:father,:homer,:lisa}}, e
    {{:succeed, []}, e} = :erlog.prove {:father,:homer,:lisa}, e
    {{:succeed, [x: res]}, e} = :erlog.prove {:father,:homer,{:x}}, e
    assert res == :lisa
    {:fail,e} = :erlog.next_solution e

    {{:succeed, []}, e} = :erlog.prove {:assert,{:father,:homer,:bart}}, e
    {{:succeed, [x: res]}, e} = :erlog.prove {:father,:homer,{:x}}, e
    assert res == :lisa
    {{:succeed, [x: res]}, e} = :erlog.next_solution e
    assert res == :bart
    {:fail,_e} = :erlog.next_solution e
  end

  test "elixirized", %{e: e} do
    {e,res} = e |> e_prove({:assert,{:father,:homer,:lisa}})
    assert res == {true,[]}
    {e,res} = e |> e_prove_all({:father,:homer,:lisa})
    assert res == [[]]
    {e,res} = e |> e_prove_all({:father,:homer,{:X}})
    assert res == [[X: :lisa]]

    {e,res} = e |> e_prove({:assert,{:father,:homer,:bart}})
    assert res == {true,[]}
    {e,res} = e |> e_prove_all({:father,:homer,{:x}})
    assert res == [[x: :lisa],[x: :bart]]

    {e,res} = e |> e_prove_all({:father,:koothrappali,{:x}})
    assert res == []

    # assertz( father(X) :- father(X,_) )
    {e,_} = e |> e_prove_all({:assertz,{:':-',{:father,{:x}},{:father,{:x},{:_}}}})
    {e,res} = e |> e_prove_all({:father,{:x}})
    assert res == [[x: :homer],[x: :homer]]
    {e,res} = e |> e_prove_all({:father,:homer})
    assert res == [[],[]]

    # empty solutions list -> fail
    {_e,res} = e |> e_prove_all({:father,:bart})
    assert res == []
  end


  test "macroized", %{e: e} do
    e = e |> assert!( father(:homer,:lisa) )
    assert e |> provable?( father(:homer,:lisa) )
    {e,res} = e |> prove_all( father(:homer,X) )
    assert res == [[X: :lisa]]

    e = e |> assertz!( father(X) <- [father(X,_)] )
    assert e |> provable?( father(:homer) )
    {e,res} = e |> prove_all( father(:homer) )
    assert res == [[]]
    {e,res} = e |> prove_all( father(X) )
    assert res == [[X: :homer]]

    refute e |> provable?( father(:bart) )
    {e,res} = e |> prove( father(:bart) )
    assert res == {false,[]}
    {e,res} = e |> prove_all( father(:bart) )
    assert res == []

    # you can use variables
    l = :lisa
    {_e,res} = e |> prove_all( father(:homer,l) )
    assert res == [[]]
  end

  test "clauses", %{e: e} do
    e = e |> assertz!( z(X) <- [a(X),b(X),c(X),d(X)] )
          |> assert!( a(:a) )
          |> assert!( b(:a) )
          |> assert!( c(:a) )

    assert_raise RuntimeError, "Exlog error: {:existence_error, :procedure, {:/, :d, 1}}", fn ->
      e |> provable?( z(:a) )
    end

    e = e |> assert!( d(:a) )
    assert e |> provable?( z(:a) )

    {_e,res} = e |> prove_all( z(X) )
    assert res == [[X: :a]]
  end

  test "strings", %{e: e} do
    {e,res} = e |> prove( assert(father("homer","lisa")) )
    assert res == {true,[]}
    assert e |> provable?( father("homer","lisa") )
    {_e,res} = e |> prove_all( father("homer",X) )
    assert res == [[X: "lisa"]]
  end
end
