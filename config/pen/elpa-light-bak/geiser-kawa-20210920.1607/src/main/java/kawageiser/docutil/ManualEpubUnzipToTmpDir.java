/*
 * Copyright (C) 2020 spellcard199 <spellcard199@protonmail.com>
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

package kawageiser.docutil;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;

public class ManualEpubUnzipToTmpDir {

    public static String unzipToTmpDir(String kawaEpubManualPath) throws IOException {
        String systemTmpDir = System.getProperty("java.io.tmpdir");
        String manualUnzippedTmpDir = String.join(
                File.separator,
                systemTmpDir,
                "geiser-kawa",
                "manual-epub-unzipped");

        File zipArchiveFile = new File(kawaEpubManualPath);
        Path destDirPath = new File(manualUnzippedTmpDir).toPath();

        kawadevutil.util.ZipExtractor.unzip(zipArchiveFile, destDirPath);
        return gnu.kawa.functions.Format.format("~S", manualUnzippedTmpDir).toString();
    }
}
