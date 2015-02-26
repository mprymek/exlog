defmodule RetractTest do
  use ExUnit.Case
  use Exlog

  setup_all do
    e = Exlog.new
    e = e |> assert!( father(:homer,:lisa) )
    e = e |> assert!( father(:homer,:bart) )
    {:ok, %{e: e}}
  end

  test "retract!", %{e: e} do
    e = e |> retract!( father(X,Y) )
    {_e, res} = e |> prove_all( father(X,Y) )
    assert res == [[X: :homer, Y: :bart]]
  end

  # @TODO: DOES NOT WORK FOR NOW
  #test "retractall!", %{e: e} do
  #  e = e |> retractall!( father(X,Y) )
  #  {_e, res} = e |> prove_all( father(X,Y) )
  #  assert res == []
  #end

  test "abolish!", %{e: e} do
    e = e |> abolish!( father/2 )
    assert_raise RuntimeError, "Exlog error: {:existence_error, :procedure, {:/, :father, 2}}", fn ->
      e |> prove_all( father(X,Y) )
    end
  end
end
