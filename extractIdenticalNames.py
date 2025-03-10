import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('wd_sparql_lineage_file', type=str, help="Enter the file which contains wikidata lineage")
parser.add_argument('repeat_file', type=str, help="Enter file name which contains WdNames that are repeated")
parser.add_argument('output_file', type=str, help="Enter output file name")
args = parser.parse_args()
input_file = args.wd_sparql_lineage_file
repeat_file = args.repeat_file
output_file = args.output_file

wd_df = pd.read_csv(input_file)

with open(repeat_file, "r") as f:
    terms = set(line.strip() for line in f if line.strip()) 

matched_df = wd_df[wd_df["WdName"].isin(terms)].copy()
matched_df.fillna("")

rank_columns = ["kingdom", "phylum", "class", "order", "family", "genus", "species"]

mismatched_rows = []
for name, group in matched_df.groupby("WdName"):
    if not group[rank_columns].nunique().eq(1).all():  
        mismatched_rows.append(group)

if mismatched_rows:
    result_df = pd.concat(mismatched_rows)
    print(result_df.to_csv(output_file,index=False))  # Print or save as needed
else:
    print("All matched terms have identical taxonomic ranks.")

