# wikidata mapping to taxonomy from ott and other databases
The scripts aid in  mapping of wikidata ids to taxonomic ids from 11 other databases (ott, gbif, ncbi, eol, itis, irmng, col, bold, worms, plazi, apni).

Ideally a big sparql query where a subject is a taxon and has a scientific name and optional mapping to to taxonomic ids from these 11 dbs, should have worked. Unfortunately, such a query times out on the wikidata sparql query service, because of enormous number of hits (>1 mio). Therefore, in this script, qlever's wikidata sparql endpoint was used (approach-1). Another crude way out is to map wd ids individually to each db and then joining them (approach-2).

A couple of R packages are required to run the scripts, mainly `WikidataQueryServiceR`, `glue`,`dplyr`, `tidyverse`, `httr`, `rotl`, `taxizedb`, and `dbplyr`.

Steps to perform:

a) Download the input:[open tree of life taxonomy](https://tree.opentreeoflife.org/about/taxonomy-version/ott3.6)

b) Run the script `Rscript --vanilla matchTaxonomy.R`

The output files can also be downloaded here [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.12725311.svg)](https://doi.org/10.5281/zenodo.12725311)



