###################################################################################################
# @Project - wd mapping with taxonomies from 11 other dbs				          #
# @Description - This code represents functions used for integrating taxonomies from 12 dbs 	  #
#including wikidata. 										  #
###################################################################################################

library(rotl) 
library(dplyr) 
library(dbplyr)
library(WikidataQueryServiceR)
library(glue)
library(httr)
library(tidyverse)
library(tidyr)
library(chunked)


#get data from OTOL
getOtolPlants <- function(a1) {
	#a1 <- unique(df.speciesX$TRY_AccSpeciesName)
	#a1 <- df.speciesX
	a1 <- tolower(a1)
	#window of 10000 as listed in the description of tnrs_match_names
	df.otol <- tnrs_match_names(names = a1[1:5663],context_name="Land plants")
	for (i in seq(5664,length(a1),10000)) {
        	j <- i + 9999
	        print("In progress....")
 	        df.tmp <- tnrs_match_names(names = a1[i:j],context_name="Land plants")
        	df.otol <- rbind(df.otol, df.tmp)
	}
	which(!(a1 %in% df.otol$search_string))
	#there are some duplicates, and 23265 names which were not found. In testing phase to figure out an alternative approach for mapping those 23265 names
	df.otol <- na.omit(df.otol) #Omit all those that were not found
	#dbDisconnect()
	return(df.otol)
}

#get data from wikidata and subsequent gbif and ncbi ids
getWikidata <- function() {
	db_download_wikidata(verbose = TRUE, overwrite = FALSE) # download wikidata with aggregated taxonomic ids for ncbi and gbif.
	db_path("wikidata") # get the path of the database. optional.
	src <- src_wikidata()  # load wikidata
	df.wikidataX <- data.frame(tbl(src, "wikidata"))
	#sanity check
	#x <- filter(df.wikidataX, scientific_name == "Acer campestre")
	#print(x)
	#dbDisconnect()
	return(df.wikidataX)
}

#get gbif ids only for plantae
getGbif <- function() {
	db_download_gbif(verbose = TRUE, overwrite = FALSE) # download gbif
	db_path("gbif") # get the path of the database. optional.
	src <- src_gbif()  # load gbif
	df.gbifX <- data.frame(tbl(src, "gbif"))
	df.gbifX <- df.gbifX[which(df.gbifX$kingdom=="Plantae"),]
	#sanity check
	#x <- filter(df.gbifX, scientific_name == "Acer campestre")
	#print(x)
	#dbDisconnect()
	return(df.gbifX)
}


# this to be used when tracking lineage
dfs_traversal1 <- function(graph, start_node) {
  dfs_result <- dfs(graph, root = start_node, dist = TRUE)
  return(dfs_result$order) # Return the order of visited nodes
}


#extract specific ids from single coulumn
extrV1  <- function(catg,fx2) {
	        for(i in 1:length(catg)) {
	                print(catg[i])
        	        m <- gregexec(paste(catg[i],"[A-Z0-9]+", sep=""), fx2[,1])
		        res <- regmatches(fx2[,1],m)
		        cols <- unique(unlist(res))                           # unlist to remove nested lists
		        res1 <- data.frame(map_vec(res, ~ifelse(is.null(.x), NA, .x)))
		        names(res1) <- catg[i]
		        res1 <- as.data.frame(sub(catg[i],"",res1[,1]))
		        names(res1) <- catg[i]
		        ifelse(i==1, res2 <- res1, res2 <- cbind(res2,res1))
	        }
        return(res2)
}


#for specific ott ids only. Timeout exception noticed many times
runSparql <- function(ottId) {
	for(i in seq(1,length(ottId),300)) {
        	j <- i + 299
		if ( abs(length(ottId) - i) < 299 ) {
			j <- length(ottId)
		}
	        print("In progress....")
		print(i)
		print(j)
		ott_id <- glue_collapse(ottId[i:j], sep="\" \"")
		query <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
			SELECT ?ott ?wd WHERE{ 
			        ?wd wdt:P9157 ?ott .
			        OPTIONAL { ?wd wdt:P685 ?ncbi .}
			        OPTIONAL { ?wd wdt:P846 ?gbif .}
			        OPTIONAL { ?wd wdt:P830 ?eol . }
			        VALUES ?wd { \"${ott_id}\" } 
				SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
		        }'
	        result1 <- data.frame(query_wikidata(glue(query, .open="${")))
		if(j==300){
			result <- result1
		}
		else {
			result <- rbind(result,result1)
		}
		#result <- ifelse(j==475, result1, rbind(result,result1))
		print(head(result1))
	}
	return(result)
}


#In case WikidataQueryServiceR fails, use the following functions
querki <- function(query) {
	  h="text/csv"
	  response <- httr::GET(url = "https://qlever.cs.uni-freiburg.de/wikidata/sparql", query = list(query = query), httr::add_headers(Accept = h))
	  #response <- httr::GET(url = "https://query.wikidata.org/sparql", query = list(query = query), httr::add_headers(Accept = h))
	  return(httr::content(response))
}

querkiWriteFile <- function(query, outputFile) {
	  h="text/csv"
	  response <- httr::GET(url = "https://qlever.cs.uni-freiburg.de/wikidata/sparql", query = list(query = query), httr::add_headers(Accept = h), httr::write_disk(outputFile))
	  #response <- httr::GET(url = "https://query.wikidata.org/sparql", query = list(query = query), httr::add_headers(Accept = h))
}

processFileInChunks <- function(chunk, pos, outputFile) {
	#con <- file(inputFile, "r")
	cs <- 5000  
	transformed_df <- chunk %>%
		select(WdID, WdName, hTaxRank, hTaxName) %>%
		distinct() %>%
		pivot_wider(names_from = hTaxRank, values_from = hTaxName, values_fn = list(hTaxName = unique))
	write.table(transformed_df, file = outputFile, sep = ",", col.names = FALSE, row.names = FALSE, append = TRUE)
	cat("Results written to", outputFile, "\n")
}



processFileInChunks1 <- function(inputFile, outputFile) {
	data_chunks <- read_chunkwise(inputFile, chunk_size = 5000L)
	data_chunks <- data_chunks %>% select(WdID, WdName, hTaxRank, hTaxName) %>%
		tidyr::pivot_wider(names_from = hTaxRank, values_from = hTaxName, values_fn = list(hTaxName = unique))
	write_chunkwise(data_chunks, outputFile)
}
