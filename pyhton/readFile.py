import pandas as pd
import re
import sys
import bz2  # pour lire .bz2

TRIPLE_RE = re.compile(r'^\s*<([^>]*)>\s+<([^>]*)>\s+<([^>]*)>\s*\.\s*$')

def turtle_to_dataframe(path, max_rows=None):
    data = []

    # choisir la bonne fonction d'ouverture
    open_fn = bz2.open if path.endswith(".bz2") else open

    with open_fn(path, "rt", encoding="utf8", errors="ignore") as f:
        for i, line in enumerate(f):
            m = TRIPLE_RE.match(line.strip())
            if m:
                subj, pred, obj = m.groups()
                data.append((subj, pred, obj))

            if max_rows and len(data) >= max_rows:
                break

    return pd.DataFrame(data, columns=["subject", "predicate", "object"])


if __name__ == "__main__":
    import sys
    path = sys.argv[1] if len(sys.argv) > 1 else "wikilinks_lang=en.ttl.bz2"
    df = turtle_to_dataframe(path, max_rows=1000)
    print(df.head())
