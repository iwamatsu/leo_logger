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
%% Leo Logger - Client (message)
%% @doc
%% @end
%%======================================================================
-module(leo_logger_client_message).

-author('Yosuke Hara').
-vsn('0.9.1').

-include("leo_logger.hrl").
-include_lib("eunit/include/eunit.hrl").

-export([new/2, new/3,
         debug/1, info/1, warn/1, error/1, fatal/1,
         format/2]).

-define(LOG_FILE_NAME_INFO,  "info").
-define(LOG_FILE_NAME_ERROR, "error").
-define(LOG_GROUP_INFO,      'log_group_message_info').
-define(LOG_GROUP_ERROR,     'log_group_message_error').

%%--------------------------------------------------------------------
%% API
%%--------------------------------------------------------------------
%% @doc Create loggers for message logs
%%
-spec(new(string(), integer()) ->
             ok).
new(RootPath, Level) ->
    new(RootPath, Level, [{?LOG_ID_FILE_INFO,  ?LOG_APPENDER_FILE},
                          {?LOG_ID_FILE_ERROR, ?LOG_APPENDER_FILE}]).

-spec(new(list(), string(), integer()) ->
             ok).
new(RootPath, Level, Loggers) ->
    %% change error-logger
    case gen_event:which_handlers(error_logger) of
        [leo_logger_error_logger_h] ->
            void;
        _ ->
            ok = gen_event:add_sup_handler(error_logger, leo_logger_error_logger_h, []),
            _ = [begin error_logger:delete_report_handler(X), X end ||
                    X <- gen_event:which_handlers(error_logger) -- [leo_logger_error_logger_h]]
    end,

    %% create loggers
    lists:foreach(fun({Id, Appender}) ->
                          case Appender of
                              ?LOG_APPENDER_FILE when Id == ?LOG_ID_FILE_INFO ->
                                  ok = leo_logger_api:new(Id, Appender, [?MODULE, format],
                                                          RootPath, ?LOG_FILE_NAME_INFO, Level),
                                  ok = leo_logger_api:add_appender(?LOG_GROUP_INFO, Id);
                              ?LOG_APPENDER_FILE when Id == ?LOG_ID_FILE_ERROR ->
                                  ok = leo_logger_api:new(Id, Appender, [?MODULE, format],
                                                          RootPath, ?LOG_FILE_NAME_ERROR, Level),
                                  ok = leo_logger_api:add_appender(?LOG_GROUP_ERROR,Id);
                              _ ->
                                  ok = leo_logger_api:new(Id, Appender, [?MODULE, format]),
                                  ok = leo_logger_api:add_appender(?LOG_GROUP_INFO, Id),
                                  ok = leo_logger_api:add_appender(?LOG_GROUP_ERROR,Id)
                          end
                  end, Loggers),
    ok.


%% @doc Output kind of 'Debug log'
-spec(debug(any()) -> ok).
debug(Log) -> leo_logger_api:append(?LOG_GROUP_INFO,  Log, 0).

%% @doc Output kind of 'Information log'
-spec(info(any()) -> ok).
info(Log)  -> leo_logger_api:append(?LOG_GROUP_INFO,  Log, 1).

%% @doc Output kind of 'Warning log'
-spec(warn(any()) -> ok).
warn(Log)  -> leo_logger_api:append(?LOG_GROUP_ERROR, Log, 2).

%% @doc Output kind of 'Error log'
-spec(error(any()) -> ok).
error(Log) -> leo_logger_api:append(?LOG_GROUP_ERROR, Log, 3).

%% @doc Output kind of 'Fatal log'
-spec(fatal(any()) -> ok).
fatal(Log) -> leo_logger_api:append(?LOG_GROUP_ERROR, Log, 4).


%% @doc Format a log message
%%
-spec(format(atom(), #message_log{}) ->
             string()).
format(Appender, Log) ->
    #message_log{format  = Format,
                 message = Message} = Log,
    FormattedMessage =
        case catch io_lib:format(Format, Message) of
            {'EXIT', _} -> [];
            NewMessage  -> NewMessage
        end,

    Output =
        case Appender of
            ?LOG_APPENDER_FILE -> text;
            _Other             -> json
        end,
    format1(Output, Log#message_log{message = FormattedMessage}).

%% @private
-spec(format1(text | json, #message_log{}) ->
             string()).
format1(text, #message_log{level    = Level,
                           module   = Module,
                           function = Function,
                           line     = Line,
                           message  = Message}) ->
    case catch io_lib:format("[~s]\t~s\t~s\t~w\t~s:~s\t~s\t~s\r\n",
                             [log_level(Level),
                              atom_to_list(node()),
                              leo_utils:date_format(type_of_now, now()),
                              unixtime(),
                              Module, Function, integer_to_list(Line),
                              Message]) of
        {'EXIT', _Cause} ->
            [];
        Result ->
            Result
    end;

format1(json, #message_log{level    =  Level,
                           module   =  Module,
                           function =  Function,
                           line     =  Line,
                           message  =  Message}) ->
    Json = {[{log_level, log_level(Level)},
             {node,      node()},
             {module,    list_to_binary(Module)},
             {function,  list_to_binary(Function)},
             {line,      Line},
             {message,   list_to_binary(Message)},
             {unix_time, unixtime()},
             {timestamp, leo_utils:date_format(type_of_now, os:timestamp())}
            ]},
    case catch jiffy:encode(Json) of
        {'EXIT', _} ->
            [];
        Result ->
            Result
    end.



%%--------------------------------------------------------------------
%% INNER FUNCTIONS
%%--------------------------------------------------------------------
%% @doc Set log-level
%% @private
log_level(?LOG_LEVEL_DEBUG) -> "D";
log_level(?LOG_LEVEL_INFO)  -> "I";
log_level(?LOG_LEVEL_WARN)  -> "W";
log_level(?LOG_LEVEL_ERROR) -> "E";
log_level(?LOG_LEVEL_FATAL) -> "F";
log_level(_)                -> "_".


%% @doc get unix-time
%% @private
unixtime() ->
    {H,S,_} = os:timestamp(),
    list_to_integer(integer_to_list(H) ++ integer_to_list(S)).
