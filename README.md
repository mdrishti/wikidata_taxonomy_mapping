# wikidata mapping to taxonomy from ott and other databases
The scripts aid in  mapping of wikidata ids to taxonomic ids from 14 other databases (ott, gbif, ncbi, eol, itis, irmng, col, bold, worms, plazi, iNaturalist, msw3, eppo).

Ideally a big sparql query where a subject is a taxon and has a scientific name and optional mapping to to taxonomic ids from these 11 dbs, should have worked. Unfortunately, such a query times out on the wikidata sparql query service, because of enormous number of hits (>1 mio). Therefore, in this script, qlever's wikidata sparql endpoint was used (approach-1). Another crude way out is to map wd ids individually to each db and then joining them (approach-2).

A couple of R packages are required to run the scripts, mainly `WikidataQueryServiceR`, `glue`,`dplyr`, `tidyverse`, `httr`, `rotl`, and `dbplyr`.

Steps to perform:

a) Match WdIDs to other taxonomies (for historical reasons the code is in R)

Run the scripts 

`Rscript --vanilla matchTaxonomy_only_SPARQL.R`


`Rscript --vanilla matchTaxonomy_only_SPARQL_lineage.R`



b) Align WdIDs to lineage through columns of taxonomic ranks

Run the script `python matchWdID_lineage.py <filename>`

`<filename>` is obtained during first step.

