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
                SELECT ?WdID ?eol ?gbif ?ncbi ?ott ?itis ?irmng ?col ?nbn ?worms ?bold ?plazi ?apni ?msw3 ?iNat ?eppo ?WdName WHERE{
                ?WdID wdt:P31 wd:Q16521;
                        wdt:P225 ?WdName .
                                OPTIONAL { ?WdID wdt:P9157 ?ott . }
                                OPTIONAL { ?WdID wdt:P685 ?ncbi . }
                                OPTIONAL { ?WdID wdt:P846 ?gbif . }
                                OPTIONAL { ?WdID wdt:P830 ?eol . }
                                OPTIONAL { ?WdID wdt:P815 ?itis . }
                                OPTIONAL { ?WdID wdt:P5055 ?irmng . }
                                OPTIONAL { ?WdID wdt:P10585 ?col . }
                                OPTIONAL { ?WdID wdt:P3240 ?nbn . }
                                OPTIONAL { ?WdID wdt:P850 ?worms . }
                                OPTIONAL { ?WdID wdt:P3606 ?bold . }
                                OPTIONAL { ?WdID wdt:P1992 ?plazi . }
                                OPTIONAL { ?WdID wdt:P5984 ?apni . }
                                OPTIONAL { ?WdID wdt:P959 ?msw3 . }
                                OPTIONAL { ?WdID wdt:P3151 ?iNat . }
                                OPTIONAL { ?WdID wdt:P3031 ?eppo . }
		        }'
#with open('sparql_query.txt', 'r') as file:
#    queryComb = file.read()
#using qlever
df.Wdfull <- querki(queryComb)
write.csv(df.Wdfull, "all_wd_eol_ncbi_gbif_andOthers_mapping_SPARQL_20250303.txt", row.names=FALSE)
#############################################Combine mapping through qlever##########################################


