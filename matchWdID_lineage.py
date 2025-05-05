import argparse
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument('wd_sparql_lineage_file', type=str, help="Enter the file which contains wikidata lineage")
parser.add_argument('filtered_output_file', type=str, help="Enter output file name which will store data from lineage file only if the corresponding rank is available")
parser.add_argument('output_file', type=str, help="Enter output file name which will store the ranks as columns in a lineage format")
args = parser.parse_args()
input_file = args.wd_sparql_lineage_file
filtered_output_file = args.filtered_output_file
output_file = args.output_file
chunk_size = 22787142

predefined_ranks = ["http://www.wikidata.org/entity/Q35409", "http://www.wikidata.org/entity/Q34740", "http://www.wikidata.org/entity/Q36602", "http://www.wikidata.org/entity/Q38348", "http://www.wikidata.org/entity/Q37517", "http://www.wikidata.org/entity/Q36732", "http://www.wikidata.org/entity/Q7432"]

# extract only those rows, which have the predefined ranks
first_chunk = True
for chunk in pd.read_csv(input_file, chunksize=chunk_size):
    required_columns = {"WdID", "WdName", "hTaxRank", "hTaxName"}
    if not required_columns.issubset(chunk.columns):
        print(f"Error: Missing columns in chunk. Found: {list(chunk.columns)}")
        continue
    filtered_chunk = chunk[chunk["hTaxRank"].isin(predefined_ranks)]
    mode = 'w' if first_chunk else 'a' # append to file instead of write afresh
    header = first_chunk
    filtered_chunk.to_csv(filtered_output_file, mode=mode, header=header, index=False)
    first_chunk = False

print(f"Filtered data written to {filtered_output_file}")


# operate on the filtered file to align data into columns with ranks as their header
chunk_iter = pd.read_csv(filtered_output_file, compression="gzip", chunksize=chunk_size)
first_chunk = True
for chunk in chunk_iter:
    chunk.columns = chunk.columns.str.strip()
    required_columns = ["WdID", "WdName", "hTaxRank", "hTaxName"]
    missing_columns = [col for col in required_columns if col not in chunk.columns]
    if missing_columns:
        print(f"Error: Missing columns in chunk: {', '.join(missing_columns)}")
        continue
    transformed_chunk = chunk[["WdID", "WdName"]].drop_duplicates().set_index(["WdID", "WdName"])
    for rank in predefined_ranks:
        transformed_chunk[rank] = ""

    # manually map values from hTaxRank to predefined columns
    for _, row in chunk.iterrows():
        if row["hTaxRank"] in predefined_ranks:
            transformed_chunk.at[(row["WdID"], row["WdName"]), row["hTaxRank"]] = row["hTaxName"]

    # reset index to flatten DataFrame
    transformed_chunk.reset_index(inplace=True)

    # write to file (header only for first chunk)
    mode = 'w' if first_chunk else 'a'
    header = first_chunk
    transformed_chunk.to_csv(output_file, compression="gzip", mode=mode, header=header, index=False)

    # after first write, switch to append mode
    first_chunk = False

print(f"Results written to {output_file}")
