# DIFF TOOLS

Make "git diff" show text difference in binary files: PDF, DOC, XLS, PPT, ODT, ODS, ODP, etc.

## Dependencies

Tools used by these scripts:

Tool             | Description
-----------------|---------------------------------
catdoc           | Microsoft Office (DOC, RTF, XLS)
pandoc           | Microsoft Office (DOCX)
docx2txt         | Microsoft Office (DOCX)
xlsx2csv         | Microsoft Office (XLSX)
odt2txt          | Libre Office (ODT, ODS, ODP)
python3-pdfminer | PDF

To install dependencies on Ubuntu:

```sh
sudo apt install catdoc pandoc docx2txt xlsx2csv odt2txt python3-pdfminer
```

# Install and help

```sh
# Install
sh setup-diff-tools.sh --install

# Help
sh setup-diff-tools.sh --help
```

# Issues

* Not able to convert PPT or PPTX (Microsoft Office PowerPoint presentations).
* ODS files (LibreOffice Calc spreadsheets) are converted as one cell per line instead of CSV.
