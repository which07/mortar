def run_script():
    import os
    from org.apache.pig.scripting import Pig

    # compile the pig code
    P = Pig.compileFromFile("../pigscripts/#{script_name}.pig")
    bound = P.bind()
    bound.runSingle()

if __name__ == '__main__':
    run_script()
