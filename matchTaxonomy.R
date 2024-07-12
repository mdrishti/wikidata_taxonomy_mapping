###################################################################################################
# @Project - wd mapping with taxonomies from 11 other dbs				          #
# @Description - This code integrates taxonomies from 12 dbs including wikidata. The anchor points#
# remain wikidata and open tree of life								  #
###################################################################################################

source("taxonomy_functions.R")

##### APPROACH-1 using qlever ##########
#############################################Combine mapping through qlever##########################################
## query below fails on wikidata query service because more than 1 mio hits with the label service. Diff number of rows each time. Couldn't resolve it for now. So, used qlever.
queryComb <- '	PREFIX wdt: <http://www.wikidata.org/prop/direct/>
		PREFIX wd: <http://www.wikidata.org/entity/>
		SELECT ?WdID ?eol ?gbif ?ncbi ?ott ?itis ?irmng ?col ?nbn ?worms ?bold ?plazi ?apni ?WdName WHERE{ 
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
		        }'
#using qlever
df.Wdfull <- querki(queryComb)
write.csv(df.Wdfull, "all_wd_eol_ncbi_gbif_andOthers_mapping_SPARQL.txt", row.names=FALSE)
#############################################Combine mapping through qlever##########################################


##########################################Integration with data from otl#############################################
#read ott taxonomy and resolve ncbi and gbif mapping within the taxonomy file
df.otol <- read.csv("ott3.6/taxonomy.tsv",header=TRUE,row.names=NULL, sep="|")
df.otol <- df.otol[,c(1,3,5)]
df.otol$sourceinfo <- gsub("\t","",df.otol$sourceinfo) 
df.otol$name <- gsub("\t","",df.otol$name) 

df.otolX <- extrV1(c("ncbi:","gbif:"),data.frame(Ids=df.otol[,3]))
names(df.otolX) <- c("ncbi","gbif")
df.otolY <- data.frame(ott_id=as.numeric(df.otol$uid),ncbi=df.otolX$ncbi,gbif=df.otolX$gbif, OttName=df.otol$name)

#full-join the sparql and otol.ott tables
df.otol.wd <- full_join(df.Wdfull,df.otolY, by=c("ott"="ott_id"), suffix=c(".wd",".ott"), na_matches="never") #all wd ids mapping to 11 dbs, but also ott not matching to wd
write.csv(df.otol.wd, "all_wd_eol_ncbi_gbif_andOthers_mapping_matchedOTT.txt", row.names=FALSE)


#simple metrics to check number of unique ott-ids and wd-ids mapped
ottU <- nrow(unique(df.otol.wd[which(is.na(df.otol.wd$WdID)==FALSE & is.na(df.otol.wd$ott)==FALSE),c("ott")])) #unique ott that have wd
WdU <- nrow(unique(df.otol.wd[which(is.na(df.otol.wd$WdID)==FALSE & is.na(df.otol.wd$ott)==FALSE),c("WdID")])) #unique wd that have ott
ottX <- nrow(unique(df.otol.wd[which(is.na(df.otol.wd$WdID)==TRUE & is.na(df.otol.wd$ott)==FALSE),c("ott")])) #unique ott that don't have wd

##########################################Integration with data from otl#############################################



#####APPROACH-2 in case the first one does not work##########
################################################### Individual mappings #############################################
#queryOtt <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
#	SELECT ?WdID ?ott WHERE{ 
#		?WdID wdt:P9157 ?ott.
#		SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
#	}'
#queryNcbi <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
#	SELECT ?WdID ?ncbi WHERE{ 
#		?WdID wdt:P685 ?ncbi.
#		SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
#	}'
#queryGbif <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
#	SELECT ?WdID ?gbif WHERE{ 
#		?WdID wdt:P846 ?gbif.
#		SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
#	}'
#queryEol <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
#	SELECT ?WdID ?eol WHERE{ 
#		?WdID wdt:P830 ?eol.
#		SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
#	}'
#queryItis <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
#	SELECT ?WdID ?itis WHERE{ 
#		?WdID wdt:P815 ?itis.
#		SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
#	}'
#queryIrmng <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
#	SELECT ?WdID ?irmng WHERE{ 
#		 ?WdID wdt:P5055 ?irmng . 
#		SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
#	}'
#queryCol <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
#	SELECT ?WdID ?col WHERE{ 
#		 ?WdID wdt:P10585 ?col . 
#		SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
#	}'
#queryNbn <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
#	SELECT ?WdID ?nbn WHERE{ 
#		 ?WdID wdt:P3240 ?nbn . 
#		SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
#	}'
#queryWorms <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
#	SELECT ?WdID ?worms WHERE{ 
#		 ?WdID wdt:P850 ?worms . 
#		SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
#	}'
#queryBold <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
#	SELECT ?WdID ?bold WHERE{ 
#		 ?WdID wdt:P3606 ?bold . 
#		SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
#	}'
#queryPlazi <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
#	SELECT ?WdID ?plazi WHERE{ 
#		 ?WdID wdt:P1992 ?plazi . 
#		SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
#	}'
#queryApni <- 'PREFIX wdt: <http://www.wikidata.org/prop/direct/> 
#	SELECT ?WdID ?apni WHERE{ 
#		 ?WdID wdt:P5984 ?apni . 
#		SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
#	}'
#
#
#df.wdOtt <- data.frame(query_wikidata(queryOtt))
#df.wdNcbi <- data.frame(query_wikidata(queryNcbi))
#df.wdEol <- data.frame(query_wikidata(queryEol))
#df.wdGbif <- data.frame(query_wikidata(queryGbif))
#df.wdItis <- data.frame(query_wikidata(queryItis))
#df.wdIrmng <- data.frame(query_wikidata(queryIrmng))
#df.wdCol <- data.frame(query_wikidata(queryCol))
#df.wdNbn <- data.frame(query_wikidata(queryNbn))
#df.wdWorms <- data.frame(query_wikidata(queryWorms))
#df.wdBold <- data.frame(query_wikidata(queryBold))
#df.wdPlazi <- data.frame(query_wikidata(queryPlazi))
#df.wdApni <- data.frame(query_wikidata(queryApni))
#################################################### Individual mappings #############################################
#
#
#################################################### Combined mappings #############################################
###Thhis is needed because otherwise some may not have an ott id and will nver turn up in the optional. Other queries were showing timeout.
#df.Wdfull <- full_join(df.wdOtt, df.wdNcbi, by='WdID') %>%
#                full_join(., df.wdEol, by='WdID') %>%	
#                full_join(., df.wdGbif, by='WdID') %>%	
#                full_join(., df.wdItis, by='WdID') %>%	
#                full_join(., df.wdIrmng, by='WdID') %>%	
#                full_join(., df.wdCol, by='WdID') %>%
#                full_join(., df.wdNbn, by='WdID') %>%	
#                full_join(., df.wdWorms, by='WdID') %>%	
#                full_join(., df.wdBold, by='WdID') %>%	
#                full_join(., df.wdPlazi, by='WdID') %>%	
#                full_join(., df.wdApni, by='WdID')	
################################################### Combined mappings #############################################

#######################################secondary###########################################

#using querki function in case WikidataQueryService::query_wikidata fails
#result <- querki(query1)
#df.wdDef <- data.frame(result)



#use in case of wd mapping for specific ott ids. 
#ott_id <- glue_collapse(ott_ids[1:475], sep="\" \"")
#df.wd <- data.frame(query_wikidata(glue(query, .open = "${")))
#results <- do.call(rbind, lapply(ott_ids, function(ott_id1) {
#					   result <- query_wikidata(glue_collapse(query, .open="${")) 
#					     result$title <- ott_id1
#					     return(result)
#}))


#use runSparql in case of more than 500 ott ids to map

#mapping to wikidata, ncbi, gbif and otol 
#df.wikidata <- getwikidata() # used for taxonomic mapping. it also maps to gbif, and ncbi

#for mapping lineage of wikidata ids. TBD
#g <- graph_from_data_frame(df.wikidata[,c("wikidata_id","parent_id")], directed = TRUE)
#cat("DFS Traversal starting for all nodes in wikidata\n")
#dfs_order <- dfs_traversal(g, 'Q12824168')
#print(V(g)$name[dfs_order])

#gbif mapping. It also maps to ncbi
#df.gbif <- getGbif()

