/*
 * Copyright (C) 2020 spellcard199 <spellcard199@protonmail.com>
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

package kawageiser.kawadevutil;

import gnu.expr.CommandCompleter;
import gnu.expr.Language;
import gnu.kawa.functions.Format;
import gnu.lists.IString;
import gnu.lists.LList;
import gnu.mapping.Environment;
import gnu.mapping.Symbol;
import gnu.math.IntNum;
import kawadevutil.complete.find.CompletionFindGeneric;
import kawadevutil.complete.find.packagemembers.CompletionFindPackageMemberUtil;
import kawadevutil.complete.result.abstractdata.CompletionData;
import kawadevutil.complete.result.abstractdata.CompletionForClassMember;
import kawadevutil.complete.result.concretedata.CompletionForPackageMember;
import kawadevutil.complete.result.concretedata.CompletionForSymbol;
import kawadevutil.complete.result.concretedata.CompletionForSymbolAndPackageMember;
import kawadevutil.exprtree.CursorFinder;
import kawadevutil.exprtree.ExprWrap;
import kawadevutil.shaded.io.github.classgraph.PackageInfo;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

public class Complete {

    public static String
    completeJava(IString codeStr, IntNum cursorIndex)
            throws Throwable {
        return completeJava(
                codeStr,
                cursorIndex,
                Language.getDefaultLanguage(),
                Environment.user());
    }

    public static String
    completeJava(IString codeStr, IntNum cursorIndex, Language lang,
                 Environment env)
            throws Throwable {

        // Get Data
        Optional<CompletionData> complDataMaybe = CompletionFindGeneric.find(
                codeStr.toString(), cursorIndex.intValue());

        return complDataMaybe
                .map(Complete::complDataToLList)
                .map(x -> Format.format("~S", x).toString())
                .orElse(Format.format("~A", LList.Empty).toString());
    }

    public static LList
    complDataToLList(CompletionData complData) {
        // Wrap data of interest in Scheme's LList
        LList complDataAsLList = null;
        if (complData instanceof CompletionForClassMember) {
            complDataAsLList = toLList((CompletionForClassMember) complData);
        } else if (complData instanceof CompletionForSymbolAndPackageMember) {
            complDataAsLList = toLList((CompletionForSymbolAndPackageMember) complData);
        } else {
            throw new Error("[BUG SPOTTED] `complData's class is one not expected: "
                    + complData.getClass().toString());
        }
        return complDataAsLList;
    }

    private static LList
    toLList(CompletionForClassMember completionForClassMember) {

        String ownerClassName = completionForClassMember.getOwnerClass().getName();

        ArrayList<String> modifiers = new ArrayList<>();
        for (Object modifier : completionForClassMember.getModifierMask().getRequired()) {
            modifiers.add(modifier.toString());
        }

        CompletionData.CompletionType completionType
                = completionForClassMember.getCompletionType();

        List<String> names
                = completionForClassMember
                .getNames()
                .stream()
                .distinct()
                .collect(Collectors.toList());

        String beforeCursor
                = completionForClassMember
                .getCursorFinder()
                .getCursorMatch()
                .getBeforeCursor();

        String afterCursor
                = completionForClassMember
                .getCursorFinder()
                .getCursorMatch()
                .getAfterCursor();

        LList res = LList.makeList(
                Arrays.asList(
                        LList.list2("completion-type", completionType.toString()),
                        LList.list2("before-cursor", beforeCursor),
                        LList.list2("after-cursor", afterCursor),
                        LList.list2("owner-class", ownerClassName),
                        LList.list2("modifiers", LList.makeList(modifiers)),
                        LList.list2("names", LList.makeList(names))
                ));

        return res;
    }

    private static LList
    toLList(CompletionForSymbolAndPackageMember completionForSymbolAndPackageMember) {

        Optional<CompletionForPackageMember> completionForPackageMember
                = completionForSymbolAndPackageMember.getCompletionForPackageMember();

        LList completionForPackageMemberLList;

        if (completionForPackageMember.isPresent()) {
            completionForPackageMemberLList
                    = completionForSymbolAndPackageMember
                    .getCompletionForPackageMember()
                    .map(Complete::toLList)
                    .orElse(LList.Empty);
        } else {
            completionForPackageMemberLList = toLList(
                    CompletionFindPackageMemberUtil.getRootCache(true)
            );
        }

        CompletionData.CompletionType
                completionType = completionForSymbolAndPackageMember.getCompletionType();

        CommandCompleter commandCompleter
                = completionForSymbolAndPackageMember.getCommandCompleter();
        ArrayList<String> symbolNames = new ArrayList<>();
        if (completionForPackageMember.isPresent()
                &&
                !completionForPackageMember
                        .get().getPackageInfo().getName().equals("")) {
            symbolNames.addAll(commandCompleter.candidates);
        } else {
            Environment.user().enumerateAllLocations().forEachRemaining(
                    loc -> {
                        Symbol sym = loc.getKeySymbol();
                        // String symName = sym.getName();
                        // TODO: with toString(), things like
                        //  $construct$:PD and $construct$:sh
                        //  are stringified correctly.
                        //  Check if with using toString() instead of getNames():
                        //  1. other things break
                        //  2. if yes, why
                        String symName = sym.toString();
                        symbolNames.add(symName);
                    }
            );
        }

        LList res = LList.makeList(
                Arrays.asList(
                        LList.list2("completion-type", completionType.toString()),
                        // CommandCompleter doesn't know what's after the cursor
                        LList.list2("before-cursor", commandCompleter.word),
                        LList.list2("word-cursor", commandCompleter.wordCursor),
                        LList.list2( "symbol-names", LList.makeList(symbolNames)),
                        LList.list2("package-members", completionForPackageMemberLList)
                )
        );

        return res;
    }

    public static LList
    toLList(CompletionForSymbol completionForSymbol) {
        CommandCompleter commandCompleter
                = completionForSymbol.getCommandCompleter();
        return LList.list1(
                LList.list2("names", LList.makeList(commandCompleter.candidates))
        );
    }

    public static LList
    toLList(CompletionForPackageMember completionForPackageMember) {
        PackageInfo pinfo = completionForPackageMember.getPackageInfo();
        return toLList(pinfo);
    }

    public static LList
    toLList(PackageInfo pinfo) {

        String ownerPackageName = pinfo.getName();

        // strip ownerPackageName plus the the dot
        int prefixLengthToStrip = ownerPackageName.length() > 0
                ? ownerPackageName.length() + 1
                : 0;
        List<String> childPackageNames
                = pinfo
                .getChildren()
                .getNames()
                .stream()
                .map(n -> n.substring(prefixLengthToStrip))
                .collect(Collectors.toList());

        List<String> childClassNames
                = pinfo
                .getClassInfo()
                .getNames()
                .stream()
                .map(n -> n.substring(prefixLengthToStrip))
                .collect(Collectors.toList());

        LList res = LList.makeList(
                Arrays.asList(
                        LList.list2("owner-package", pinfo.getName()),
                        LList.list2(
                                "child-package-names",
                                LList.makeList(childPackageNames)),
                        LList.list2(
                                "child-class-names",
                                LList.makeList(childClassNames))
                )
        );
        return res;

    }

    public static Optional<ExprWrap>
    getExprTreeMaybe(IString codeStr, IntNum cursorIndex, Language lang,
                     Environment env)
            throws IOException {
        try {
            CursorFinder cursorFinder = CursorFinder.make(
                    codeStr.toString(), cursorIndex.intValue(), true,
                    lang, env
            );
            return Optional.of(cursorFinder.getRootExprWrap());
        } catch (IOException e) {
            return Optional.empty();
        }
    }

    public static Optional<ExprWrap>
    getExprTreeMaybe(IString codeStr, IntNum cursorIndex)
            throws IOException {
        return getExprTreeMaybe(
                codeStr, cursorIndex,
                Language.getDefaultLanguage(), Environment.user());
    }

    public static String
    getExprTreeFormatted(IString codeStr, IntNum cursorIndex,
                                              Language lang, Environment env)
            throws IOException {
        return getExprTreeMaybe(codeStr, cursorIndex, lang, env)
                .map(complData -> complData.formatElem(true)).get();
    }

    public static String
    getExprTreeFormatted(IString codeStr, IntNum cursorIndex)
            throws IOException {
        return getExprTreeFormatted(
                codeStr,
                cursorIndex,
                Language.getDefaultLanguage(),
                Environment.user()
        );
    }
}
