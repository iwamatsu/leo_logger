%%======================================================================
%%
%% Leo Logger
%%
%% Copyright (c) 2012 Rakuten, Inc.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% ---------------------------------------------------------------------
%% Leo Logger  - Behaviour.
%% @doc
%% @end
%%======================================================================
-module(leo_logger_behavior).

-author('Yosuke Hara').
-vsn('0.9.1').

-export([behaviour_info/1]).

behaviour_info(callbacks) ->
    [
     %% init(atom(), list(), list() ->  {ok, #logger_state{}}.
     {init, 3},

     %% append(list(), #logger_state{}) -> ok.
     {append, 2},

     %% rotate(integer(), #logger_state{}) -> {ok, #logger_state{}}
     {rotate, 2}
    ];
behaviour_info(_Other) ->
    undefined.

