import glob
import os

import duckdb  # pip install duckdb
import matplotlib.pyplot as plt

con = duckdb.connect("motor.duckdb")
for path in sorted(glob.glob("sql/*.sql")):
    print("running", path)
    con.execute(open(path, encoding="utf-8").read())

# Export every result_ table to CSV
os.makedirs("results", exist_ok=True)
tables = [r[0] for r in con.execute(
    "SELECT table_name FROM information_schema.tables "
    "WHERE table_name LIKE 'result_%' ORDER BY table_name").fetchall()]
for t in tables:
    con.execute(f"COPY {t} TO 'results/{t}.csv' (HEADER)")
    print(f"\n== {t} ==")
    print(con.sql(f"SELECT * FROM {t}").df().to_string(index=False))

# Charts
os.makedirs("charts", exist_ok=True)
one_way = con.sql("SELECT * FROM result_04_one_way").df()
fig, axes = plt.subplots(1, 2, figsize=(11, 4))
for ax, factor, title in [(axes[0], "driver_age_band", "Driver age"),
                          (axes[1], "bonus_malus_band", "Bonus-malus level")]:
    d = one_way[one_way.factor == factor].sort_values("level")
    ax.bar(d.level, d.frequency, color="#4C72B0")
    ax.errorbar(d.level, d.frequency,
                yerr=[d.frequency - d.freq_lower_95, d.freq_upper_95 - d.frequency],
                fmt="none", color="black", capsize=3)
    ax.set_title(f"Claim frequency by {title.lower()}")
    ax.set_ylabel("Claims per policy-year")
    ax.tick_params(axis="x", rotation=30)
plt.tight_layout()
plt.savefig("charts/frequency_one_way.png", dpi=150)

dec = con.sql("SELECT * FROM result_07_deciles").df()
fig, ax = plt.subplots(figsize=(7, 4))
ax.bar(dec.decile, dec.actual_relativity, color="#4C72B0", label="Actual (test data)")
ax.plot(dec.decile, dec.avg_predicted_relativity, "o-", color="#DD8452", label="Predicted")
ax.axhline(1, color="grey", lw=0.8, ls="--")
ax.set_xticks(dec.decile)
ax.set_xlabel("Risk decile (1 = lowest predicted risk)")
ax.set_ylabel("Pure premium relative to average")
ax.set_title("Out-of-sample lift chart")
ax.legend()
plt.tight_layout()
plt.savefig("charts/lift_chart.png", dpi=150)
print("\ncharts saved to charts/")
