/*
 * Copyright (C) 2020 spellcard199 <spellcard199@protonmail.com>
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

package kawageiser;

import gnu.expr.CompiledProc;
import gnu.expr.Language;
import gnu.kawa.functions.Format;
import gnu.kawa.lispexpr.LangObjType;
import gnu.lists.LList;
import gnu.mapping.Environment;
import gnu.mapping.Procedure;
import gnu.mapping.Symbol;
import kawadevutil.data.ParamData;
import kawadevutil.data.ProcDataGeneric;
import kawadevutil.data.ProcDataNonGeneric;
import kawadevutil.eval.EvalResult;
import kawadevutil.kawa.GnuMappingLocation;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

public class GeiserAutodoc {

    public static boolean showTypes = true;

    // TODO: Find the "right" way to get modules for symbols.
    // TODO: Support for macros (possible?)
    // TODO: Support for getting parameter names for java instance
    //       methods getMethods bytecode with ClassType (not so simple)
    // TODO: Support names with special characters, like |a[)|
    //       Problem is that resulting name is without the || around
    //       the name and since the name that emacs is different from
    //       the one we are given back autodoc is not accepted as valid
    //       Maybe we can:
    //       1. keep a list of special chars
    //       2. when `id' contains one: surround with || (e.g. |id|)
    // TODO: Consider multiple ids:
    //  - Examples: to get more add (message (format "(geiser:%s %s)" proc form))
    //              in the t clause of the geiser-kawa--geiser-procedure:
    //   - (display [cursor] -> (geiser:autodoc ’(display))
    //   - (display (symbol? (string->symbol [cursor] -> (geiser:autodoc ’(string->symbol symbol? display))

    // At the moment arguments are enclosed in double quotes. The
    // reason is that geiser's output is `read' by elisp, but java types
    // may contain characters that are not valid in elisp symbols
    // (e.g. java arrays contain square brackets). So instead of symbols
    // we use strings. When type annotations are disabled using
    // (geiser:set-autodoc-show-types #f) parameter names displayed as
    // symbols (without double quotes around them).

    // List<Object> idsArr = List.getLocalVarsAttr(ids.toArray());
    // idsArr.stream().map( (Object symId, Object env) -> {
    // return (new SymToAutodoc()).apply2(symId, env);
    // })

    public static String autodoc(LList ids) {
        Language language = Language.getDefaultLanguage();
        return autodoc(ids, language, Environment.user());
    }

    public static String autodoc(LList ids, Environment env) {
        Language language = Language.getDefaultLanguage();
        return autodoc(ids, language, env);
    }

    public static String autodoc(LList ids, Language lang, Environment env) {
        String formattedAutodoc = null;
        try {
            ArrayList<Object> autodocList = new ArrayList<>();
            for (Object autodocQuery : (LList) ids) {
                // Currently autodoc is only supported for symbols.
                if (Symbol.class.isAssignableFrom(autodocQuery.getClass())) {
                    AutodocDataForSymId autodocDataForSymId = new AutodocDataForSymId((Symbol) autodocQuery, env, lang);
                    autodocList.add(autodocDataForSymId.toLList());
                }
            }
            formattedAutodoc = Format
                    .format("~S", LList.makeList(autodocList))
                    .toString();
        } catch (Throwable throwable) {
            throwable.printStackTrace();
        }
        return formattedAutodoc;
    }

    public static class OperatorArgListData {
        ProcDataGeneric procDataGeneric;

        public OperatorArgListData(ProcDataGeneric procDataGeneric) {
            this.procDataGeneric = procDataGeneric;
        }

        private static String
        formatParam(ParamData param, String formatting) {
            // This method is just to reduce boilerplate in the other `formatParam'
            String paramName = param.getName();
            String formattedParamType =
                    Format
                            .format("::~a",
                                    param.getType().getReflectClass().getName())
                            .toString();
            return Format.format(
                    formatting,
                    paramName,
                    formattedParamType).toString();
        }

        public static String
        formatParam(ParamData param,
                    boolean isOptionalParam) {
            if (isOptionalParam && showTypes) {
                return formatParam(param, "(~a~a)");
            } else if (isOptionalParam && !showTypes) {
                return formatParam(param, "(~a)");
            } else if (!isOptionalParam && showTypes) {
                return formatParam(param, "~a~a");
            } else if (!isOptionalParam && !showTypes) {
                return formatParam(param, "~a");
            } else {
                throw new Error("No worries, this clause can't happen (2 booleans == 4 possibilities)." +
                        "Just silencing the \"Missing return statement\" error.");
            }
        }

        public LList paramListToFormattedParamLList(List<ParamData> params, boolean areOptionalParams) {
            List<String> formattedParamList = new ArrayList<>();
            for (ParamData req : params) {
                String s = formatParam(req, areOptionalParams);
                formattedParamList.add(s);
            }
            return LList.makeList(formattedParamList);
        }

        public LList toLList() {
            ArrayList<Object> genericProcArgList = new ArrayList<>();

            for (ProcDataNonGeneric pd : this.procDataGeneric.getProcDataNonGenericList()) {
                ArrayList<Object> nonGenericProcArgList = new ArrayList<>();
                ArrayList<Object> requiredParamList = new ArrayList<>();
                ArrayList<Object> optionalParamList = new ArrayList<>();

                List<ParamData> requiredParams = pd.getRequiredParams();

                if (!requiredParams.isEmpty()) {
                    LList requiredParamLList = paramListToFormattedParamLList(requiredParams, false);
                    // argList.add(LList.list2("required", requiredParamLList));
                    requiredParamList.add("required");
                    requiredParamList.addAll(requiredParamLList);
                }

                List<ParamData> optionalParams = pd.getOptionalParams();
                Optional<ParamData> restParamMaybe = pd.getRestParam();
                if (optionalParams.size() > 0 || restParamMaybe.isPresent()) {
                    LList optionalOrRestParamLList =
                            optionalParams.size() > 0
                                    ? paramListToFormattedParamLList(optionalParams, true)
                                    : LList.makeList(java.util.Collections.emptyList());
                    if (restParamMaybe.isPresent()) {
                        Object restParamFormatted = Format.format(
                                "(~a...)",
                                formatParam(restParamMaybe.get(), false)
                        );
                        // adding to gnu.lists.EmptyList is not supported.
                        if (optionalOrRestParamLList.size() == 0) {
                            optionalOrRestParamLList =
                                    LList.list1(restParamFormatted);
                        } else {
                            optionalOrRestParamLList.add(restParamFormatted);
                        }
                    }
                    optionalParamList.add("optional");
                    optionalParamList.addAll(optionalOrRestParamLList);
                }

                if (!requiredParamList.isEmpty()) {
                    nonGenericProcArgList.add(LList.makeList(requiredParamList));
                }
                if (!optionalParamList.isEmpty()) {
                    nonGenericProcArgList.add(LList.makeList(optionalParamList));
                }
                genericProcArgList.add(LList.makeList(nonGenericProcArgList));
            }

            return LList.makeList(genericProcArgList);
        }
    }

    public static class AutodocDataForSymId {
        private boolean symExists;
        private Symbol symId;
        private Optional<Object> operatorMaybe;
        private Environment environment;
        private Optional<OperatorArgListData> operatorArgListMaybe;
        // TODO: fix type, write way to get it
        private Object module;


        public AutodocDataForSymId(Symbol symId, Environment env, Language lang) {
            this.symId = symId;
            this.environment = env;

            Optional<Object> operatorMaybe = Optional.empty();
            Optional<OperatorArgListData> operatorArgListMaybe = Optional.empty();
            try {
                // env.get(symId) works with the < procedure, while
                // lang.eval(symId.toString()) raises NullPointerException (maybe a bug?).
                // On the other hand, env.get(symId) does not work with procedures defined
                // from java with lang.defineFunction(), like the various geiser:...
                // Since kawadevutil's eval works for both we are using that for now.
                EvalResult evalResult = GeiserEval.evaluator.eval(lang, env, symId);
                operatorMaybe = evalResult.getResult() != null
                        ? Optional.of(evalResult.getResult())
                        : Optional.empty();
                if (operatorMaybe.isPresent()) {
                    Object operator = operatorMaybe.get();

                    if (Procedure.class.isAssignableFrom(operator.getClass())) {
                        Procedure operatorProc
                                = (Procedure) operator;
                        ProcDataGeneric procDataGeneric
                                = ProcDataGeneric.makeForProcedure(operatorProc);
                        operatorArgListMaybe
                                = Optional.of(new OperatorArgListData(procDataGeneric));

                    } else if (operator.getClass().equals(Class.class)) {
                        Class operatorClass
                                = (Class) operatorMaybe.get();
                        ProcDataGeneric procDataGeneric
                                = ProcDataGeneric.makeForConstructors(operatorClass);
                        operatorArgListMaybe
                                = Optional.of(new OperatorArgListData(procDataGeneric));

                    } else if (LangObjType.class.isAssignableFrom(operator.getClass())) {
                        LangObjType operatorLOT
                                = (LangObjType) operator;
                        Procedure constructorProc
                                = operatorLOT.getConstructor();
                        ProcDataGeneric procDataGeneric
                                = ProcDataGeneric.makeForProcedure(constructorProc);
                        operatorArgListMaybe
                                = Optional.of(new OperatorArgListData(procDataGeneric));

                    } else {
                        // Not a procedure
                        // TODO : is it possible to implement autodoc for macros?
                        //        If not: write a comment why.
                        operatorArgListMaybe = Optional.empty();
                    }

                }
            } catch (Throwable throwable) {
                throwable.printStackTrace();
            }

            this.operatorArgListMaybe = operatorArgListMaybe;
            this.operatorMaybe = operatorMaybe;
            this.symExists = operatorMaybe.isPresent();
        }

        public LList toLList() {

            ArrayList<Object> operatorArgListAsList = new ArrayList<>();
            operatorArgListAsList.add("args");
            if (operatorArgListMaybe.isPresent()) {
                operatorArgListAsList.addAll(operatorArgListMaybe.get().toLList());
            } else {
                operatorArgListAsList.add(false);
            }
            LList operatorArgListAsLList = LList.makeList(operatorArgListAsList);

            // TODO: write a procedure that gets the module getMethods
            //       which a symbol comes getMethods using "the right way" (is there one?)
            // TODO: When we find the correct way to do it, refactor moduleLList inside
            //       ProcDataNonGeneric or a generic wrapper for Procedure data
            LList moduleLList = null;
            if (this.operatorMaybe.isPresent()) {

                Object operator = this.operatorMaybe.get();

                if (operator.getClass().equals(CompiledProc.class)) {
                    CompiledProc compProc = (CompiledProc) operator;
                    moduleLList = LList.makeList(
                            java.util.Arrays
                                    .asList(compProc
                                            .getModuleClass()
                                            .getName()
                                            .split("\\.")));

                } else if (operator.getClass().equals(LangObjType.class)
                        && this.operatorArgListMaybe.isPresent()) {
                    Procedure constructorProc = ((LangObjType) operator).getConstructor();
                    String constructorName = constructorProc.getName();
                    // constructorName examples:
                    // list: list
                    // filepath: gnu.kawa.io.FilePath.makeFilePath(java.lang.Object)
                    String constructorNameNoSig = constructorName.contains("(")
                                    ? constructorName
                                    .substring(0, constructorName.indexOf("("))
                                    : constructorName;
                    ArrayList<String> splitAtDot = new ArrayList<>(
                            Arrays.asList(constructorNameNoSig.split("\\."))
                    );
                    int procNameIndex = splitAtDot.size() - 1;
                    String procNameOnly = splitAtDot.get(procNameIndex);

                    Class moduleAsClass
                            = this.operatorArgListMaybe.get().procDataGeneric.getModule();
                    ArrayList<String> moduleList = new ArrayList<>();
                    moduleList.addAll(
                            Arrays.asList(moduleAsClass.getName().split("\\."))
                    );
                    moduleList.add(":" + procNameOnly);
                    moduleLList = LList.makeList(moduleList);
                }
            }

            // If none of the previous conditions matched, moduleLList is still null.
            if (moduleLList == null) {
                try {
                    // If it's not a CompiledProc it does not have a
                    // `getModule' method: fallback to trying to figure
                    // out getMethods GnuMappingLocation in Environment.
                    // TODO: generalize to arbitrary environment
                    moduleLList = (LList) kawa.lib.ports.read(
                            new gnu.kawa.io.CharArrayInPort(
                                    GnuMappingLocation.baseLocationToModuleName(
                                            environment.lookup(symId).getBase()
                                    )
                            )
                    );
                } catch (NullPointerException e) {
                    // If it is not even a sym in the environment, give up.
                    // TODO: should we consider all java classes as modules?
                    moduleLList = LList.makeList(new ArrayList());
                }
            }

            // If you don't convert your symbol to String it may not match with
            // the string seen from the emacs side and when that happens geiser
            // does not considers that a valid autodoc response.
            // Example: as a Symbol, java.lang.String:format is displayed by
            // kawa as:
            //   java.lang.String{$unknown$}:format
            // which does not match:
            //   java.lang.String:format
            // so geiser ignores it.
            String symIdAsStr = symId.toString();
            LList res;
            if (moduleLList.size() > 0) {
                ArrayList<Object> moduleList = new ArrayList<>();
                moduleList.add("module");
                for (Object m : moduleLList) {
                    moduleList.add(Symbol.valueOf(m.toString()));
                }
                res = LList.list3(
                        symIdAsStr,
                        operatorArgListAsLList,
                        LList.makeList(moduleList)
                );
            } else {
                res = LList.list2(
                        symIdAsStr,
                        operatorArgListAsLList
                );
            }

            return res;
        }
    }
}

