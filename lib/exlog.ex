defmodule Exlog do
  @moduledoc """
  Exlog is an Elixir wrapper for Erlog (https://github.com/rvirding/erlog).

  It defines some convenience functions and macros for embedding Prolog in Elixir
  in a more natural way.
  """

  defmacro __using__ _opts do
    quote do
      import Exlog
    end
  end

  #############################################################################
  # API

  @doc """
  Create a new Prolog context.
  """
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
  Determine if clause is provable.

  Note this function returns only true or false. You can't change the engine state with it.

  ## Example

      iex> use Exlog
      nil
      iex> e = Exlog.new; nil
      nil
      iex> e = e |> assert!( father(:homer,:lisa) ); nil
      nil
      iex> e |> provable?( father(:homer,:lisa) )
      true
      iex> e |> provable?( father(:homer,:ralph) )
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
  Assert a fact.

  ## Example

      iex> e = Exlog.new; nil
      nil
      iex> e = e |> assert!( father(:homer,:lisa) ); nil
      nil
  """
  defmacro assert!(e,ex_clause) do
    meta_predicate :assert!, e, {:assert, ex2erlog(ex_clause)}
  end

  @doc """
  Insert clause at the beginning of the clause database.

  ## Example

      iex> use Exlog
      nil
      iex> e = Exlog.new; nil
      nil
      iex> e = e |> assert!( father(:homer,:lisa) ); nil
      nil
      iex> e = e |> asserta!( father(X) <- father(X,_) ); nil
      nil
      iex> e |> provable?( father(:homer) )
      true
      iex> e |> provable?( father(:ralph) )
      false
      iex> e = e |> asserta!( nice_woman(X) <- [nice(X),woman(X)] ); nil
      nil
      iex> e = e |> assert!( nice(:marge) ) |> assert!( woman(:marge) ) |> assert!( nice(:troy) ) |> assert!( woman(:patty) ); nil
      nil
      iex> {e,result} = e |> prove_all( nice_woman(X) ); result
      [[X: :marge]]
  """
  defmacro asserta!(e,ex_clause) do
    meta_predicate :asserta!, e, {:asserta, ex2erlog(ex_clause)}
  end

  @doc """
  Insert clause at the end of the clause database.

  see `asserta!/2`
  """
  defmacro assertz!(e,ex_clause) do
    meta_predicate :assertz!, e, {:assertz, ex2erlog(ex_clause)}
  end

  @doc """
  Remove first unifiable clause from database.

  ## Example

      iex> e = Exlog.new; nil
      nil
      iex> e = e |> assert!( father(:homer,:bart) ); nil
      nil
      iex> e = e |> assert!( father(:homer,:lisa) ); nil
      nil
      iex> e = e |> retract!( father(:homer,X) ); nil
      nil
      iex> {_,result} = e |> prove( father(:homer,X) ); result
      {true, [X: :lisa]}
  """
  defmacro retract!(e,ex_term) do
    meta_predicate :retract!, e, {:retract, ex2erlog(ex_term)}
  end

  # @TODO: DOES NOT WORK FOR NOW
  #@doc """
  #Removes all clauses which head unifies with the given head.
  #
  #Like `retract!/2` but removes all clauses with unifiable heads.
  #"""
  #defmacro retractall!(e,ex_head) do
  #  meta_predicate :retractall!, e, {:retractall, ex2erlog(ex_head)}
  #end

  @doc """
  Remove all clauses with the given functor and arity.

  ## Example

      iex> e = Exlog.new; nil
      nil
      iex> e = e |> assert!( father(:homer,:bart) ); nil
      nil
      iex> e = e |> assert!( father(:homer,:lisa) ); nil
      nil
      iex> e = e |> abolish!( father/2 ); nil
      nil
      iex> e |> prove( father(X,Y) )
      ** (RuntimeError) Exlog error: {:existence_error, :procedure, {:/, :father, 2}}
          (exlog) lib/exlog.ex:265: Exlog.e_prove/2
  """
  defmacro abolish!(e,ex_pred_ind) do
    meta_predicate :abolish!, e, {:abolish, ex2erlog(ex_pred_ind)}
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

  ## Example

      iex> e = Exlog.new; nil
      nil
      iex> e = e |> assert!( father(:homer,:lisa) ); nil
      nil
      iex> e = e |> assert!( father(:homer,:bart) ); nil
      nil
      iex> {e,result} = e |> prove( father(:homer,:lisa) ); result
      {true, []}
      iex> {e,result} = e |> prove( father(:homer,:ralph) ); result
      {false, []}
      iex> {e,result} = e |> prove( father(:homer,X) ); result
      {true, [X: :lisa]}
      iex> {e,result} = e |> next_solution; result
      {true, [X: :bart]}
      iex> {e,result} = e |> next_solution; result
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
  Prove clause and get all solutions.

  ## Example

      iex> e = Exlog.new; nil
      nil
      iex> e = e |> assert!( father(:homer,:lisa) ); nil
      nil
      iex> e = e |> assert!( father(:homer,:bart) ); nil
      nil
      iex> {e,result} = e |> prove_all( father(:homer,X) ); result
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

  # predicate indicator
  defp ex2erlog({:/, meta, [{functor,_meta,_mod},arity]}) when is_atom(functor) and is_integer(arity), do:
    {:{},meta,[:/,functor,arity]}

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
