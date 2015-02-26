defmodule Exlog do
  @moduledoc """
  Exlang is a wrapper library for Erlog (https://github.com/rvirding/erlog).
  It defines some convenience functions and macros for writing prolog clauses in
  exilirish style.
  """

  defmacro __using__ _opts do
    quote do
      import Exlog
    end
  end

  #############################################################################
  # API

  def new do
    {:ok,e} = :erlog.new
    e
  end

  # TODO: doesn't work...
  #def new_ets do
  #  {:ok, e} = :erlog.load(:erlog_ets,Exlog.new)
  #  e
  #end

  @doc """
  Determines if clause is provable.

  Note this function returns only true or false. You can't change the engine state with it.

  ## Examples

      iex(1)> use Exlog
      iex(2)> e = Exlog.new
      iex(3)> e = e |> assert!( father(:homer,:lisa) )
      iex(4)> e |> provable?( father(:homer,:lisa) )
      true
      iex(5)> e |> provable?( father(:homer,:ralph) )
      false
  """
  # NOTE: We do not return context here! You can't use assert(...) etc.
  defmacro provable?(e,ex_clause) do
    clause = ex2erlog ex_clause
    quote do
      {_e,{result,_bind}} =  Exlog.e_prove unquote(e), unquote(clause)
      result
    end
  end

  @doc """
  Asserts fact.

  ## Examples

      iex(1)> use Exlog
      iex(2)> e = Exlog.new
      iex(3)> e = e |> assert!( father(:homer,:lisa) )
  """
  defmacro assert!(e,ex_clause) do
    meta_predicate :assert!, e, {:assert, ex2erlog(ex_clause)}
  end

  @doc """
  Inserts clause at the end of the clause database.

  ## Examples

      iex(1)> use Exlog
      iex(2)> e = Exlog.new
      iex(3)> e = e |> assert!( father(:homer,:lisa) )
      iex(4)> e = e |> assertz!( father(X) <- father(X,_) )
      iex(5)> e |> provable?( father(:homer) )
      true
      iex(6)> e |> provable?( father(:ralph) )
      false
      iex(7)> e = e |> assertz!( nice_woman(X) <- [nice(X),woman(X)] )
      iex(8)> e = e |> assert!( nice(:marge) ) |> assert!( woman(:marge) ) |> assert!( nice(:troy) ) |> assert!( woman(:patty) )
      iex(9)> {e,result} = e |> prove_all( nice_woman(X) )
      iex(10)> result
      [[X: :marge]]
  """
  defmacro assertz!(e,ex_clause) do
    meta_predicate :assertz!, e, {:assertz, ex2erlog(ex_clause)}
  end

  defp meta_predicate(pred_name,e,clause) do
    quote do
      case Exlog.e_prove unquote(e), unquote(clause) do
        {e,{true,_}} -> e
        {e,result} ->
          raise "Exlog.#{unquote(pred_name)}(#{inspect unquote(clause)}) failed with #{inspect result}."
      end
    end
  end

  @doc """
  Prove clause.

  ## Examples

      iex(1)> use Exlog
      iex(2)> e = Exlog.new
      iex(3)> e = e |> assert!( father(:homer,:lisa) )
      iex(4)> e = e |> assert!( father(:homer,:bart) )
      iex(5)> {e,result} = e |> prove( father(:homer,:lisa) ); result
      {true, []}
      iex(6)> {e,result} = e |> prove( father(:homer,:ralph) ); result
      {false, []}
      iex(7)> {e,result} = e |> prove( father(:homer,X) ); result
      {true, [X: :lisa]}
      iex(8)> {e,result} = e |> next_solution; result
      {true, [X: :bart]}
      iex(9)> {e,result} = e |> next_solution; result
      {false, []}
  """
  defmacro prove(e,ex_clause) do
    clause = ex2erlog ex_clause
    quote do
      Exlog.e_prove unquote(e), unquote(clause)
    end
  end

  @doc """
  Search for next solution.
  """
  def next_solution(e) do
    case :erlog.next_solution e do
      {{:succeed, bindings}, e} -> {e,{true,bindings}}
      {:fail,e} -> {e,{false,[]}}
      {{:error, err},_e} -> raise "Exlog error: #{inspect err}"
    end
  end

  @doc """
  Prove clause.

  ## Examples

      iex(1)> use Exlog
      iex(2)> e = Exlog.new
      iex(3)> e = e |> assert!( father(:homer,:lisa) )
      iex(4)> e = e |> assert!( father(:homer,:bart) )
      iex(5)> {e,result} = e |> prove_all( father(:homer,X) ); result
      [[X: :lisa], [X: :bart]]
  """
  defmacro prove_all(e,ex_clause) do
    clause = ex2erlog ex_clause
    quote do
      Exlog.e_prove_all unquote(e), unquote(clause)
    end
  end

  #############################################################################
  # IMPLEMENTATION

  # list
  defp ex2erlog(list) when is_list(list) do
    list |> Enum.map(&ex2erlog/1)
  end

  # clause
  # format:  f(a) <- [ g(a), h(b,c) ]       LIST IS MANDATORY HERE!
  defp ex2erlog({:<-, meta, [head,body]}) when is_list(body) do
    body = body
         |> Enum.reverse
         |> Enum.map(&ex2erlog/1)
         |> Enum.reduce(fn x,acc -> {:{}, [], [:',', x, acc]} end)
    {:{}, meta, [:':-',ex2erlog(head),body]}
  end
  defp ex2erlog({:<-, meta, [head,body]}) do
    {:{}, meta, [:':-',ex2erlog(head),ex2erlog(body)]}
  end

  # s.x
  defp ex2erlog(dot_expr={{:., _, [_, _]}, _, _}), do: dot_expr

  # atom
  defp ex2erlog(atom) when is_atom(atom), do: atom

  # number
  defp ex2erlog(num) when is_integer(num) or is_float(num), do: num

  # Prolog variable
  defp ex2erlog({:__aliases__, meta, [atom]}) when is_atom(atom) do
    {:{}, meta, [atom]}
  end
  defp ex2erlog({:_, meta, mod}) when is_atom(mod) do
    {:{}, meta, [:_]}
  end

  # functor
  defp ex2erlog({fun, meta, args}) when is_atom(fun) and is_list(args) and (not (fun in [:<-])) do
    e_args = args |> Enum.map(&ex2erlog/1)
    {:{}, meta, [fun|e_args]}
  end

  # Elixir variable
  defp ex2erlog({atom, meta, mod}) when is_atom(atom) and is_atom(mod) do
    {atom, meta, mod}
  end

  # string
  defp ex2erlog(str) when is_binary(str), do: str

  defp ex2erlog(any) do
    raise "Invalid clause: #{inspect any}"
  end

  @doc false
  def e_prove(e,clause) do
    case :erlog.prove clause, e do
      {{:succeed, bindings}, e} -> {e,{true,bindings}}
      {:fail,e} -> {e,{false,[]}}
      {{:error, err},_e} -> raise "Exlog error: #{inspect err}"
    end
  end

  @doc false
  def e_prove_all(e,clause) do
    case :erlog.prove clause, e do
      {{:succeed, bindings}, e} ->
        e_prove_all2 e, [bindings]
      {:fail,e} -> {e,[]}
      {{:error, err},_e} -> raise "Exlog error: #{inspect err}"
    end
  end

  defp e_prove_all2(e,bindings1) do
    case :erlog.next_solution e do
      {{:succeed, bindings}, e} ->
        e_prove_all2 e, [bindings|bindings1]
      {:fail,e} -> {e,Enum.reverse(bindings1)}
      {{:error, err},_e} -> raise "Exlog error: #{inspect err}"
    end
  end

end
