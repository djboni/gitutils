#!/bin/sh
#
# Copyright (C) 2021 Djones A. Boni
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <https://unlicense.org>

# Make "git diff" show text difference in binary files:
# PDF, DOC, XLS, PPT, ODT, ODS, ODP, etc.
#
# See: setup-diff-tools.sh --help

do_usage() {
    Usage="\
setup-diff-tools.sh --help|--install

Install dependencies and configure git diff to use conversion tools for some
filetypes:

DOC  XLS       (Microsoft Office)
DOCX XLSX      (Microsoft Office)
ODT  ODS  ODP  (Libre Office)
FODT FODS FODP (Libre Office)
PDF

Options:

--help

        See this helpful message.

--install

        Install dependencies and configure git diff.

References:

[1] Pro Git
    http://git-scm.com/book

[2] Git advanced (text) diff: .odt, .pdf, .doc, .xls, .ppt
    https://medium.com/@mbrehin/git-advanced-diff-odt-pdf-doc-xls-ppt-25afbf4f1105

[3] View .docx file on Github and use git diff on .docx file format
    https://stackoverflow.com/questions/22439517/view-docx-file-on-github-and-use-git-diff-on-docx-file-format
"
    echo "$Usage"
}

do_install() {
    sudo apt install catdoc pandoc docx2txt xlsx2csv odt2txt python3-pdfminer

    # Cache text conversion:
    # true or false
    CacheTextConv="false"

    # Clean cache with:
    # git update-ref -d refs/notes/textconv/doc
    # or
    # rm -fr .git/refs/notes/textconv

    # catdoc

    git config --local diff.doc.textconv catdoc
    git config --local diff.doc.binary true
    git config --local diff.doc.cachetextconv $CacheTextConv

    git config --local diff.rtf.textconv catdoc
    git config --local diff.rtf.binary true
    git config --local diff.rtf.cachetextconv $CacheTextConv

    # pandoc or docx2txt

    #git config --local diff.docx.textconv "pandoc --to=markdown"
    git config --local diff.docx.textconv 'docx2txt - - <'
    git config --local diff.docx.binary true
    git config --local diff.docx.cachetextconv $CacheTextConv

    # catdoc

    git config --local diff.xls.textconv xls2csv
    git config --local diff.xls.binary true
    git config --local diff.xls.cachetextconv $CacheTextConv

    # xlsx2csv

    git config --local diff.xlsx.textconv xlsx2csv
    git config --local diff.xlsx.binary true
    git config --local diff.xlsx.cachetextconv $CacheTextConv

    # What converts PPT and PPTX to text?
    # catppt does not work for both.

    #git config --local diff.ppt.textconv catppt
    #git config --local diff.ppt.binary true
    #git config --local diff.ppt.cachetextconv $CacheTextConv

    #git config --local diff.pptx.textconv catppt
    #git config --local diff.pptx.binary true
    #git config --local diff.pptx.cachetextconv $CacheTextConv

    # odt2txt

    git config --local diff.odt.textconv odt2txt
    git config --local diff.odt.binary true
    git config --local diff.odt.cachetextconv $CacheTextConv

    git config --local diff.fodt.textconv "odt2txt --raw-input"
    git config --local diff.fodt.binary false
    git config --local diff.fodt.cachetextconv $CacheTextConv

    git config --local diff.ods.textconv ods2txt
    git config --local diff.ods.binary true
    git config --local diff.ods.cachetextconv $CacheTextConv

    git config --local diff.fods.textconv "ods2txt --raw-input"
    git config --local diff.fods.binary false
    git config --local diff.fods.cachetextconv $CacheTextConv

    git config --local diff.odp.textconv odp2txt
    git config --local diff.odp.binary true
    git config --local diff.odp.cachetextconv $CacheTextConv

    git config --local diff.fodp.textconv "odp2txt --raw-input"
    git config --local diff.fodp.binary false
    git config --local diff.fodp.cachetextconv $CacheTextConv

    # python3-pdfminer

    git config --local diff.pdf.textconv pdf2txt
    git config --local diff.pdf.binary true
    git config --local diff.pdf.cachetextconv $CacheTextConv
}

# $# Number of arguments
# $1 First argument
case "$#$1" in
1--help)
    do_usage
    exit 0
    ;;
1--install)
    do_install
    exit 0
    ;;
*)
    do_usage >&2
    exit 1
    ;;
esac
