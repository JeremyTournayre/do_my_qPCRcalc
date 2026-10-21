"""Non-regression test of a running do_my_qPCRcalc site.

Sends every example file of the repository (3 data sets x .tsv/.xlsx/.ods x Pfaffl/Livak,
plus the copy-paste form with example.tsv) to the site, extracts the cells of each
returned Excel file and compares them with expected/.

Usage (requires curl and the Python package openpyxl):
    python tests/non_regression/run.py [URL]            compare the site with expected/
    python tests/non_regression/run.py [URL] --update   replace expected/ with the site's results

Each run adds 20 files to upload/ (named NONREG-*, plus 2 random names for the
copy-paste form) and 20 entries to count_upload/ on the server.
"""
import os
import re
import subprocess
import sys
import tempfile

import openpyxl

URL = "https://qpcr-calcul.clermont.inrae.fr/"
HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
EXPECTED = os.path.join(HERE, "expected")
EXAMPLES = ["example", "example_norefgene", "example_multiplerefgenes"]
EXTS = ["tsv", "xlsx", "ods"]
METHODS = ["Pffafl", "Livak"]


def cases():
    for ex in EXAMPLES:
        for ext in EXTS:
            for m in METHODS:
                path = os.path.join(REPO, f"{ex}.{ext}")
                upload_name = f"NONREG-{ex.replace('_', '-')}.{ext}"
                yield f"{ex}.{ext}_{m}", ["-F", "action=file", "-F", f"Pffafl_o_Livak={m}",
                                          "-F", f"qPCRfile=@{path};filename={upload_name}"]
    for m in METHODS:
        yield f"paste-example.tsv_{m}", ["-F", "action=in", "-F", f"Pffafl_o_Livak={m}",
                                         "-F", f"txt=<{os.path.join(REPO, 'example.tsv')}"]


def cells(xlsx):
    """All non-empty rows of every sheet, as text."""
    lines = []
    for ws in openpyxl.load_workbook(xlsx).worksheets:
        lines.append(f"### {ws.title}")
        for row in ws.iter_rows():
            vals = ["" if c.value is None else repr(c.value) for c in row]
            if any(vals):
                lines.append("\t".join(vals))
    return "\n".join(lines) + "\n"


def normalize(text):
    # With several reference genes, the "delta Cq by <gene>" title names one of them
    # at random (Perl hash order); the values do not change.
    return re.sub(r"delta Cq by [^']*", "delta Cq by REF", text)


def main():
    args = [a for a in sys.argv[1:] if a != "--update"]
    update = "--update" in sys.argv
    url = args[0] if args else URL
    os.makedirs(EXPECTED, exist_ok=True)
    failures = 0
    with tempfile.TemporaryDirectory() as tmp:
        for name, form in cases():
            xlsx = os.path.join(tmp, name + ".xlsx")
            subprocess.run(["curl", "-s", "-o", xlsx, *form, url], check=True)
            try:
                got = cells(xlsx)
            except Exception:
                print(f"ERREUR      {name} : le site n'a pas renvoyé de fichier Excel")
                failures += 1
                continue
            expected_file = os.path.join(EXPECTED, name + ".txt")
            if update:
                with open(expected_file, "w", encoding="utf-8", newline="\n") as f:
                    f.write(got)
                print(f"MIS A JOUR  {name}")
            elif not os.path.exists(expected_file):
                print(f"ABSENT      {name} : pas de résultat attendu (lancer avec --update)")
                failures += 1
            else:
                with open(expected_file, encoding="utf-8") as f:
                    same = normalize(f.read()) == normalize(got)
                print(f"{'OK' if same else 'DIFFERENT':12s}{name}")
                failures += not same
    if not update:
        print(f"\n{failures} échec(s) sur 20" if failures else "\nTous les résultats sont identiques aux résultats attendus.")
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
