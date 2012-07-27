/*
 * last_search_by_age
 */
DEFINE LAST_SEARCH_BY_AGE_STORER(alias)
returns void {
    STORE alias 
     INTO '$OUTPUT_DESTINATION'
    USING org.apache.pig.piggybank.storage.MultiStorage(
             's3n://hawk-dev-sandbox/ddaniels_at_mortardata_dot_com/most_recent_query_by_age',  -- top-level output path (repeated)
             '0');                   -- index of field to partition by ('age' in this example)
};
