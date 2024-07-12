# wikidata mapping to taxonomy from ott and other databases
The scripts aid in  mapping of wikidata ids to taxonomic ids from 11 other databases (ott, gbif, ncbi, eol, itis, irmng, col, bold, worms, plazi, apni).

Ideally a big sparql query where a subject is a taxon and has a scientific name and optional mapping to to taxonomic ids from these 11 dbs, should have worked. Unfortunately, such a query leads to timeout because of enormous number of hits (>1 mio). Another crude way out is to map wd ids individually to each db and then joining them.

A couple of R packages are required to run the scripts, mainly `WikidataQueryServiceR`, `glue`,`dplyr`, `httr`, `rotl`, `taxizedb`, and `dbplyr`.

Run the script `Rscript --vanilla matchTaxonomy.R`

Download the input:[open tree of life taxonomy](https://tree.opentreeoflife.org/about/taxonomy-version/ott3.6)
 

Download the output files associated with these scripts can be found here (link coming soon).

