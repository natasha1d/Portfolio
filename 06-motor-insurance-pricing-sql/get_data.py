"""Download freMTPL2 from the CASdatasets GitHub repository and save as CSV."""
import os
import urllib.request

import pyreadr  # pip install pyreadr

BASE = "https://raw.githubusercontent.com/dutangc/CASdatasets/master/data/"
os.makedirs("data", exist_ok=True)

for name in ["freMTPL2freq", "freMTPL2sev"]:
    rda = f"data/{name}.rda"
    urllib.request.urlretrieve(BASE + name + ".rda", rda)
    df = next(iter(pyreadr.read_r(rda).values()))
    df.to_csv(f"data/{name}.csv", index=False)
    os.remove(rda)
    print(f"{name}: {len(df):,} rows saved to data/{name}.csv")
