/**
 * <%= macro_name %>: Pig macros for use in pigscripts.
 *
 */

/**
 * A simple example macro function that returns the entity passed in.
 */
DEFINE <%= macro_name.capitalize %>_EXAMPLE(input_relation)
returns output_relation {
    -- just an example
    $output_relation = FOREACH $input_relation
                      GENERATE *;
};
