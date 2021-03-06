%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 2001-2011. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%%
%% %CopyrightEnd%
%%
%%
%%% Purpose : Test suite for the ASN.1 application

-module(asn1_SUITE).
-define(PER,'per').
-define(BER,'ber').
-define(ber_driver(Erule,Func),
	case Erule of
           ber_bin_v2 ->
		Func;
	    _ -> ok
	end).
-define(per_optimize(Erule),
	case Erule of
	   ber_bin_v2 ->[optimize];
           _ -> []
	end).
-define(per_bit_opt(FuncCall),
	case ?BER of
	   ber_bin_v2 -> FuncCall;
%	   _ -> {skip,"only for bit optimized per_bin"}
	   _ -> ok
	end).
-define(uper_bin(FuncCall),
	case ?PER of
	   per -> FuncCall;
	   _ -> ok
	end).

-compile(export_all).
%%-export([Function/Arity, ...]).

-include_lib("test_server/include/test_server.hrl").

%% records used by test-case default
-record('Def1',{ bool0, 
		 bool1 = asn1_DEFAULT, 
		 bool2 = asn1_DEFAULT, 
		 bool3 = asn1_DEFAULT}).

%-record('Def2',{
%bool10, bool11 = asn1_DEFAULT, bool12 = asn1_DEFAULT, bool13}).

%-record('Def3',{
%bool30 = asn1_DEFAULT, bool31 = asn1_DEFAULT, bool32 = asn1_DEFAULT, bool33 = asn1_DEFAULT}).

suite() -> [{ct_hooks,[ts_install_cth]}].

all() -> 
    [{group, compile}, parse, default_per, default_ber,
     default_per_opt, per, {group, ber}, testPrim,
     testPrimStrings, testPrimExternal, testChoPrim,
     testChoExtension, testChoExternal, testChoOptional,
     testChoOptionalImplicitTag, testChoRecursive,
     testChoTypeRefCho, testChoTypeRefPrim,
     testChoTypeRefSeq, testChoTypeRefSet, testDef, testOpt,
     testSeqDefault, testSeqExtension, testSeqExternal,
     testSeqOptional, testSeqPrim, testSeqTag,
     testSeqTypeRefCho, testSeqTypeRefPrim,
     testSeqTypeRefSeq, testSeqTypeRefSet, testSeqOf,
     testSeqOfIndefinite, testSeqOfCho, testSeqOfExternal,
     testSetDefault, testSetExtension,
     testExtensionAdditionGroup, testSetExternal,
     testSeqOfTag, testSetOptional, testSetPrim, testSetTag,
     testSetTypeRefCho, testSetTypeRefPrim,
     testSetTypeRefSeq, testSetTypeRefSet, testSetOf,
     testSetOfCho, testSetOfExternal, testSetOfTag,
     testEnumExt, value_test, testSeq2738, constructed,
     ber_decode_error, h323test, testSeqIndefinite,
     testSetIndefinite, testChoiceIndefinite,
     per_GeneralString, per_open_type, testInfObjectClass,
     testParameterizedInfObj, testMergeCompile, testobj,
     testDeepTConstr, testConstraints, testInvokeMod,
     testExport, testImport, testCompactBitString,
     testMegaco, testParamBasic, testMvrasn6,
     testContextSwitchingTypes, testTypeValueNotation,
     testOpenTypeImplicitTag, duplicate_tags, rtUI, testROSE,
     testINSTANCE_OF, testTCAP, testDER, specialized_decodes,
     special_decode_performance, test_driver_load,
     test_ParamTypeInfObj, test_WS_ParamClass,
     test_Defed_ObjectIdentifier, testSelectionType,
     testSSLspecs, testNortel, test_undecoded_rest,
     test_inline, testTcapsystem, testNBAPsystem,
     test_compile_options, testDoubleEllipses,
     test_modified_x420, testX420, test_x691, ticket_6143,
     testExtensionAdditionGroup] ++ common() ++ particular().

groups() -> 
    [{option_tests, [],
      [test_compile_options, ticket_6143]},
     {infobj, [],
      [testInfObjectClass, testParameterizedInfObj,
       testMergeCompile, testobj, testDeepTConstr]},
     {performance, [],
      [testTimer_ber, testTimer_ber_opt_driver, testTimer_per,
       testTimer_per_opt, testTimer_uper_bin]},
     {bugs, [],
      [test_ParamTypeInfObj, test_WS_ParamClass,
       test_Defed_ObjectIdentifier]},
     {compile, [],
      [c_syntax, c_string_per, c_string_ber,
       c_implicit_before_choice]},
     {ber, [],
      [ber_choiceinseq, ber_optional, ber_optional_keyed_list,
       ber_other]},
     {app_test, [], [{asn1_app_test, all}]},
     {appup_test, [], [{asn1_appup_test, all}]}].

init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

init_per_group(_GroupName, Config) ->
	Config.

end_per_group(_GroupName, Config) ->
	Config.


%all(suite) -> [test_inline,testNBAPsystem,test_compile_options,ticket_6143].


init_per_testcase(Func,Config) ->
    %%?line test_server:format("Func: ~p~n",[Func]),
    ?line {ok, _} = file:read_file_info(filename:join([?config(priv_dir,Config)])),
    ?line code:add_patha(?config(priv_dir,Config)),
    Dog=
    case Func of
       testX420 ->
           test_server:timetrap({minutes,60}); % 60 minutes
       _ ->
	   test_server:timetrap({minutes,30}) % 60 minutes
    end,
%%    Dog=test_server:timetrap(1800000), % 30 minutes
    [{watchdog, Dog}|Config].

end_per_testcase(_Func,Config) ->
          Dog=?config(watchdog, Config),
          test_server:timetrap_cancel(Dog).


testPrim(suite) -> [];
testPrim(Config) ->
    ?line testPrim:compile(Config,?BER,[]),
    ?line testPrim_cases(?BER),
    ?line ?ber_driver(?BER,testPrim:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testPrim_cases(?BER)),
    ?line testPrim:compile(Config,?PER,[]),
    ?line testPrim_cases(?PER),
    ?line ?per_bit_opt(testPrim:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testPrim_cases(?PER)),
    ?line ?uper_bin(testPrim:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testPrim_cases(uper_bin)),
    ?line testPrim:compile(Config,?PER,[optimize]),
    ?line testPrim_cases(?PER).

testPrim_cases(Rules) ->
    ?line testPrim:bool(Rules),
    ?line testPrim:int(Rules),
    ?line testPrim:enum(Rules),
    ?line testPrim:obj_id(Rules),
    ?line testPrim:rel_oid(Rules),
    ?line testPrim:null(Rules),
    ?line testPrim:real(Rules).


testCompactBitString(suite) -> [];
testCompactBitString(Config) -> 

    ?line testCompactBitString:compile(Config,?BER,[compact_bit_string]),
    ?line testCompactBitString:compact_bit_string(?BER),

    ?line ?ber_driver(?BER,testCompactBitString:compile(Config,?BER,[compact_bit_string,driver])),
    ?line ?ber_driver(?BER,testCompactBitString:compact_bit_string(?BER)),

    ?line testCompactBitString:compile(Config,?PER,[compact_bit_string]),
    ?line testCompactBitString:compact_bit_string(?PER),
    ?line testCompactBitString:bit_string_unnamed(?PER),

    ?line ?per_bit_opt(testCompactBitString:compile(Config,?PER,
					[compact_bit_string,optimize])),
    ?line ?per_bit_opt(testCompactBitString:compact_bit_string(?PER)),
    ?line ?per_bit_opt(testCompactBitString:bit_string_unnamed(?PER)),
    ?line ?per_bit_opt(testCompactBitString:ticket_7734(?PER)),

    ?line ?uper_bin(testCompactBitString:compile(Config,uper_bin,
					[compact_bit_string])),
    ?line ?uper_bin(testCompactBitString:compact_bit_string(uper_bin)),
    ?line ?uper_bin(testCompactBitString:bit_string_unnamed(uper_bin)),

    ?line testCompactBitString:compile(Config,?PER,[optimize,compact_bit_string]),
    ?line testCompactBitString:compact_bit_string(?PER),
    ?line testCompactBitString:bit_string_unnamed(?PER),

    ?line testCompactBitString:otp_4869(?PER).


testPrimStrings(suite) -> [];
testPrimStrings(Config) ->

    ?line testPrimStrings:compile(Config,?BER,[]),
    ?line testPrimStrings_cases(?BER),
    ?line testPrimStrings:more_strings(?BER), %% these are not implemented in per yet
    ?line ?ber_driver(?BER,testPrimStrings:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testPrimStrings_cases(?BER)),
    ?line ?ber_driver(?BER,testPrimStrings:more_strings(?BER)),

    ?line testPrimStrings:compile(Config,?PER,[]),
    ?line testPrimStrings_cases(?PER),

    ?line ?per_bit_opt(testPrimStrings:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testPrimStrings_cases(?PER)),

    ?line ?uper_bin(testPrimStrings:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testPrimStrings_cases(uper_bin)),

    ?line testPrimStrings:compile(Config,?PER,[optimize]),
    ?line testPrimStrings_cases(?PER).

testPrimStrings_cases(Rules) ->
    ?line testPrimStrings:bit_string(Rules),
    ?line testPrimStrings:bit_string_unnamed(Rules),
    ?line testPrimStrings:octet_string(Rules),
    ?line testPrimStrings:numeric_string(Rules),
    ?line testPrimStrings:other_strings(Rules),
    ?line testPrimStrings:universal_string(Rules),
    ?line testPrimStrings:bmp_string(Rules),
    ?line testPrimStrings:times(Rules),
    ?line testPrimStrings:utf8_string(Rules).
    


testPrimExternal(suite) -> [];
testPrimExternal(Config) ->

    ?line testExternal:compile(Config,?BER,[]),
    ?line testPrimExternal:compile(Config,?BER,[]),
    ?line testPrimExternal_cases(?BER),

    ?line ?ber_driver(?BER,testExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testPrimExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testPrimExternal_cases(?BER)),
    
    ?line testExternal:compile(Config,?PER,[]),     
    ?line testPrimExternal:compile(Config,?PER,[]), 
    ?line testPrimExternal_cases(?PER),

    ?line ?per_bit_opt(testExternal:compile(Config,?PER,[optimize])),     
    ?line ?per_bit_opt(testPrimExternal:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testPrimExternal_cases(?PER)),

    ?line ?uper_bin(testExternal:compile(Config,uper_bin,[])),     
    ?line ?uper_bin(testPrimExternal:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testPrimExternal_cases(uper_bin)),

    ?line testExternal:compile(Config,?PER,[optimize]),     
    ?line testPrimExternal:compile(Config,?PER,[optimize]), 
    ?line testPrimExternal_cases(?PER).

testPrimExternal_cases(Rules) ->
    ?line testPrimExternal:external(Rules).




testChoPrim(suite) -> [];
testChoPrim(Config) ->

    ?line testChoPrim:compile(Config,?BER,[]),
    ?line testChoPrim_cases(?BER),

    ?line ?ber_driver(?BER,testChoPrim:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testChoPrim_cases(?BER)),

    ?line testChoPrim:compile(Config,?PER,[]), 
    ?line testChoPrim_cases(?PER),

    ?line ?per_bit_opt(testChoPrim:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testChoPrim_cases(?PER)),

    ?line ?uper_bin(testChoPrim:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testChoPrim_cases(uper_bin)),

    ?line testChoPrim:compile(Config,?PER,[optimize]), 
    ?line testChoPrim_cases(?PER).

testChoPrim_cases(Rules) ->
    ?line testChoPrim:bool(Rules),
    ?line testChoPrim:int(Rules).



testChoExtension(suite) -> [];
testChoExtension(Config) ->

    ?line testChoExtension:compile(Config,?BER,[]),
    ?line testChoExtension_cases(?BER),          

    ?line ?ber_driver(?BER,testChoExtension:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testChoExtension_cases(?BER)),

    ?line testChoExtension:compile(Config,?PER,[]),
    ?line testChoExtension_cases(?PER),          

    ?line ?per_bit_opt(testChoExtension:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testChoExtension_cases(?PER)),

    ?line ?uper_bin(testChoExtension:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testChoExtension_cases(uper_bin)),

    ?line testChoExtension:compile(Config,?PER,[optimize]),
    ?line testChoExtension_cases(?PER).          

testChoExtension_cases(Rules) ->
    ?line testChoExtension:extension(Rules).



testChoExternal(suite) -> [];
testChoExternal(Config) ->

    ?line testExternal:compile(Config,?BER,[]),
    ?line testChoExternal:compile(Config,?BER,[]),
    ?line testChoExternal_cases(?BER),

    ?line ?ber_driver(?BER,testExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testChoExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testChoExternal_cases(?BER)),

    ?line testExternal:compile(Config,?PER,[]),
    ?line testChoExternal:compile(Config,?PER,[]), 
    ?line testChoExternal_cases(?PER),

    ?line ?per_bit_opt(testExternal:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testChoExternal:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testChoExternal_cases(?PER)),

    ?line ?uper_bin(testExternal:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testChoExternal:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testChoExternal_cases(uper_bin)),

    ?line testExternal:compile(Config,?PER,[optimize]),
    ?line testChoExternal:compile(Config,?PER,[optimize]), 
    ?line testChoExternal_cases(?PER).


testChoExternal_cases(Rules) ->
    ?line testChoExternal:external(Rules).



testChoOptional(suite) -> [];
testChoOptional(Config) ->

    ?line testChoOptional:compile(Config,?BER,[]),
    ?line testChoOptional_cases(?BER),

    ?line ?ber_driver(?BER,testChoOptional:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testChoOptional_cases(?BER)),

    ?line testChoOptional:compile(Config,?PER,[]), 
    ?line testChoOptional_cases(?PER),

    ?line ?per_bit_opt(testChoOptional:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testChoOptional_cases(?PER)),

    ?line ?uper_bin(testChoOptional:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testChoOptional_cases(uper_bin)),

    ?line testChoOptional:compile(Config,?PER,[optimize]), 
    ?line testChoOptional_cases(?PER).

testChoOptional_cases(Rules) ->
    ?line testChoOptional:optional(Rules).

testChoOptionalImplicitTag(suite) -> [];
testChoOptionalImplicitTag(Config) ->
    %% Only meaningful for ?BER
    ?line testChoOptionalImplicitTag:compile(Config,?BER),
    ?line testChoOptionalImplicitTag:optional(?BER).


testChoRecursive(suite) -> [];
testChoRecursive(Config) ->

    ?line testChoRecursive:compile(Config,?BER,[]),
    ?line testChoRecursive_cases(?BER),

    ?line ?ber_driver(?BER,testChoRecursive:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testChoRecursive_cases(?BER)),

    ?line testChoRecursive:compile(Config,?PER,[]), 
    ?line testChoRecursive_cases(?PER),

    ?line ?per_bit_opt(testChoRecursive:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testChoRecursive_cases(?PER)),

    ?line ?uper_bin(testChoRecursive:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testChoRecursive_cases(uper_bin)),

    ?line testChoRecursive:compile(Config,?PER,[optimize]), 
    ?line testChoRecursive_cases(?PER).

testChoRecursive_cases(Rules) ->
    ?line testChoRecursive:recursive(Rules).



testChoTypeRefCho(suite) -> [];
testChoTypeRefCho(Config) ->

    ?line testChoTypeRefCho:compile(Config,?BER,[]),
    ?line testChoTypeRefCho_cases(?BER),

    ?line ?ber_driver(?BER,testChoTypeRefCho:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testChoTypeRefCho_cases(?BER)),

    ?line testChoTypeRefCho:compile(Config,?PER,[]), 
    ?line testChoTypeRefCho_cases(?PER),

    ?line ?per_bit_opt(testChoTypeRefCho:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testChoTypeRefCho_cases(?PER)),

    ?line ?uper_bin(testChoTypeRefCho:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testChoTypeRefCho_cases(uper_bin)),

    ?line testChoTypeRefCho:compile(Config,?PER,[optimize]), 
    ?line testChoTypeRefCho_cases(?PER).

testChoTypeRefCho_cases(Rules) ->
    ?line testChoTypeRefCho:choice(Rules).



testChoTypeRefPrim(suite) -> [];
testChoTypeRefPrim(Config) ->

    ?line testChoTypeRefPrim:compile(Config,?BER,[]),
    ?line testChoTypeRefPrim_cases(?BER),

    ?line ?ber_driver(?BER,testChoTypeRefPrim:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testChoTypeRefPrim_cases(?BER)),

    ?line testChoTypeRefPrim:compile(Config,?PER,[]), 
    ?line testChoTypeRefPrim_cases(?PER),

    ?line ?per_bit_opt(testChoTypeRefPrim:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testChoTypeRefPrim_cases(?PER)),

    ?line ?uper_bin(testChoTypeRefPrim:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testChoTypeRefPrim_cases(uper_bin)),

    ?line testChoTypeRefPrim:compile(Config,?PER,[optimize]), 
    ?line testChoTypeRefPrim_cases(?PER).

testChoTypeRefPrim_cases(Rules) ->
    ?line testChoTypeRefPrim:prim(Rules).



testChoTypeRefSeq(suite) -> [];
testChoTypeRefSeq(Config) ->

    ?line testChoTypeRefSeq:compile(Config,?BER,[]),
    ?line testChoTypeRefSeq_cases(?BER),

    ?line ?ber_driver(?BER,testChoTypeRefSeq:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testChoTypeRefSeq_cases(?BER)),

    ?line testChoTypeRefSeq:compile(Config,?PER,[]), 
    ?line testChoTypeRefSeq_cases(?PER),

    ?line ?per_bit_opt(testChoTypeRefSeq:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testChoTypeRefSeq_cases(?PER)),

    ?line ?uper_bin(testChoTypeRefSeq:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testChoTypeRefSeq_cases(uper_bin)),

    ?line testChoTypeRefSeq:compile(Config,?PER,[optimize]), 
    ?line testChoTypeRefSeq_cases(?PER).

testChoTypeRefSeq_cases(Rules) ->
    ?line testChoTypeRefSeq:seq(Rules).



testChoTypeRefSet(suite) -> [];
testChoTypeRefSet(Config) ->

    ?line testChoTypeRefSet:compile(Config,?BER,[]),
    ?line testChoTypeRefSet_cases(?BER),

    ?line ?ber_driver(?BER,testChoTypeRefSet:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testChoTypeRefSet_cases(?BER)),

    ?line testChoTypeRefSet:compile(Config,?PER,[]), 
    ?line testChoTypeRefSet_cases(?PER),

    ?line ?per_bit_opt(testChoTypeRefSet:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testChoTypeRefSet_cases(?PER)),

    ?line ?uper_bin(testChoTypeRefSet:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testChoTypeRefSet_cases(uper_bin)),

    ?line testChoTypeRefSet:compile(Config,?PER,[optimize]), 
    ?line testChoTypeRefSet_cases(?PER).

testChoTypeRefSet_cases(Rules) ->
    ?line testChoTypeRefSet:set(Rules).



testDef(suite) -> [];
testDef(Config) ->

    ?line testDef:compile(Config,?BER,[]),
    ?line testDef_cases(?BER),

    ?line ?ber_driver(?BER,testDef:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testDef_cases(?BER)),

    ?line testDef:compile(Config,?PER,[]), 
    ?line testDef_cases(?PER),

    ?line ?per_bit_opt(testDef:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testDef_cases(?PER)),

    ?line ?uper_bin(testDef:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testDef_cases(uper_bin)),

    ?line testDef:compile(Config,?PER,[optimize]), 
    ?line testDef_cases(?PER).

testDef_cases(Rules) ->
    ?line testDef:main(Rules).



testOpt(suite) -> [];
testOpt(Config) ->

    ?line testOpt:compile(Config,?BER),
    ?line testOpt_cases(?BER),

    ?line testOpt:compile(Config,?PER), 
    ?line testOpt_cases(?PER).          

testOpt_cases(Rules) ->
    ?line testOpt:main(Rules).


testEnumExt(suite) -> [];
testEnumExt(Config) ->

    ?line testEnumExt:compile(Config,?BER,[]),
    ?line testEnumExt:main(?BER),

    ?line ?ber_driver(?BER,testEnumExt:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testEnumExt:main(?BER)),

    ?line testEnumExt:compile(Config,?PER,[]),
    ?line testEnumExt:main(?PER),

    ?line ?per_bit_opt(testEnumExt:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testEnumExt:main(?PER)),

    ?line ?uper_bin(testEnumExt:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testEnumExt:main(uper_bin)),

    ?line testEnumExt:compile(Config,?PER,[optimize]),
    ?line testEnumExt:main(?PER).

testSeqDefault(doc) -> ["Test of OTP-2523 ENUMERATED with extensionmark."];
testSeqDefault(suite) -> [];
testSeqDefault(Config) ->

    ?line testSeqDefault:compile(Config,?BER,[]),
    ?line testSeqDefault_cases(?BER),

    ?line ?ber_driver(?BER,testSeqDefault:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqDefault_cases(?BER)),

    ?line testSeqDefault:compile(Config,?PER,[]), 
    ?line testSeqDefault_cases(?PER),

    ?line ?per_bit_opt(testSeqDefault:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeqDefault_cases(?PER)),

    ?line ?uper_bin(testSeqDefault:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeqDefault_cases(uper_bin)),

    ?line testSeqDefault:compile(Config,?PER,[optimize]), 
    ?line testSeqDefault_cases(?PER).

testSeqDefault_cases(Rules) ->
    ?line testSeqDefault:main(Rules).



testSeqExtension(suite) -> [];
testSeqExtension(Config) ->

    ?line testExternal:compile(Config,?BER,[]),
    ?line testSeqExtension:compile(Config,?BER,[]),
    ?line testSeqExtension_cases(?BER),

    ?line ?ber_driver(?BER,testExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqExtension:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqExtension_cases(?BER)).

testSeqExtension_cases(Rules) ->
    ?line testSeqExtension:main(Rules).



testSeqExternal(suite) -> [];
testSeqExternal(Config) ->

    ?line testExternal:compile(Config,?BER,[]),
    ?line testSeqExternal:compile(Config,?BER,[]),
    ?line testSeqExternal_cases(?BER),

    ?line ?ber_driver(?BER,testExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqExternal_cases(?BER)).

testSeqExternal_cases(Rules) ->
    ?line testSeqExternal:main(Rules).


testSeqOptional(suite) -> [];
testSeqOptional(Config) ->

    ?line testSeqOptional:compile(Config,?BER,[]),
    ?line testSeqOptional_cases(?BER),

    ?line ?ber_driver(?BER,testSeqOptional:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqOptional_cases(?BER)),

    ?line testSeqOptional:compile(Config,?PER,[]), 
    ?line testSeqOptional_cases(?PER),

    ?line ?per_bit_opt(testSeqOptional:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeqOptional_cases(?PER)),

    ?line ?uper_bin(testSeqOptional:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeqOptional_cases(uper_bin)),

    ?line testSeqOptional:compile(Config,?PER,[optimize]), 
    ?line testSeqOptional_cases(?PER).

testSeqOptional_cases(Rules) ->
    ?line testSeqOptional:main(Rules).



testSeqPrim(suite) -> [];
testSeqPrim(Config) ->

    ?line testSeqPrim:compile(Config,?BER,[]),
    ?line testSeqPrim_cases(?BER),

    ?line ?ber_driver(?BER,testSeqPrim:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqPrim_cases(?BER)),

    ?line testSeqPrim:compile(Config,?PER,[]), 
    ?line testSeqPrim_cases(?PER),

    ?line ?per_bit_opt(testSeqPrim:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeqPrim_cases(?PER)),

    ?line ?uper_bin(testSeqPrim:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeqPrim_cases(uper_bin)),

    ?line testSeqPrim:compile(Config,?PER,[optimize]), 
    ?line testSeqPrim_cases(?PER).

testSeqPrim_cases(Rules) ->
    ?line testSeqPrim:main(Rules).


testSeq2738(doc) -> ["Test of OTP-2738 Detect corrupt optional component."];
testSeq2738(suite) -> [];
testSeq2738(Config) ->

    ?line testSeq2738:compile(Config,?BER,[]),
    ?line testSeq2738_cases(?BER),

    ?line ?ber_driver(?BER,testSeq2738:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeq2738_cases(?BER)),

    ?line testSeq2738:compile(Config,?PER,[]), 
    ?line testSeq2738_cases(?PER),

    ?line ?per_bit_opt(testSeq2738:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeq2738_cases(?PER)),

    ?line ?uper_bin(testSeq2738:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeq2738_cases(uper_bin)),

    ?line testSeq2738:compile(Config,?PER,[optimize]), 
    ?line testSeq2738_cases(?PER).

testSeq2738_cases(Rules) ->
    ?line testSeq2738:main(Rules).


testSeqTag(suite) -> [];
testSeqTag(Config) ->

    ?line testExternal:compile(Config,?BER,[]),
    ?line testSeqTag:compile(Config,?BER,[]),
    ?line testSeqTag_cases(?BER),

    ?line ?ber_driver(?BER,testExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqTag:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqTag_cases(?BER)),

    ?line testExternal:compile(Config,?PER,[]),
    ?line testSeqTag:compile(Config,?PER,[]), 
    ?line testSeqTag_cases(?PER),

    ?line ?per_bit_opt(testExternal:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testSeqTag:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeqTag_cases(?PER)),

    ?line ?uper_bin(testExternal:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testSeqTag:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeqTag_cases(uper_bin)),

    ?line testExternal:compile(Config,?PER,[optimize]),
    ?line testSeqTag:compile(Config,?PER,[optimize]), 
    ?line testSeqTag_cases(?PER).

testSeqTag_cases(Rules) ->
    ?line testSeqTag:main(Rules).




testSeqTypeRefCho(suite) -> [];
testSeqTypeRefCho(Config) ->

    ?line testSeqTypeRefCho:compile(Config,?BER,[]),
    ?line testSeqTypeRefCho_cases(?BER),

    ?line ?ber_driver(?BER,testSeqTypeRefCho:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqTypeRefCho_cases(?BER)),

    ?line testSeqTypeRefCho:compile(Config,?PER,[]), 
    ?line testSeqTypeRefCho_cases(?PER),

    ?line ?per_bit_opt(testSeqTypeRefCho:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeqTypeRefCho_cases(?PER)),

    ?line ?uper_bin(testSeqTypeRefCho:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeqTypeRefCho_cases(uper_bin)),

    ?line testSeqTypeRefCho:compile(Config,?PER,[optimize]), 
    ?line testSeqTypeRefCho_cases(?PER).

testSeqTypeRefCho_cases(Rules) ->
    ?line testSeqTypeRefCho:main(Rules).



testSeqTypeRefPrim(suite) -> [];
testSeqTypeRefPrim(Config) ->

    ?line testSeqTypeRefPrim:compile(Config,?BER,[]),
    ?line testSeqTypeRefPrim_cases(?BER),

    ?line ?ber_driver(?BER,testSeqTypeRefPrim:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqTypeRefPrim_cases(?BER)),

    ?line testSeqTypeRefPrim:compile(Config,?PER,[]), 
    ?line testSeqTypeRefPrim_cases(?PER),

    ?line ?per_bit_opt(testSeqTypeRefPrim:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeqTypeRefPrim_cases(?PER)),

    ?line ?uper_bin(testSeqTypeRefPrim:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeqTypeRefPrim_cases(uper_bin)),

    ?line testSeqTypeRefPrim:compile(Config,?PER,[optimize]), 
    ?line testSeqTypeRefPrim_cases(?PER).

testSeqTypeRefPrim_cases(Rules) ->
    ?line testSeqTypeRefPrim:main(Rules).



testSeqTypeRefSeq(suite) -> [];
testSeqTypeRefSeq(Config) ->

    ?line testSeqTypeRefSeq:compile(Config,?BER,[]),
    ?line testSeqTypeRefSeq_cases(?BER),

    ?line ?ber_driver(?BER,testSeqTypeRefSeq:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqTypeRefSeq_cases(?BER)),

    ?line testSeqTypeRefSeq:compile(Config,?PER,[]), 
    ?line testSeqTypeRefSeq_cases(?PER),

    ?line ?per_bit_opt(testSeqTypeRefSeq:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeqTypeRefSeq_cases(?PER)),

    ?line ?uper_bin(testSeqTypeRefSeq:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeqTypeRefSeq_cases(uper_bin)),

    ?line testSeqTypeRefSeq:compile(Config,?PER,[optimize]), 
    ?line testSeqTypeRefSeq_cases(?PER).

testSeqTypeRefSeq_cases(Rules) ->
    ?line testSeqTypeRefSeq:main(Rules).



testSeqTypeRefSet(suite) -> [];
testSeqTypeRefSet(Config) ->

    ?line testSeqTypeRefSet:compile(Config,?BER,[]),
    ?line testSeqTypeRefSet_cases(?BER),

    ?line ?ber_driver(?BER,testSeqTypeRefSet:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqTypeRefSet_cases(?BER)),

    ?line testSeqTypeRefSet:compile(Config,?PER,[]), 
    ?line testSeqTypeRefSet_cases(?PER),

    ?line ?per_bit_opt(testSeqTypeRefSet:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeqTypeRefSet_cases(?PER)),

    ?line ?uper_bin(testSeqTypeRefSet:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeqTypeRefSet_cases(uper_bin)),

    ?line testSeqTypeRefSet:compile(Config,?PER,[optimize]), 
    ?line testSeqTypeRefSet_cases(?PER).

testSeqTypeRefSet_cases(Rules) ->
    ?line testSeqTypeRefSet:main(Rules).




testSeqOf(suite) -> [];
testSeqOf(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSeqOf:compile(Config,?BER,[]),
    ?line testSeqOf_cases(?BER),

    ?line ?ber_driver(?BER,testSeqOf:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqOf_cases(?BER)),

    ?line testSeqOf:compile(Config,?PER,[]), 
    ?line testSeqOf_cases(?PER),

    ?line ?per_bit_opt(testSeqOf:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeqOf_cases(?PER)),

    ?line ?uper_bin(testSeqOf:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeqOf_cases(uper_bin)),

    ?line testSeqOf:compile(Config,?PER,[optimize]), 
    ?line testSeqOf_cases(?PER).

testSeqOf_cases(Rules) ->
    ?line testSeqOf:main(Rules).




testSeqOfCho(suite) -> [];
testSeqOfCho(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSeqOfCho:compile(Config,?BER,[]),
    ?line testSeqOfCho_cases(?BER),

    ?line ?ber_driver(?BER,testSeqOfCho:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqOfCho_cases(?BER)),

    ?line testSeqOfCho:compile(Config,?PER,[]), 
    ?line testSeqOfCho_cases(?PER),

    ?line ?per_bit_opt(testSeqOfCho:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeqOfCho_cases(?PER)),

    ?line ?uper_bin(testSeqOfCho:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeqOfCho_cases(uper_bin)),

    ?line testSeqOfCho:compile(Config,?PER,[optimize]), 
    ?line testSeqOfCho_cases(?PER).

testSeqOfIndefinite(suite) -> [];
testSeqOfIndefinite(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSeqOfIndefinite:compile(Config,?BER,[]),
    ?line testSeqOfIndefinite:main(),

    ?line ?ber_driver(?BER,testSeqOfIndefinite:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqOfIndefinite:main()).

testSeqOfCho_cases(Rules) ->
    ?line testSeqOfCho:main(Rules).


testSeqOfExternal(suite) -> [];
testSeqOfExternal(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testExternal:compile(Config,?BER,[]),
    ?line testSeqOfExternal:compile(Config,?BER,[]),
    ?line testSeqOfExternal_cases(?BER),

    ?line ?ber_driver(?BER,testExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqOfExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqOfExternal_cases(?BER)),

    ?line testExternal:compile(Config,?PER,[]),
    ?line testSeqOfExternal:compile(Config,?PER,[]), 
    ?line testSeqOfExternal_cases(?PER),

    ?line ?per_bit_opt(testExternal:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testSeqOfExternal:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeqOfExternal_cases(?PER)),

    ?line ?uper_bin(testExternal:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testSeqOfExternal:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeqOfExternal_cases(uper_bin)),

    ?line testExternal:compile(Config,?PER,[optimize]),
    ?line testSeqOfExternal:compile(Config,?PER,[optimize]), 
    ?line testSeqOfExternal_cases(?PER).

testSeqOfExternal_cases(Rules) ->
    ?line testSeqOfExternal:main(Rules).



testSeqOfTag(suite) -> [];
testSeqOfTag(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testExternal:compile(Config,?BER,[]),
    ?line testSeqOfTag:compile(Config,?BER,[]),
    ?line testSeqOfTag_cases(?BER),

    ?line ?ber_driver(?BER,testExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqOfTag:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqOfTag_cases(?BER)),

    ?line testExternal:compile(Config,?PER,[]),
    ?line testSeqOfTag:compile(Config,?PER,[]), 
    ?line testSeqOfTag_cases(?PER),

    ?line ?per_bit_opt(testExternal:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testSeqOfTag:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSeqOfTag_cases(?PER)),

    ?line ?uper_bin(testExternal:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testSeqOfTag:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSeqOfTag_cases(uper_bin)),

    ?line testExternal:compile(Config,?PER,[optimize]),
    ?line testSeqOfTag:compile(Config,?PER,[optimize]), 
    ?line testSeqOfTag_cases(?PER).

testSeqOfTag_cases(Rules) ->
    ?line testSeqOfTag:main(Rules).




testSetDefault(suite) -> [];
testSetDefault(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSetDefault:compile(Config,?BER,[]),
    ?line testSetDefault_cases(?BER),

    ?line ?ber_driver(?BER,testSetDefault:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetDefault_cases(?BER)),

    ?line testSetDefault:compile(Config,?PER,[]), 
    ?line testSetDefault_cases(?PER),

    ?line ?per_bit_opt(testSetDefault:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSetDefault_cases(?PER)),

    ?line ?uper_bin(testSetDefault:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSetDefault_cases(uper_bin)),

    ?line testSetDefault:compile(Config,?PER,[optimize]), 
    ?line testSetDefault_cases(?PER).

testSetDefault_cases(Rules) ->
    ?line testSetDefault:main(Rules).


testParamBasic(suite) -> [];
testParamBasic(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testParamBasic:compile(Config,?BER,[]),
    ?line testParamBasic_cases(?BER),

    ?line ?ber_driver(?BER,testParamBasic:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testParamBasic_cases(?BER)),

    ?line testParamBasic:compile(Config,?PER,[]),
    ?line testParamBasic_cases(?PER),

    ?line ?per_bit_opt(testParamBasic:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testParamBasic_cases(?PER)),

    ?line ?uper_bin(testParamBasic:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testParamBasic_cases(uper_bin)),

    ?line testParamBasic:compile(Config,?PER,[optimize]),
    ?line testParamBasic_cases(?PER).


testParamBasic_cases(Rules) ->
    ?line testParamBasic:main(Rules).

testSetExtension(suite) -> [];
testSetExtension(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testExternal:compile(Config,?BER,[]),
    ?line testSetExtension:compile(Config,?BER,[]),
    ?line testSetExtension_cases(?BER),

    ?line ?ber_driver(?BER,testExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetExtension:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetExtension_cases(?BER)).

testSetExtension_cases(Rules) ->
    ?line testSetExtension:main(Rules).


testSetExternal(suite) -> [];
testSetExternal(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testExternal:compile(Config,?BER,[]),
    ?line testSetExternal:compile(Config,?BER,[]),
    ?line testSetExternal_cases(?BER),

    ?line ?ber_driver(?BER,testExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetExternal_cases(?BER)).

testSetExternal_cases(Rules) ->
    ?line testSetExternal:main(Rules).


testSetOptional(suite) -> [];
testSetOptional(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSetOptional:compile(Config,?BER,[]),
    ?line testSetOptional_cases(?BER),

    ?line ?ber_driver(?BER,testSetOptional:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetOptional_cases(?BER)),

    ?line testSetOptional:compile(Config,?PER,[]), 
    ?line testSetOptional_cases(?PER),

    ?line ?per_bit_opt(testSetOptional:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSetOptional_cases(?PER)),

    ?line ?uper_bin(testSetOptional:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSetOptional_cases(uper_bin)),

    ?line testSetOptional:compile(Config,?PER,[optimize]), 
    ?line testSetOptional_cases(?PER).

testSetOptional_cases(Rules) ->
    ?line ok = testSetOptional:ticket_7533(Rules),
    ?line ok = testSetOptional:main(Rules).




testSetPrim(suite) -> [];
testSetPrim(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSetPrim:compile(Config,?BER,[]),
    ?line testSetPrim_cases(?BER),

    ?line ?ber_driver(?BER,testSetPrim:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetPrim_cases(?BER)),

    ?line testSetPrim:compile(Config,?PER,[]), 
    ?line testSetPrim_cases(?PER),

    ?line ?per_bit_opt(testSetPrim:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSetPrim_cases(?PER)),

    ?line ?uper_bin(testSetPrim:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSetPrim_cases(uper_bin)),

    ?line testSetPrim:compile(Config,?PER,[optimize]), 
    ?line testSetPrim_cases(?PER).

testSetPrim_cases(Rules) ->
    ?line testSetPrim:main(Rules).



testSetTag(suite) -> [];
testSetTag(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testExternal:compile(Config,?BER,[]),
    ?line testSetTag:compile(Config,?BER,[]),
    ?line testSetTag_cases(?BER),

    ?line ?ber_driver(?BER,testExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetTag:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetTag_cases(?BER)),

    ?line testExternal:compile(Config,?PER,[]),
    ?line testSetTag:compile(Config,?PER,[]), 
    ?line testSetTag_cases(?PER),

    ?line ?per_bit_opt(testExternal:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testSetTag:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSetTag_cases(?PER)),

    ?line ?uper_bin(testExternal:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testSetTag:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSetTag_cases(uper_bin)),

    ?line testExternal:compile(Config,?PER,[optimize]),
    ?line testSetTag:compile(Config,?PER,[optimize]), 
    ?line testSetTag_cases(?PER).

testSetTag_cases(Rules) ->
    ?line testSetTag:main(Rules).



testSetTypeRefCho(suite) -> [];
testSetTypeRefCho(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSetTypeRefCho:compile(Config,?BER,[]),
    ?line testSetTypeRefCho_cases(?BER),

    ?line ?ber_driver(?BER,testSetTypeRefCho:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetTypeRefCho_cases(?BER)),

    ?line testSetTypeRefCho:compile(Config,?PER,[]), 
    ?line testSetTypeRefCho_cases(?PER),

    ?line ?per_bit_opt(testSetTypeRefCho:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSetTypeRefCho_cases(?PER)),

    ?line ?uper_bin(testSetTypeRefCho:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSetTypeRefCho_cases(uper_bin)),

    ?line testSetTypeRefCho:compile(Config,?PER,[optimize]), 
    ?line testSetTypeRefCho_cases(?PER).

testSetTypeRefCho_cases(Rules) ->
    ?line testSetTypeRefCho:main(Rules).



testSetTypeRefPrim(suite) -> [];
testSetTypeRefPrim(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSetTypeRefPrim:compile(Config,?BER,[]),
    ?line testSetTypeRefPrim_cases(?BER),

    ?line ?ber_driver(?BER,testSetTypeRefPrim:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetTypeRefPrim_cases(?BER)),

    ?line testSetTypeRefPrim:compile(Config,?PER,[]), 
    ?line testSetTypeRefPrim_cases(?PER),

    ?line ?per_bit_opt(testSetTypeRefPrim:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSetTypeRefPrim_cases(?PER)),

    ?line ?uper_bin(testSetTypeRefPrim:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSetTypeRefPrim_cases(uper_bin)),

    ?line testSetTypeRefPrim:compile(Config,?PER,[optimize]), 
    ?line testSetTypeRefPrim_cases(?PER).

testSetTypeRefPrim_cases(Rules) ->
    ?line testSetTypeRefPrim:main(Rules).



testSetTypeRefSeq(suite) -> [];
testSetTypeRefSeq(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSetTypeRefSeq:compile(Config,?BER,[]),
    ?line testSetTypeRefSeq_cases(?BER),

    ?line ?ber_driver(?BER,testSetTypeRefSeq:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetTypeRefSeq_cases(?BER)),

    ?line testSetTypeRefSeq:compile(Config,?PER,[]), 
    ?line testSetTypeRefSeq_cases(?PER),

    ?line ?per_bit_opt(testSetTypeRefSeq:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSetTypeRefSeq_cases(?PER)),

    ?line ?uper_bin(testSetTypeRefSeq:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSetTypeRefSeq_cases(uper_bin)),

    ?line testSetTypeRefSeq:compile(Config,?PER,[optimize]), 
    ?line testSetTypeRefSeq_cases(?PER).

testSetTypeRefSeq_cases(Rules) ->
    ?line testSetTypeRefSeq:main(Rules).



testSetTypeRefSet(suite) -> [];
testSetTypeRefSet(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSetTypeRefSet:compile(Config,?BER,[]),
    ?line testSetTypeRefSet_cases(?BER),

    ?line ?ber_driver(?BER,testSetTypeRefSet:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetTypeRefSet_cases(?BER)),

    ?line testSetTypeRefSet:compile(Config,?PER,[]), 
    ?line testSetTypeRefSet_cases(?PER),

    ?line ?per_bit_opt(testSetTypeRefSet:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSetTypeRefSet_cases(?PER)),

    ?line ?uper_bin(testSetTypeRefSet:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSetTypeRefSet_cases(uper_bin)),

    ?line testSetTypeRefSet:compile(Config,?PER,[optimize]), 
    ?line testSetTypeRefSet_cases(?PER).

testSetTypeRefSet_cases(Rules) ->
    ?line testSetTypeRefSet:main(Rules).



testSetOf(suite) -> [];
testSetOf(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSetOf:compile(Config,?BER,[]),
    ?line testSetOf_cases(?BER),

    ?line ?ber_driver(?BER,testSetOf:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetOf_cases(?BER)),

    ?line testSetOf:compile(Config,?PER,[]), 
    ?line testSetOf_cases(?PER),

    ?line ?per_bit_opt(testSetOf:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSetOf_cases(?PER)),

    ?line ?uper_bin(testSetOf:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSetOf_cases(uper_bin)),

    ?line testSetOf:compile(Config,?PER,[optimize]), 
    ?line testSetOf_cases(?PER).

testSetOf_cases(Rules) ->
    ?line testSetOf:main(Rules).



testSetOfCho(suite) -> [];
testSetOfCho(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSetOfCho:compile(Config,?BER,[]),
    ?line testSetOfCho_cases(?BER),

    ?line ?ber_driver(?BER,testSetOfCho:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetOfCho_cases(?BER)),

    ?line testSetOfCho:compile(Config,?PER,[]), 
    ?line testSetOfCho_cases(?PER),

    ?line ?per_bit_opt(testSetOfCho:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSetOfCho_cases(?PER)),

    ?line ?uper_bin(testSetOfCho:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSetOfCho_cases(uper_bin)),

    ?line testSetOfCho:compile(Config,?PER,[optimize]), 
    ?line testSetOfCho_cases(?PER).

testSetOfCho_cases(Rules) ->
    ?line testSetOfCho:main(Rules).


testSetOfExternal(suite) -> [];
testSetOfExternal(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testExternal:compile(Config,?BER,[]),
    ?line testSetOfExternal:compile(Config,?BER,[]),
    ?line testSetOfExternal_cases(?BER),

    ?line ?ber_driver(?BER,testExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetOfExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetOfExternal_cases(?BER)),

    ?line testExternal:compile(Config,?PER,[]),
    ?line testSetOfExternal:compile(Config,?PER,[]), 
    ?line testSetOfExternal_cases(?PER),

    ?line ?per_bit_opt(testExternal:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testSetOfExternal:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSetOfExternal_cases(?PER)),

    ?line ?uper_bin(testExternal:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testSetOfExternal:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSetOfExternal_cases(uper_bin)),

    ?line testExternal:compile(Config,?PER,[optimize]),
    ?line testSetOfExternal:compile(Config,?PER,[optimize]), 
    ?line testSetOfExternal_cases(?PER).

testSetOfExternal_cases(Rules) ->
    ?line testSetOfExternal:main(Rules).




testSetOfTag(suite) -> [];
testSetOfTag(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testExternal:compile(Config,?BER,[]),
    ?line testSetOfTag:compile(Config,?BER,[]),
    ?line testSetOfTag_cases(?BER),

    ?line ?ber_driver(?BER,testExternal:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetOfTag:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetOfTag_cases(?BER)),

    ?line testExternal:compile(Config,?PER,[]),
    ?line testSetOfTag:compile(Config,?PER,[]), 
    ?line testSetOfTag_cases(?PER),

    ?line ?per_bit_opt(testExternal:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testSetOfTag:compile(Config,?PER,[optimize])), 
    ?line ?per_bit_opt(testSetOfTag_cases(?PER)),

    ?line ?uper_bin(testExternal:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testSetOfTag:compile(Config,uper_bin,[])), 
    ?line ?uper_bin(testSetOfTag_cases(uper_bin)),

    ?line testExternal:compile(Config,?PER,[optimize]),
    ?line testSetOfTag:compile(Config,?PER,[optimize]), 
    ?line testSetOfTag_cases(?PER).

testSetOfTag_cases(Rules) ->
    ?line testSetOfTag:main(Rules).


c_syntax(suite) -> [];
c_syntax(Config) ->
    ?line DataDir%    ?line testExternal:compile(Config,?PER),     
%    ?line testPrimExternal:compile(Config,?PER), 
%    ?line testPrimExternal_cases(?PER).          
 = ?config(data_dir,Config),
    ?line _TempDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),
    ?line {error,_R1} = asn1ct:compile(filename:join(DataDir,"Syntax")),
    ?line {error,_R2} = asn1ct:compile(filename:join(DataDir,"BadTypeEnding")),
    ?line {error,_R3} = asn1ct:compile(filename:join(DataDir,
						    "BadValueAssignment1")),
    ?line {error,_R4} = asn1ct:compile(filename:join(DataDir,
                                                    "BadValueAssignment2")),
    ?line {error,_R5} = asn1ct:compile(filename:join(DataDir,
						    "BadValueSet")),
    ?line {error,_R6} = asn1ct:compile(filename:join(DataDir,
						    "ChoiceBadExtension")),
    ?line {error,_R7} = asn1ct:compile(filename:join(DataDir,
						"EnumerationBadExtension")),
    ?line {error,_R8} = asn1ct:compile(filename:join(DataDir,
						    "Example")),
    ?line {error,_R9} = asn1ct:compile(filename:join(DataDir,
						    "Export1")),
    ?line {error,_R10} = asn1ct:compile(filename:join(DataDir,
						     "MissingEnd")),
    ?line {error,_R11} = asn1ct:compile(filename:join(DataDir,
						     "SequenceBadComma")),
    ?line {error,_R12} = asn1ct:compile(filename:join(DataDir,
						"SequenceBadComponentName")),
    ?line {error,_R13} = asn1ct:compile(filename:join(DataDir,
						"SequenceBadComponentType")),
    ?line {error,_R14} = asn1ct:compile(filename:join(DataDir,
						"SeqBadComma")).


c_string_per(suite) -> [];
c_string_per(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line TempDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),
    ?line ok = asn1ct:compile(filename:join(DataDir,"String"),[?PER,{outdir,TempDir}]).

c_string_ber(suite) -> [];
c_string_ber(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line TempDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),
    ?line ok = asn1ct:compile(filename:join(DataDir,"String"),[?BER,{outdir,TempDir}]).


c_implicit_before_choice(suite) -> [];
c_implicit_before_choice(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line TempDir = ?config(priv_dir,Config),
    ?line {error,_R2} = asn1ct:compile(filename:join(DataDir,"CCSNARG3"),[?BER,{outdir,TempDir}]).

parse(suite) -> [];
parse(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line OutDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),
    M1 = test_modules(),
%    M2 = parse_modules(),
    ?line ok = parse1(M1,DataDir,OutDir).

parse1([M|T],DataDir,OutDir) ->
    ?line ok = asn1ct:compile(DataDir ++ M,[abs,{outdir,OutDir}]),
    parse1(T,DataDir,OutDir);
parse1([],_,_) ->
    ok.

per(suite) -> [];
per(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line OutDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),
    ?line ok = per1(per_modules(),DataDir,OutDir),
    ?line ?per_bit_opt(per1_bit_opt(per_modules(),DataDir,OutDir)),
    ?line ok = per1_opt(per_modules(),DataDir,OutDir).


per1([M|T],DataDir,OutDir) ->
    ?line ok = asn1ct:compile(DataDir ++ M,[?PER,{outdir,OutDir}]),
    ?line ok = asn1ct:test(list_to_atom(M)),
    per1(T,DataDir,OutDir);
per1([],_,_) ->
    ok.

per1_bit_opt([M|T],DataDir,OutDir) ->
    ?line ok = asn1ct:compile(DataDir ++ M,[?PER,optimize,{outdir,OutDir}]),
    ?line ok = asn1ct:test(list_to_atom(M)),
    per1_bit_opt(T,DataDir,OutDir);
per1_bit_opt([],_,_) ->
    ok.

per1_opt([M|T],DataDir,OutDir) ->
    ?line ok = asn1ct:compile(DataDir ++ M,[?PER,optimized,{outdir,OutDir}]),
    ?line ok = asn1ct:test(list_to_atom(M)),
    per1_opt(T,DataDir,OutDir);
per1_opt([],_,_) ->
    ok.


ber_choiceinseq(suite) ->[];
ber_choiceinseq(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line OutDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),
    ?line ok = asn1ct:compile(filename:join(DataDir,"ChoiceInSeq"),[?BER,{outdir,OutDir}]).

ber_optional(suite) ->[];
ber_optional(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line OutDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),
    ?line ok = asn1ct:compile(filename:join(DataDir,"SOpttest"),[?BER,{outdir,OutDir}]),
    ?line V = {'S',{'A',10,asn1_NOVALUE,asn1_NOVALUE},
	 {'B',asn1_NOVALUE,asn1_NOVALUE,asn1_NOVALUE},
	 {'C',asn1_NOVALUE,111,asn1_NOVALUE}},
    ?line {ok,B} = asn1_wrapper:encode('SOpttest','S',V),
    ?line Bytes = lists:flatten(B),
    ?line V2 = asn1_wrapper:decode('SOpttest','S',Bytes),
    ?line ok = eq(V,element(2,V2)).

ber_optional_keyed_list(suite) ->[];
ber_optional_keyed_list(Config) ->
    case ?BER of
	ber_bin_v2 -> ok;
	_ ->
    	   ?line DataDir = ?config(data_dir,Config),
    	   ?line OutDir = ?config(priv_dir,Config),
    	   ?line true = code:add_patha(?config(priv_dir,Config)),
    	   ?line ok = asn1ct:compile(filename:join(DataDir,"SOpttest"),
			      [?BER,keyed_list,{outdir,OutDir}]),
    	   ?line Vrecord = {'S',{'A',10,asn1_NOVALUE,asn1_NOVALUE},
	      {'B',asn1_NOVALUE,asn1_NOVALUE,asn1_NOVALUE},
	      {'C',asn1_NOVALUE,111,asn1_NOVALUE}},
    	   ?line V = [ {a,[{scriptKey,10}]},
		       {b,[]},
		       {c,[{callingPartysCategory,111}]} ],
    	   ?line {ok,B} = asn1_wrapper:encode('SOpttest','S',V),
    	   ?line Bytes = lists:flatten(B),
    	   ?line V2 = asn1_wrapper:decode('SOpttest','S',Bytes),
    	   ?line ok = eq(Vrecord,element(2,V2))
    end.


eq(V,V) ->
    ok.


ber_other(suite) ->[];
ber_other(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line OutDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),
    ?line ok = ber1(ber_modules(),DataDir,OutDir).


ber1([M|T],DataDir,OutDir) ->
    ?line ok = asn1ct:compile(DataDir ++ M,[?BER,{outdir,OutDir}]),
    ?line ok = asn1ct:test(list_to_atom(M)),
    ber1(T,DataDir,OutDir);
ber1([],_,_) ->
    ok.

default_per(suite) ->[];
default_per(Config) ->
    default1(?PER,Config,[]).

default_per_opt(suite) -> [];
default_per_opt(Config) ->
    ?per_bit_opt(default1(?PER,Config,[optimize])),
    default1(?PER,Config,[optimize]).

default_ber(suite) ->[];
default_ber(Config) ->
    default1(?BER,Config,[]).

default1(Rule,Config,Options) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line OutDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),
    ?line ok = asn1ct:compile(DataDir ++ "Def",[Rule,{outdir,OutDir}]++Options),
    ?line {ok,Bytes1} = asn1_wrapper:encode('Def','Def1',#'Def1'{bool0 = true,
						 bool1 = true,
						 bool2 = true,
						 bool3 = true}),
    ?line {ok,{'Def1',true,true,true,true}} = asn1_wrapper:decode('Def','Def1',lists:flatten(Bytes1)),
    
    ?line {ok,Bytes2} = asn1_wrapper:encode('Def','Def1',#'Def1'{bool0 = true}),
    ?line {ok,{'Def1',true,false,false,false}} = asn1_wrapper:decode('Def','Def1',lists:flatten(Bytes2)),

    ?line {ok,Bytes3} = asn1_wrapper:encode('Def','Def1',#'Def1'{bool0 = true,bool2=false}),
    ?line {ok,{'Def1',true,false,false,false}} = asn1_wrapper:decode('Def','Def1',lists:flatten(Bytes3)).
    
    
value_test(suite) ->[];
value_test(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line OutDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),
    ?line ok = asn1ct:compile(DataDir ++ "ObjIdValues",[?BER,{outdir,OutDir}]),
    ?line {ok,_} = asn1_wrapper:encode('ObjIdValues','ObjIdType','ObjIdValues':'mobileDomainId'()),
    ?line ok = asn1ct:compile(DataDir ++ "ObjIdValues",[?PER,{outdir,OutDir}]),
    ?line {ok,_} = asn1_wrapper:encode('ObjIdValues','ObjIdType','ObjIdValues':'mobileDomainId'()),
    ?line ok = test_bad_values:tests(Config),
    ok.


constructed(suite) ->
     [];
constructed(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line OutDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),
    ?line ok = asn1ct:compile(DataDir ++ "Constructed",[?BER,{outdir,OutDir}]),
    ?line {ok,B} = asn1_wrapper:encode('Constructed','S',{'S',false}),
    ?line [40,3,1,1,0] = lists:flatten(B),
    ?line {ok,B1} = asn1_wrapper:encode('Constructed','S2',{'S2',false}),
    ?line [40,5,48,3,1,1,0] = lists:flatten(B1),
    ?line {ok,B2} = asn1_wrapper:encode('Constructed','I',10),
    ?line [136,1,10] = lists:flatten(B2),
    ok.
    
ber_decode_error(suite) -> [];
ber_decode_error(Config) ->
    ?line ok = ber_decode_error:compile(Config,?BER,[]),
    ?line ok = ber_decode_error:run([]),

    ?line ok = ?ber_driver(?BER,ber_decode_error:compile(Config,?BER,[driver])),
    ?line ok = ?ber_driver(?BER,ber_decode_error:run([driver])),
	ok.   

h323test(suite) -> 
    [];
h323test(Config) ->
    ?line ok = h323test:compile(Config,?PER,[]),
    ?line ok = h323test:run(?PER),
    ?line ?per_bit_opt(h323test:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(h323test:run(?PER)),
    ?line ?uper_bin(h323test:compile(Config,uper_bin,[])),
    ?line ?uper_bin(h323test:run(uper_bin)),
    ?line ok = h323test:compile(Config,?PER,[optimize]),
    ?line ok = h323test:run(?PER),
    ok.

per_GeneralString(suite) ->
     [];
per_GeneralString(Config) ->
    case erlang:module_loaded('MULTIMEDIA-SYSTEM-CONTROL') of
	true ->
	    ok;
	false ->
	    h323test:compile(Config,?PER,[])
    end,
    UI = [109,64,1,57],
    ?line {ok,_V} = asn1_wrapper:decode('MULTIMEDIA-SYSTEM-CONTROL',
				 'MultimediaSystemControlMessage',UI).

per_open_type(suite) ->
    [];
per_open_type(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line OutDir = ?config(priv_dir,Config),
    ?line ok = asn1ct:compile(DataDir ++ "OpenType",[?PER,{outdir,OutDir}]),
    Stype = {'Stype',10,true},
    ?line {ok,Bytes} = asn1_wrapper:encode('OpenType','Ot',Stype),
    ?line {ok,Stype} = asn1_wrapper:decode('OpenType','Ot',Bytes),

    ?line ?per_bit_opt(ok = asn1ct:compile(DataDir ++ "OpenType",
			      [?PER,optimize,{outdir,OutDir}])),
    ?line ?per_bit_opt({ok,Bytes}=asn1_wrapper:encode('OpenType','Ot',Stype)),
    ?line ?per_bit_opt({ok,Stype}=asn1_wrapper:decode('OpenType','Ot',Bytes)),

    ?line ?uper_bin(ok = asn1ct:compile(DataDir ++ "OpenType",
			      [uper_bin,{outdir,OutDir}])),
    ?line ?uper_bin({ok,Bytes}=asn1_wrapper:encode('OpenType','Ot',Stype)),
    ?line ?uper_bin({ok,Stype}=asn1_wrapper:decode('OpenType','Ot',Bytes)),

    ?line ok = asn1ct:compile(DataDir ++ "OpenType",
			      [?PER,optimize,{outdir,OutDir}]),
    ?line {ok,Bytes} = asn1_wrapper:encode('OpenType','Ot',Stype),
    ?line {ok,Stype} = asn1_wrapper:decode('OpenType','Ot',Bytes).

testConstraints(suite) ->
	[];
testConstraints(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testConstraints:compile(Config,?BER,[]),
    ?line testConstraints:int_constraints(?BER),

    ?line ?ber_driver(?BER,testConstraints:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testConstraints:int_constraints(?BER)),

    ?line testConstraints:compile(Config,?PER,[]),
    ?line testConstraints:int_constraints(?PER),
    ?line testConstraints:refed_NNL_name(?PER),

    ?line ?per_bit_opt(testConstraints:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testConstraints:int_constraints(?PER)),
    ?line ?per_bit_opt(testConstraints:refed_NNL_name(?PER)),

    ?line ?uper_bin(testConstraints:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testConstraints:int_constraints(uper_bin)),
    ?line ?uper_bin(testConstraints:refed_NNL_name(uper_bin)),

    ?line testConstraints:compile(Config,?PER,[optimize]),
    ?line testConstraints:int_constraints(?PER),
    ?line testConstraints:refed_NNL_name(?PER).

testSeqIndefinite(suite) -> [];
testSeqIndefinite(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSeqIndefinite:compile(Config,?BER,[]),
    ?line testSeqIndefinite:main(?BER),

    ?line ?ber_driver(?BER,testSeqIndefinite:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSeqIndefinite:main(?BER)).

testSetIndefinite(suite) -> [];
testSetIndefinite(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testSetIndefinite:compile(Config,?BER,[]),
    ?line testSetIndefinite:main(?BER),

    ?line ?ber_driver(?BER,testSetIndefinite:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testSetIndefinite:main(?BER)).

testChoiceIndefinite(suite) -> [];
testChoiceIndefinite(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testChoiceIndefinite:compile(Config,?BER,[]),
    ?line testChoiceIndefinite:main(?BER),

    ?line ?ber_driver(?BER,testChoiceIndefinite:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testChoiceIndefinite:main(?BER)).

testInfObjectClass(suite) ->
    [];
testInfObjectClass(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),
    
    ?line testInfObjectClass:compile(Config,?PER,[]),
    ?line testInfObjectClass:main(?PER),
    ?line testInfObj:compile(Config,?PER,[]),
    ?line testInfObj:main(?PER),

    ?line ?per_bit_opt(testInfObjectClass:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testInfObjectClass:main(?PER)),
    ?line ?per_bit_opt(testInfObj:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testInfObj:main(?PER)),

    ?line ?uper_bin(testInfObjectClass:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testInfObjectClass:main(uper_bin)),
    ?line ?uper_bin(testInfObj:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testInfObj:main(uper_bin)),

    ?line testInfObjectClass:compile(Config,?PER,[optimize]),
    ?line testInfObjectClass:main(?PER),
    ?line testInfObj:compile(Config,?PER,[optimize]),
    ?line testInfObj:main(?PER),

    ?line testInfObjectClass:compile(Config,?BER,[]),
    ?line testInfObjectClass:main(?BER),
    ?line testInfObj:compile(Config,?BER,[]),
    ?line testInfObj:main(?BER),

    ?line ?ber_driver(?BER,testInfObjectClass:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testInfObjectClass:main(?BER)),
    ?line ?ber_driver(?BER,testInfObj:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testInfObj:main(?BER)),

    ?line testInfObj:compile_RANAPfiles(Config,?PER,[]),

    ?line ?per_bit_opt(testInfObj:compile_RANAPfiles(Config,?PER,[optimize])),

    ?line ?uper_bin(testInfObj:compile_RANAPfiles(Config,uper_bin,[])),

    ?line testInfObj:compile_RANAPfiles(Config,?PER,[optimize]),

    ?line testInfObj:compile_RANAPfiles(Config,?BER,[]).

testParameterizedInfObj(suite) ->
    [];
testParameterizedInfObj(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),
    
    ?line testParameterizedInfObj:compile(Config,?PER,[]),
    ?line testParameterizedInfObj:main(?PER),

    ?line ?per_bit_opt(testParameterizedInfObj:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testParameterizedInfObj:main(?PER)),

    ?line ?uper_bin(testParameterizedInfObj:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testParameterizedInfObj:main(uper_bin)),

    ?line testParameterizedInfObj:compile(Config,?PER,[optimize]),
    ?line testParameterizedInfObj:main(?PER),

    ?line testParameterizedInfObj:compile(Config,?BER,[]),
    ?line testParameterizedInfObj:main(?BER),

    ?line ?ber_driver(?BER,testParameterizedInfObj:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testParameterizedInfObj:main(?BER)).

testMergeCompile(suite) ->
    [];
testMergeCompile(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),
    
    ?line testMergeCompile:compile(Config,?PER,[]),
    ?line testMergeCompile:main(?PER),
    ?line testMergeCompile:mvrasn(?PER),

    ?line ?per_bit_opt(testMergeCompile:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testMergeCompile:main(?PER)),
    ?line ?per_bit_opt(testMergeCompile:mvrasn(?PER)),

    ?line ?uper_bin(testMergeCompile:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testMergeCompile:main(uper_bin)),
    ?line ?uper_bin(testMergeCompile:mvrasn(uper_bin)),

    ?line testMergeCompile:compile(Config,?BER,[]),
    ?line testMergeCompile:main(?BER),
    ?line testMergeCompile:mvrasn(?BER),

    ?line ?ber_driver(?BER,testMergeCompile:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testMergeCompile:main(?BER)),
    ?line ?ber_driver(?BER,testMergeCompile:mvrasn(?BER)).

testobj(suite) ->
    [];
testobj(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),
    
    ?line ok = testRANAP:compile(Config,?PER,[]),
    ?line ok = testRANAP:testobj(?PER),
    ?line ok = testParameterizedInfObj:ranap(?PER),
    
    ?line ?per_bit_opt(ok = testRANAP:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(ok = testRANAP:testobj(?PER)),
    ?line ?per_bit_opt(ok = testParameterizedInfObj:ranap(?PER)),
    
    ?line ?uper_bin(ok = testRANAP:compile(Config,uper_bin,[])),
    ?line ?uper_bin(ok = testRANAP:testobj(uper_bin)),
    ?line ?uper_bin(ok = testParameterizedInfObj:ranap(uper_bin)),
    
    ?line ok = testRANAP:compile(Config,?PER,[optimize]),
    ?line ok = testRANAP:testobj(?PER),
    ?line ok = testParameterizedInfObj:ranap(?PER),

    ?line ok = testRANAP:compile(Config,?BER,[]),
    ?line ok = testRANAP:testobj(?BER),
    ?line ok = testParameterizedInfObj:ranap(?BER),

    ?line ?ber_driver(?BER,testRANAP:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testRANAP:testobj(?BER)),
    ?line ?ber_driver(?BER,testParameterizedInfObj:ranap(?BER)).


testDeepTConstr(suite) ->
    [];
testDeepTConstr(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testDeepTConstr:compile(Config,?PER,[]),
    ?line testDeepTConstr:main(?PER),

    ?line ?per_bit_opt(testDeepTConstr:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testDeepTConstr:main(?PER)),

    ?line ?uper_bin(testDeepTConstr:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testDeepTConstr:main(uper_bin)),

    ?line testDeepTConstr:compile(Config,?PER,[optimize]),
    ?line testDeepTConstr:main(?PER),

    ?line testDeepTConstr:compile(Config,?BER,[]),
    ?line testDeepTConstr:main(?BER),

    ?line ?ber_driver(?BER,testDeepTConstr:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testDeepTConstr:main(?BER)).

testInvokeMod(suite) ->
    [];
testInvokeMod(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line OutDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line ok = asn1ct:compile(filename:join(DataDir,"PrimStrings"),[{outdir,OutDir}]),
    ?line {ok,_Result1} = 'PrimStrings':encode('Bs1',[1,0,1,0]),
    ?line ok = asn1ct:compile(filename:join(DataDir,"PrimStrings"),[?PER,{outdir,OutDir}]),
    ?line {ok,_Result2} = 'PrimStrings':encode('Bs1',[1,0,1,0]).

testExport(suite) ->
    [];
testExport(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line OutDir = ?config(priv_dir,Config),
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line {error,{asn1,_Reason}} = asn1ct:compile(filename:join(DataDir,"IllegalExport"),[{outdir,OutDir}]).

testImport(suite) ->
    [];
testImport(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line _OutDir = ?config(priv_dir,Config),
    ?line {error,_} = asn1ct:compile(filename:join(DataDir,"ImportsFrom"),[?BER]),
    ok.

testMegaco(suite) ->
    [];
testMegaco(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),
    io:format("Config: ~p~n",[Config]),
    ?line {ok,ModuleName1,ModuleName2} = testMegaco:compile(Config,?BER,[]),
    ?line ok = testMegaco:main(ModuleName1,Config),
    ?line ok = testMegaco:main(ModuleName2,Config),

    case ?BER of
	ber_bin_v2 ->
	    ?line {ok,ModuleName3,ModuleName4} = testMegaco:compile(Config,?BER,[driver]),
	    ?line ok = testMegaco:main(ModuleName3,Config),
	    ?line ok = testMegaco:main(ModuleName4,Config);
	_-> ok
    end,

    ?line {ok,ModuleName5,ModuleName6} = testMegaco:compile(Config,?PER,[]),
    ?line ok = testMegaco:main(ModuleName5,Config),
    ?line ok = testMegaco:main(ModuleName6,Config),

    ?line ?per_bit_opt({ok,ModuleName5,ModuleName6} = testMegaco:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(ok = testMegaco:main(ModuleName5,Config)),
    ?line ?per_bit_opt(ok = testMegaco:main(ModuleName6,Config)),

    ?line ?uper_bin({ok,ModuleName5,ModuleName6} = testMegaco:compile(Config,uper_bin,[])),
    ?line ?uper_bin(ok = testMegaco:main(ModuleName5,Config)),
    ?line ?uper_bin(ok = testMegaco:main(ModuleName6,Config)),

    ?line {ok,ModuleName7,ModuleName8} = testMegaco:compile(Config,?PER,[optimize]),
    ?line ok = testMegaco:main(ModuleName7,Config),
    ?line ok = testMegaco:main(ModuleName8,Config).


testMvrasn6(suite) -> [];
testMvrasn6(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testMvrasn6:compile(Config,?BER),
    ?line testMvrasn6:main().

testContextSwitchingTypes(suite) -> [];
testContextSwitchingTypes(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testContextSwitchingTypes:compile(Config,?BER,[]),
    ?line testContextSwitchingTypes:test(),

    ?line ?ber_driver(?BER,testContextSwitchingTypes:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testContextSwitchingTypes:test()),

    ?line testContextSwitchingTypes:compile(Config,?PER,[]),
    ?line testContextSwitchingTypes:test(),

    ?line ?per_bit_opt(testContextSwitchingTypes:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testContextSwitchingTypes:test()),

    ?line ?uper_bin(testContextSwitchingTypes:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testContextSwitchingTypes:test()),

    ?line testContextSwitchingTypes:compile(Config,?PER,[optimize]),
    ?line testContextSwitchingTypes:test().

testTypeValueNotation(suite) -> [];
testTypeValueNotation(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    case ?BER of
	Ber when Ber == ber; Ber == ber_bin ->
	    ?line testTypeValueNotation:compile(Config,?BER,[]),
	    ?line testTypeValueNotation:main(?BER,dummy);
	_ ->
	    ok
    end,

    ?line ?ber_driver(?BER,testTypeValueNotation:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testTypeValueNotation:main(?BER,optimize)),

    case ?BER of
	Ber2 when Ber2 == ber; Ber2 == ber_bin ->
	    ?line testTypeValueNotation:compile(Config,?PER,[]),
	    ?line testTypeValueNotation:main(?PER,dummy);
	_ ->
	    ok
    end,

    ?line ?per_bit_opt(testTypeValueNotation:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testTypeValueNotation:main(?PER,optimize)),

    ?line ?uper_bin(testTypeValueNotation:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testTypeValueNotation:main(uper_bin,optimize)),
    case ?BER of
	Ber3 when Ber3 == ber; Ber3 == ber_bin ->
	    ?line testTypeValueNotation:compile(Config,?PER,[optimize]),
	    ?line testTypeValueNotation:main(?PER,optimize);
	_ ->
	    ok
     end.

testOpenTypeImplicitTag(suite) -> [];
testOpenTypeImplicitTag(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testOpenTypeImplicitTag:compile(Config,?BER,[]),
    ?line testOpenTypeImplicitTag:main(?BER),

    ?line ?ber_driver(?BER,testOpenTypeImplicitTag:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testOpenTypeImplicitTag:main(?BER)),

    ?line testOpenTypeImplicitTag:compile(Config,?PER,[]),
    ?line testOpenTypeImplicitTag:main(?PER),

    ?line ?per_bit_opt(testOpenTypeImplicitTag:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testOpenTypeImplicitTag:main(?PER)),

    ?line ?uper_bin(testOpenTypeImplicitTag:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testOpenTypeImplicitTag:main(uper_bin)),

    ?line testOpenTypeImplicitTag:compile(Config,?PER,[optimize]),
    ?line testOpenTypeImplicitTag:main(?PER).

duplicate_tags(suite) -> [];
duplicate_tags(Config) ->
	?line DataDir = ?config(data_dir,Config),
	{error,{asn1,[{error,{type,_,_,'SeqOpt1Imp',{asn1,{duplicates_of_the_tags,_}}}}]}} = 
	asn1ct:compile(filename:join(DataDir,"SeqOptional2"),[abs]),
	ok.

rtUI(suite) -> [];
rtUI(Config) -> 
    ?line DataDir = ?config(data_dir,Config),
    ?line ok = asn1ct:compile(filename:join(DataDir,"Prim"),[?BER]),
    ?line {ok,_} = asn1rt:info('Prim'),

    ?line ok = asn1ct:compile(filename:join(DataDir,"Prim"),[?PER]),
    ?line {ok,_} = asn1rt:info('Prim'),

    ?line ok = asn1rt:load_driver(),
    ?line ok = asn1rt:load_driver(),
    ?line ok = asn1rt:unload_driver().

testROSE(suite) -> [];
testROSE(Config) -> 
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testROSE:compile(Config,?BER,[]),

    ?line testROSE:compile(Config,?PER,[]),
    ?line ?per_bit_opt(testROSE:compile(Config,?PER,[optimize])),
    ?line ?uper_bin(testROSE:compile(Config,uper_bin,[])),
    ?line testROSE:compile(Config,?PER,[optimize]).

testINSTANCE_OF(suite) -> [];
testINSTANCE_OF(Config) ->
    ?line testINSTANCE_OF:compile(Config,?BER,[]),
    ?line testINSTANCE_OF:main(?BER),

    ?line ?ber_driver(?BER,testINSTANCE_OF:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testINSTANCE_OF:main(?BER)),

    ?line testINSTANCE_OF:compile(Config,?PER,[]),
    ?line testINSTANCE_OF:main(?PER),

    ?line ?per_bit_opt(testINSTANCE_OF:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testINSTANCE_OF:main(?PER)),

    ?line ?uper_bin(testINSTANCE_OF:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testINSTANCE_OF:main(uper_bin)),

    ?line testINSTANCE_OF:compile(Config,?PER,[optimize]),
    ?line testINSTANCE_OF:main(?PER).

testTCAP(suite) -> [];
testTCAP(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testTCAP:compile(Config,?BER,[]),
    ?line testTCAP:test(?BER,Config),

    ?line ?ber_driver(?BER,testTCAP:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testTCAP:test(?BER,Config)),

    ?line ?ber_driver(?BER,testTCAP:compile_asn1config(Config,?BER,[asn1config])),
    ?line ?ber_driver(?BER,testTCAP:test_asn1config()).

testDER(suite) ->[];
testDER(Config) ->
    ?line true = code:add_patha(?config(priv_dir,Config)),

    ?line testDER:compile(Config,?BER,[]),
    ?line testDER:test(),

    ?line ?ber_driver(?BER,testDER:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testDER:test()),

    ?line testParamBasic:compile_der(Config,?BER),
    ?line testParamBasic_cases(der),


    ?line testSeqSetDefaultVal:compile(Config,?BER),
    ?line testSeqSetDefaultVal_cases(?BER).

testSeqSetDefaultVal_cases(?BER) ->
    ?line testSeqSetDefaultVal:main(?BER).


specialized_decodes(suite) -> [];
specialized_decodes(Config) ->
    ?line test_partial_incomplete_decode:compile(Config,?BER,[optimize]),
    ?line test_partial_incomplete_decode:test(?BER,Config),
    ?line test_selective_decode:test(?BER,Config).

special_decode_performance(suite) ->[];
special_decode_performance(Config) ->
    ?line ?ber_driver(?BER,test_special_decode_performance:compile(Config,?BER)),
    ?line ?ber_driver(?BER,test_special_decode_performance:go(all)).


test_driver_load(suite) -> [];
test_driver_load(Config) ->
    ?line test_driver_load:compile(Config,?PER),
    ?line test_driver_load:test(?PER,5).

test_ParamTypeInfObj(suite) -> [];
test_ParamTypeInfObj(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line ok = asn1ct:compile(filename:join(DataDir,"IN-CS-1-Datatypes"),[ber_bin]).

test_WS_ParamClass(suite) -> [];
test_WS_ParamClass(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line ok = asn1ct:compile(filename:join(DataDir,"InformationFramework"),
				[ber_bin]).

test_Defed_ObjectIdentifier(suite) -> [];
test_Defed_ObjectIdentifier(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line ok = asn1ct:compile(filename:join(DataDir,"UsefulDefinitions"),
				[ber_bin]).

testSelectionType(suite) -> [];
testSelectionType(Config) ->

    ?line ok = testSelectionTypes:compile(Config,?BER,[]),
    ?line {ok,_}  = testSelectionTypes:test(),

    ?line ok = testSelectionTypes:compile(Config,?PER,[]),
    ?line {ok,_}  = testSelectionTypes:test().

testSSLspecs(suite) -> [];
testSSLspecs(Config) ->

    ?line ok = testSSLspecs:compile(Config,?BER,
				[optimize,compact_bit_string,der]),
    ?line testSSLspecs:run(?BER),

    case code:which(asn1ct) of
       cover_compiled ->
	   ok;
       _ ->
           ?line ok = testSSLspecs:compile_inline(Config,?BER),
           ?line ok = testSSLspecs:run_inline(?BER)
    end.

testNortel(suite) -> [];
testNortel(Config) ->
    ?line DataDir = ?config(data_dir,Config),

    ?line ok = asn1ct:compile(filename:join(DataDir,"Nortel"),[?BER]),
    ?line ok = asn1ct:compile(filename:join(DataDir,"Nortel"),
				[?BER,optimize]),
    ?line ok = asn1ct:compile(filename:join(DataDir,"Nortel"),
				[?BER,optimize,driver]),
    ?line ok = asn1ct:compile(filename:join(DataDir,"Nortel"),[?PER]),
    ?line ?per_bit_opt(ok = asn1ct:compile(filename:join(DataDir,"Nortel"),
				[?PER,optimize])),
    ?line ?uper_bin(ok = asn1ct:compile(filename:join(DataDir,"Nortel"),[uper_bin])),
    ?line ok = asn1ct:compile(filename:join(DataDir,"Nortel"),
				[?PER,optimize]).
test_undecoded_rest(suite) -> [];
test_undecoded_rest(Config) ->

    ?line ok = test_undecoded_rest:compile(Config,?BER,[]),
    ?line ok = test_undecoded_rest:test([]),

    ?line ok = test_undecoded_rest:compile(Config,?BER,[undec_rest]),
    ?line ok = test_undecoded_rest:test(undec_rest),

    ?line ok = test_undecoded_rest:compile(Config,?PER,[]),
    ?line ok = test_undecoded_rest:test([]),

    ?line ?per_bit_opt(ok = test_undecoded_rest:compile(Config,?PER,[optimize,undec_rest])),
    ?line ?per_bit_opt(ok = test_undecoded_rest:test(undec_rest)),

    ?line ?uper_bin(ok = test_undecoded_rest:compile(Config,uper_bin,[undec_rest])),
    ?line ?uper_bin(ok = test_undecoded_rest:test(undec_rest)),

    ?line ok = test_undecoded_rest:compile(Config,?PER,[undec_rest]),
    ?line ok = test_undecoded_rest:test(undec_rest).

test_inline(suite) -> [];
test_inline(Config) ->
    case code:which(asn1ct) of
       cover_compiled ->
          {skip,"Not runnable when cover compiled"};
       _  ->
          ?line ok=test_inline:compile(Config,?BER,[]),
          ?line test_inline:main(?BER),
    	  ?line test_inline:inline1(Config,?BER,[]),
     	  ?line test_inline:performance2()
    end.

%test_inline_prf(suite) -> [];
%test_inline_prf(Config) ->
%    ?line test_inline:performance(Config).

testTcapsystem(suite) -> [];
testTcapsystem(Config) ->
    ?line ok=testTcapsystem:compile(Config,?BER,[]).

testNBAPsystem(suite) -> [];
testNBAPsystem(Config) ->
    ?line ok=testNBAPsystem:compile(Config,?PER,?per_optimize(?BER)),
    ?line ok=testNBAPsystem:test(?PER,Config).

test_compile_options(suite) -> [];
test_compile_options(Config) ->
    case code:which(asn1ct) of
       cover_compiled ->
          {skip,"Not runnable when cover compiled"};
       _  ->
    	  ?line ok = test_compile_options:wrong_path(Config),
    	  ?line ok = test_compile_options:path(Config),
    	  ?line ok = test_compile_options:noobj(Config),
	  ?line ok = test_compile_options:record_name_prefix(Config),
	  ?line ok = test_compile_options:verbose(Config)
    end.
testDoubleEllipses(suite) ->  [];
testDoubleEllipses(Config) ->
    ?line testDoubleEllipses:compile(Config,?BER,[]),
    ?line testDoubleEllipses:main(?BER),
    ?line ?ber_driver(?BER,testDoubleEllipses:compile(Config,?BER,[driver])),
    ?line ?ber_driver(?BER,testDoubleEllipses:main(?BER)),
    ?line ?per_bit_opt(testDoubleEllipses:compile(Config,?PER,[optimize])),
    ?line ?per_bit_opt(testDoubleEllipses:main(?PER)),
    ?line ?uper_bin(testDoubleEllipses:compile(Config,uper_bin,[])),
    ?line ?uper_bin(testDoubleEllipses:main(uper_bin)),
    ?line testDoubleEllipses:compile(Config,?PER,?per_optimize(?BER)),
    ?line testDoubleEllipses:main(?PER).

test_modified_x420(suite) -> [];
test_modified_x420(Config) ->
    ?line test_modified_x420:compile(Config),
    ?line test_modified_x420:test_io(Config).

testX420(suite) -> [];
testX420(Config) ->
    ?line testX420:compile(?BER,[der],Config),
    ?line ok = testX420:ticket7759(?BER,Config),
    ?line testX420:compile(?PER,[],Config).

test_x691(suite) -> [];
test_x691(Config) ->
    case ?PER of
	per ->
    	   ?line ok = test_x691:compile(Config,uper_bin,[]),
    	   ?line true = test_x691:cases(uper_bin,unaligned),
	   ?line ok = test_x691:compile(Config,?PER,[]),
    	   ?line true = test_x691:cases(?PER,aligned),
%%	   ?line ok = asn1_test_lib:ticket_7678(Config,[]),
	   ?line ok = asn1_test_lib:ticket_7708(Config,[]),
	   ?line ok = asn1_test_lib:ticket_7763(Config);
	_ ->
	   ?line ok = test_x691:compile(Config,?PER,?per_optimize(?BER)),
    	   ?line true = test_x691:cases(?PER,aligned)
    end.
%%    ?line ok = asn1_test_lib:ticket_7876(Config,?PER,[]),
%%    ?line ok = asn1_test_lib:ticket_7876(Config,?PER,[compact_bit_string]),
%%    ?line ok = asn1_test_lib:ticket_7876(Config,?PER,[optimize]),
%%    ?line ok = asn1_test_lib:ticket_7876(Config,?PER,[optimize,compact_bit_string]).


ticket_6143(suite) -> [];
ticket_6143(Config) ->
    ?line ok = test_compile_options:ticket_6143(Config).

testExtensionAdditionGroup(suite) -> [];
testExtensionAdditionGroup(Config) ->
	?line DataDir = ?config(data_dir,Config),
	?line PrivDir = ?config(priv_dir,Config),
	?line Path = code:get_path(),
	?line code:add_patha(PrivDir),
	DoIt = fun(Erule) ->
		?line ok = asn1ct:compile(filename:join(DataDir,"Extension-Addition-Group"),[Erule,{outdir,PrivDir}]),
		?line {ok,_M} = compile:file(filename:join(DataDir,"extensionAdditionGroup"),[{i,PrivDir},{outdir,PrivDir},debug_info]),
		?line ok = extensionAdditionGroup:run(Erule)
	       end,
	?line [DoIt(Rule)|| Rule <- [per_bin,uper_bin,ber_bin]],
	?line code:set_path(Path).



% parse_modules() ->
%	["ImportsFrom"].

per_modules() ->
	[X || X <- test_modules()].
ber_modules() ->
	[X || X <- test_modules(),
		X =/= "CommonDataTypes",
		X =/= "DS-EquipmentUser-CommonFunctionOrig-TransmissionPath",
		X =/= "H323-MESSAGES",
	        X =/= "H235-SECURITY-MESSAGES",
	        X =/= "MULTIMEDIA-SYSTEM-CONTROL"].
test_modules() ->
    _Modules = [
	       "BitStr",
	       "CommonDataTypes",
	       "Constraints",
	       "ContextSwitchingTypes",
	       "DS-EquipmentUser-CommonFunctionOrig-TransmissionPath",
	       "Enum",
	       "From",
	       "H235-SECURITY-MESSAGES",
	       "H323-MESSAGES",
	       %%"MULTIMEDIA-SYSTEM-CONTROL", recursive type , problem for asn1ct:value
	       "Import",
	       "Int",
	       "MAP-commonDataTypes",
% ambigous tags	       "MAP-insertSubscriberData-def",
	       "Null",
	       "Octetstr",
	       "One",
	       "P-Record",
	       "P",
%	       "PDUs",
	       "Person",
	       "PrimStrings",
	       "Real",
	       "XSeq",
	       "XSeqOf",
	       "XSet",
	       "XSetOf",
	       "String",
	       "SwCDR",
%	       "Syntax",
	       "Time"
% ANY	       "Tst",
%	       "Two",
% errors that should be detected      "UndefType"
] ++
	[
	 "SeqSetLib", % must be compiled before Seq and Set
	 "Seq",
	 "Set",
	 "SetOf",
	 "SeqOf",
	 "Prim",
	 "Cho",
	 "Def",
         "Opt",
	 "ELDAPv3",
	 "LDAP"
	].


%%
%% %CopyrightBegin%
%% 
%% Copyright Ericsson AB 2005-2010. All Rights Reserved.
%% 
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%% 
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% 
%% %CopyrightEnd%
%%
%%

common() -> 
[{group, app_test}, {group, appup_test}, testTimer_ber,
 testTimer_ber_bin, testTimer_ber_bin_opt,
 testTimer_ber_bin_opt_driver, testTimer_per,
 testTimer_per_bin, testTimer_per_bin_opt,
 testTimer_uper_bin, testComment, testName2Number].



testTimer_ber(suite) -> [];
testTimer_ber(Config) ->
    ?line testTimer:compile(Config,ber,[]),
    ?line testTimer:go(Config,ber).

testTimer_ber_bin(suite) -> [];
testTimer_ber_bin(Config) ->
    ?line testTimer:compile(Config,ber_bin,[]),
    ?line testTimer:go(Config,ber_bin).

testTimer_ber_bin_opt(suite) -> [];
testTimer_ber_bin_opt(Config) ->
    ?line testTimer:compile(Config,ber_bin,[optimize]),
    ?line testTimer:go(Config,ber_bin).

testTimer_ber_bin_opt_driver(suite) -> [];
testTimer_ber_bin_opt_driver(Config) ->
    ?line testTimer:compile(Config,ber_bin,[optimize,driver]),
    ?line testTimer:go(Config,ber_bin).

testTimer_per(suite) -> [];
testTimer_per(Config) ->
    ?line testTimer:compile(Config,per,[]),
    ?line testTimer:go(Config,per).

testTimer_per_bin(suite) -> [];
testTimer_per_bin(Config) ->
    ?line testTimer:compile(Config,per_bin,[]),
    ?line testTimer:go(Config,per_bin).

testTimer_per_bin_opt(suite) -> [];
testTimer_per_bin_opt(Config) ->
    ?line testTimer:compile(Config,per_bin,[optimize]),
    ?line testTimer:go(Config,per_bin).


testTimer_uper_bin(suite) -> [];
testTimer_uper_bin(Config) ->
    ?line ok=testTimer:compile(Config,uper_bin,[]),
    ?line {comment,_} = testTimer:go(Config,uper_bin).

%% Test of multiple-line comment, OTP-8043
testComment(suite) -> [];
testComment(Config) ->
    ?line DataDir = ?config(data_dir,Config),
    ?line OutDir = ?config(priv_dir,Config),

    ?line ok = asn1ct:compile(DataDir ++ "Comment",[{outdir,OutDir}]),

    ?line {ok,Enc} = asn1_wrapper:encode('Comment','Seq',{'Seq',12,true}),
    ?line {ok,{'Seq',12,true}} = asn1_wrapper:decode('Comment','Seq',Enc),
    ok.

testName2Number(suite) -> [];
testName2Number(Config) -> 
    DataDir = ?config(data_dir,Config),
    OutDir = ?config(priv_dir,Config),
    N2NOptions = [{n2n,Type}|| Type <- 
				   ['CauseMisc','CauseProtocol',
				    %% 'CauseNetwork',
				    'CauseRadioNetwork',
				    'CauseTransport','CauseNas']],
    ?line ok = asn1ct:compile(DataDir ++ "S1AP-IEs",[{outdir,OutDir}]++N2NOptions),
    ?line true = code:add_patha(OutDir),

    ?line 0 = 'S1AP-IEs':name2num_CauseMisc('control-processing-overload'),
    ?line 'unknown-PLMN' = 'S1AP-IEs':num2name_CauseMisc(5),
    ok.


particular() -> 
    [ticket_7407].

ticket_7407(suite) -> [];
ticket_7407(Config) ->
    ?line ok = asn1_test_lib:ticket_7407_compile(Config,[]),
    ?line ok = asn1_test_lib:ticket_7407_code(true),

    ?line ok = asn1_test_lib:ticket_7407_compile(Config,[no_final_padding]),
    ?line ok = asn1_test_lib:ticket_7407_code(false).
