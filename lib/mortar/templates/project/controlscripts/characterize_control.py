from org.apache.pig.scripting import Pig

if __name__ == "__main__":
    params       = Pig.getParameters()
    loader       = params["LOADER"]
    input_source = params["INPUT_SRC"]
    output_path  = params["OUTPUT_PATH"]

    Pig.compileFromFile("../pigscripts/characterize.pig").bind({
        "LOADER"      : loader
        "INPUT_SRC"   : input_source
        "OUTPUT_PATH" : output_path
    }).runSingle()
