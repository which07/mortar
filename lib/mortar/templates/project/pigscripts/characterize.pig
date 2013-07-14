IMPORT '../macros/characterize.pig';
data = LOAD '$INPUT_SRC'
       USING $LOADER;
characterize_data = Characterize(data, true);
STORE characterize_data INTO '../$OUTPUT_PATH'
       USING org.apache.pig.piggybank.storage.CSVExcelStorage(',', 'YES_MULTILINE', 'UNIX', 'WRITE_OUTPUT_HEADER');
