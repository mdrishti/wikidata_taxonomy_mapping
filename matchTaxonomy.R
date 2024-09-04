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
df.otol <- read.csv("../ott3.6/taxonomy.tsv",header=TRUE,row.names=NULL, sep="|")
df.otol <- df.otol[,c(1,3,5)]
df.otol$sourceinfo <- gsub("\t","",df.otol$sourceinfo) 
df.otol$name <- gsub("\t","",df.otol$name) 

df.otolX <- extrV1(c("ncbi:","gbif:","irmng:","worms:"),data.frame(Ids=df.otol[,3]))
names(df.otolX) <- c("ncbi","gbif","irmng","worms")
df.otolY <- data.frame(ott_id=as.numeric(df.otol$uid),ncbi=df.otolX$ncbi,gbif=df.otolX$gbif, irmng=df.otolX$irmng, worms=df.otolX$worms, OttName=df.otol$name)


################################################
#left-join the sparql and otol.ott tables, but take care that the matching is done by both ncbi and ott. Hack is to firt do anti-join on ott, then join by ncbi and coalesce ott ids, and then join on ott with the original ott df. This is not the most efficiet, but it gets the job done.
#anti-join on ott
df.otolZ <- anti_join(df.otolY,df.Wdfull, by=c("ott_id"="ott")) #ott not matching-2603918
df.otolZ$ncbi <- as.double(df.otolZ$ncbi)
#join on ncbi with results of anti-join
df.otol.wd1 <- left_join(df.Wdfull,df.otolZ, by=c("ncbi"="ncbi"), suffix=c(".wd",".ott"), na_matches="never") %>%
	  mutate(ottJoined = coalesce(ott_id, ott))
#check how many left unjoined on ncbi
df.otol.wd1.aj <- anti_join(df.otolZ,df.Wdfull, by=c("ncbi"="ncbi")) #1420011

#join ncbi-joined and original ott df on ott.
df.otol.wd.lj <- left_join(df.otol.wd1,df.otolY, by=c("ottJoined"="ott_id"), suffix=c(".wd",".ott"), na_matches="never") #all wd ids mapping to 11 dbs, but also ott not matching to wd
df.otol.wd <- full_join(df.otol.wd1,df.otolY, by=c("ottJoined"="ott_id"), suffix=c(".wd",".ott"), na_matches="never") #all wd ids mapping to 11 dbs, but also ott not matching to wd
#check how many left unjoined on ott
df.otolZ.still <- anti_join(df.otolY,df.otol.wd.lj, by=c("ott_id"="ottJoined")) #ott not matching --2550986

#chek how many (un)common between anti-joins of ncbi and ott
df.otolZ.still$ncbi <- as.double(df.otolZ.still$ncbi)
df.otolZ.still$ott_id <- as.double(df.otolZ.still$ott_id)
df.otolZ.nxbi.ott <- anti_join(df.otol.wd1.aj,df.otolZ.still, by=c("ott_id","ncbi")) #ott & ncbi not matching = 0. Good sign!

################################################

write.csv(df.otol.wd, "all_wd_eol_ncbi_gbif_andOthers_mapping_matchedOTT.txt", row.names=FALSE)


#simple metrics to check number of unique ott-ids and wd-ids mapped
ottU <- nrow(unique(df.otol.wd[which(is.na(df.otol.wd$WdID)==FALSE & is.na(df.otol.wd$ottJoined)==FALSE),c("ottJoined")])) #unique ott that have wd: 1924374 --> after anti-join technique-1977306
WdU <- nrow(unique(df.otol.wd[which(is.na(df.otol.wd$WdID)==FALSE & is.na(df.otol.wd$ottJoined)==FALSE),c("WdID")])) #unique wd that have ott: 1958836 -->after anti-join technique-2011639
ottX <- nrow(unique(df.otol.wd[which(is.na(df.otol.wd$WdID)==TRUE & is.na(df.otol.wd$ottJoined)==FALSE),c("ottJoined")])) #unique ott that don't have wd: 2603918 -->2550986


ottY1 <- nrow(unique(df.otol.wd[which(df.otol.wd$ncbi.wd==df.otol.wd$ncbi.ott),c("ottJoined")])) #unique ott-ids that have the same ncbi mapping in both wd and ott: 465368 -->after anti-join- 519070
ottY2 <- nrow(unique(df.otol.wd[which(df.otol.wd$gbif.wd==df.otol.wd$gbif),c("ottJoined")])) #unique ott-ids that have the same gbif mapping in both wd and ott: 1757020 -->after anti-join- 22144 (on mapping gbif.wd & gbif.ott)? & 1778420 (on mapping gbif.wd & gbif)
ottZ1 <- nrow(unique(df.otol.wd[which(df.otol.wd$ncbi.wd!=df.otol.wd$ncbi.ott),c("ottJoined")])) #unique ott-ids that don't have the same ncbi mapping in both wd and ott: 4072 -->after anti-join-3966
ottZ2 <- nrow(unique(df.otol.wd[which(df.otol.wd$gbif.wd!=df.otol.wd$gbif),c("ottJoined")])) #unique ott-ids that don't have the same gbif mapping in both wd and ott: 61516 -->after anti-join- 4001 (on mapping gbif.wd & gbif.ott)? & 65467 (on mapping gbif.wd & gbif) 

WdY1 <- nrow(unique(df.otol.wd[which(df.otol.wd$ncbi.wd==df.otol.wd$ncbi.ott),c("WdID")])) #unique ott-ids that have the same ncbi mapping in both wd and ott: 465371 -->after anti-join-519052
WdY2 <- nrow(unique(df.otol.wd[which(df.otol.wd$gbif.wd==df.otol.wd$gbif),c("WdID")])) #unique ott-ids that have the same gbif mapping in both wd and ott: 1758591 -->after anti-join-1779943 
WdZ1 <- nrow(unique(df.otol.wd[which(df.otol.wd$ncbi.wd!=df.otol.wd$ncbi.ott),c("WdID")])) #unique ott-ids that don't have the same ncbi mapping in both wd and ott: 4377 -->after anti-join-4267
WdZ2 <- nrow(unique(df.otol.wd[which(df.otol.wd$gbif.wd!=df.otol.wd$gbif),c("WdID")])) #unique ott-ids that don't have the same gbif mapping in both wd and ott: 64825 -->after anti-join-68770
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

##temp
#df.otol.wd1 <- full_join(data.frame(df.otol.wd),data.frame(df.otolZ), by=c("ncbi.wd"="ncbi"), suffix=c(".wd",".ott"), na_matches="never") #all wd ids mapping to 11 dbs, but also ott not matching to wd
#df.otol.wd <- left_join(df.Wdfull,df.otolY, by=c("ott"="ott_id"), suffix=c(".wd",".ott"), na_matches="never") #all wd ids mapping to 11 dbs, but also ott not matching to wd
##temp over
