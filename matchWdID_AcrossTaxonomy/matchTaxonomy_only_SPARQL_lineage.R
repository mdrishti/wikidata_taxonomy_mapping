###################################################################################################
# @Project - wd mapping with taxonomies from 11 other dbs				          #
# @Description - This code integrates taxonomies from 12 dbs including wikidata. The anchor points#
# remain wikidata and open tree of life								  #
###################################################################################################

source("taxonomy_functions.R")

##### APPROACH-1 using qlever ##########
#############################################Combine mapping through qlever##########################################
## query below fails on wikidata query service because more than 1 mio hits with the label service. Diff number of rows each time. Couldn't resolve it for now. So, used qlever. variable kept for reference later.
queryComb <- '
PREFIX wdt: <http://www.wikidata.org/prop/direct/>
PREFIX wd: <http://www.wikidata.org/entity/>
                SELECT ?WdID ?WdName ?hTax ?hTaxName ?hTaxRankName WHERE{
                ?WdID wdt:P31 wd:Q16521;
                        wdt:P225 ?WdName ;
			wdt:P171* ?hTax .
		?hTax wdt:P225 ?hTaxName ;
			wdt:P105 ?hTaxRank . 
		        }'
#with open('sparql_query.txt', 'r') as file:
#    queryComb = file.read()
#using qlever
df.Wdfull <- querkiWriteFile(queryComb, "all_wd_eol_ncbi_gbif_andOthers_mapping_SPARQL_20250305_lineage.txt")
#write.csv(df.Wdfull, "all_wd_eol_ncbi_gbif_andOthers_mapping_SPARQL_20250305_lineage.txt", row.names=FALSE)
#############################################Combine mapping through qlever##########################################


