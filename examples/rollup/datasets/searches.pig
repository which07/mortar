/*
 * searches
 */
DEFINE SEARCHES_LOADER()
returns loaded {
    $loaded = 
        LOAD 's3n://hawk-example-data/tutorial/excite.log.bz2'
       USING PigStorage('\t') 
          AS (b0:double, b1:double, b2:double, b3:double);
};

DEFINE SEARCHES_STORER(alias)
returns void {
};
