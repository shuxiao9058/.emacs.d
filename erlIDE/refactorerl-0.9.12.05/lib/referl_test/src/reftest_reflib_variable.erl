%%% -*- coding: latin-1 -*-

%%% The  contents of this  file are  subject to  the Erlang  Public License,
%%% Version  1.1, (the  "License");  you may  not  use this  file except  in
%%% compliance  with the License.  You should  have received  a copy  of the
%%% Erlang  Public License  along  with this  software.  If not,  it can  be
%%% retrieved at http://plc.inf.elte.hu/erlang/
%%%
%%% Software  distributed under  the License  is distributed  on an  "AS IS"
%%% basis, WITHOUT  WARRANTY OF ANY  KIND, either expressed or  implied. See
%%% the License  for the specific language governing  rights and limitations
%%% under the License.
%%%
%%% The Original Code is RefactorErl.
%%%
%%% The Initial Developer of the  Original Code is E�tv�s Lor�nd University.
%%% Portions created  by E�tv�s  Lor�nd University are  Copyright 2008-2009,
%%% E�tv�s Lor�nd University. All Rights Reserved.

%%% @doc Unit test for {@link reflib_variable}.
%%% @author Melinda T�th <toth_m@inf.elte.hu>

-module(reftest_reflib_variable).

-vsn("$Rev: 3893 $").

-compile([export_all]).

-include("test.hrl").

files() ->
    [{module, "var.erl",
      "-module(var).\n"
      "f(A) ->\n"
      "  A + 1.\n"
      "g(X) ->\n"
      "  case X of add -> A = 1+1; mul -> A = 2*2 end, \n"
      "  A + A.\n"
      "emb()->"
      "  if true ->"
      "      fun() -> ok end,"
      "      A=1,"
      "      fun() -> ok end;"
      "    false -> ok"
      "  end.\n"}].

test_scopes() ->
    Def = ?Query:exec1(
             ?Query:seq([?Mod:find(var), ?Mod:local(emb, 0),
                         ?Fun:definition(), ?Form:clause(1)]),
             test_def),
    Var = ?Query:exec1(Def, ?Clause:variable("A"), test_var),
    Fun = ?Query:exec1(Def,
                       ?Query:seq([?Clause:body(1), ?Expr:clause(1),
                                   ?Clause:body(3), ?Expr:clause(1)]),
                       test_fun),
    Scopes = ?Query:exec(Var, ?Var:scopes()),
    [] = Scopes -- [Def, Fun],
    [] = [Def, Fun] -- Scopes,
    ok.

data(Name, Arity) ->
    Mod   = ?Query:exec1(?Mod:find(var), test_module),
    Fun1  = ?Query:exec1(Mod, ?Mod:local(Name, Arity), test_fun),
    Cl    = ?Query:exec1(Fun1, 
                  ?Query:seq(?Fun:definition(), ?Form:clauses()), test_cl),
    Pat   = ?Query:exec1(Cl, ?Clause:patterns(), test_pattern),
    Expr  = ?Query:exec(Cl, ?Clause:body()),
    {Expr, Pat}.

test_bindings() ->
    {Expr, Pat} = data(f, 1),
    Var   = ?Query:exec1(Expr, ?Expr:variables(), test_var),
    [Pat] = ?Query:exec(Var, ?Var:bindings()),
    ok.

test_references() ->
    {Expr, _Pat} = data(g, 1),
    Var   = lists:usort(?Query:exec(Expr, ?Expr:variables())),
    Ref   = ?Query:exec(Var, ?Var:references()),
    Occ   = ?Query:exec(Var, ?Var:occurrences()),
    Bind  = ?Query:exec(Var, ?Var:bindings()),    
    []    = Occ -- (Ref ++ Bind),
    ok.

test_occurrences() ->
    {Expr, _Pat} = data(g, 1),
    Var   = ?Query:exec(Expr, ?Expr:variables()),
    Len   = length(Var),
    Occ   = ?Query:exec(lists:usort(Var), ?Var:occurrences()),
    Len   = length(Occ) - 1,
    ok.
    
test_bindings1() ->
    {_Expr, Pat} = data(g, 1),
    VarX  = ?Query:exec(Pat, ?Expr:varbinds()),
    BindX = ?Query:exec(VarX, ?Var:bindings()),
    BindX = ?Query:exec(VarX, ?Var:bindings(Pat)),
    ok.

test_references1() ->
    {Expr, Pat} = data(g, 1),
    VarX = ?Query:exec(Pat, ?Expr:varbinds()),
    RefX = ?Query:exec(VarX, ?Var:references()),
    RefX = ?Query:exec(VarX, ?Var:references(hd(Expr))),
    ok.

test_occurrences1() ->
    {Expr, _Pat} = data(g, 1),
    VarA  = lists:usort(?Query:exec(Expr, ?Expr:varbinds())),
    OccA1 = ?Query:exec(VarA, ?Var:occurrences()),
    OccA2 = lists:flatten(
                  [?Query:exec(VarA, ?Var:occurrences(E)) || E <- Expr]),
    []    = OccA1 -- OccA2,    
    ok.

test_valid_name() ->
    Good  = [[[],["A"]],"A", "_A", "ABC123", "A_2b@1Cd"],
    Bad   = ["", "_", [[],[]], [[],["_"]], "a", "1", "$", [[],"a",[]]],
    true  = lists:all(fun ?Var:valid_name/1, Good),
    false = lists:any(fun ?Var:valid_name/1, Bad),
    ok.
