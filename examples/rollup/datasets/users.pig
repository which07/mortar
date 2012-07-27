/*
 * users
 */
DEFINE USERS_LOADER()
returns loaded {
    $loaded = 
        LOAD 's3n://hawk-example-data/tutorial/users.txt'
       USING PigStorage('\t') 
          AS (user_id:chararray, age:int);
};

DEFINE USERS_STORER(alias)
returns void {
};
