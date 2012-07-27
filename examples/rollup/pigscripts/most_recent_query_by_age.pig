/**
 * Find the most recent query for each age of user.
 */
<%= datasets.searches -%>
<%= datasets.users -%>
<%= datasets.last_search_by_age -%>

searches = SEARCHES_LOADER();

users = USERS_LOADER();

-- Filter to get only users under age 30
users_filtered = FILTER users BY age < 30;

-- Join in user 'dimension' data
joined = JOIN users_filtered BY user_id, searches BY user_id;

-- Merge together searches for each user, only keeping the most recent search
searches_grouped = GROUP joined BY users_filtered::user_id;
most_recent_searches = FOREACH searches_grouped {
     sorted_searches = ORDER joined BY timestamp DESC;
     most_recent_record = LIMIT sorted_searches 1;
     GENERATE group AS user_id,
              MAX(most_recent_record.age) AS age,
              MAX(most_recent_record.timestamp) AS timestamp,
              MAX(most_recent_record.query) AS query;
};


-- Select out just the fields we want to output
ready_to_output = FOREACH most_recent_searches 
                 GENERATE age, 
                          timestamp, 
                          user_id,
                          query;

-- FIXME: need a way to get to the output path directly
rmf s3n://hawk-dev-sandbox/ddaniels_at_mortardata_dot_com/most_recent_query_by_age;

-- Store the output to a folder per 'age' (column 0)
LAST_SEARCH_BY_AGE_STORER(ready_to_output);
