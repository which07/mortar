require 'json'

module Mortar
  module Fixtures
    def fixture_mappings(mappings_file)
      mappings = []
      if File.exists? mappings_file
        File.open(mappings_file, "r") do |f|
          mappings = JSON.load(f)
        end
      end
      mappings
    end

    def delete_fixture(fixtures_path, mappings_file, fixture_name)
      mappings = fixture_mappings(mappings_file)

      # delete mapping
      File.open(mappings_file, "w") do |f|
        f.write(JSON.pretty_generate(
          mappings.select { |m| m["name"] != fixture_name }
        ))
      end
      
      # delete data
      if File.exists? "#{fixtures_path}/#{fixture_name}"
        FileUtils.rm_r "#{fixtures_path}/#{fixture_name}"
      end
    end

    def fixture_overwrite_check(fixtures_path, mappings_file, fixture_name, overwrite)
      mappings = fixture_mappings(mappings_file)
      if (mappings.select { |m| m["name"] == fixture_name }).size > 0
        if overwrite
          delete_fixture(fixtures_path, mappings_file, fixture_name)
        else
          error("Fixture #{fixture_name} already exists. To overwrite, use the -f option.")
        end
      end
    end

    def store_fixture_argument(fixture_type, fixture_alias, store_what, output_uri)
      if fixture_type == :LIMIT
        fixture_statement = "LIMIT #{fixture_alias} #{store_what}"
      elsif fixture_type == :SAMPLE
        fixture_statement = "SAMPLE #{fixture_alias} #{store_what}"
      elsif fixture_type == :FILTER
        fixture_statement = "FILTER #{fixture_alias} BY #{store_what}"
      else
        error("pig_store_fixture_argument: invalid fixture type. must be LIMIT, SAMPLE, or FILTER.")
      end
      "-S \"#{fixture_alias}|#{fixture_statement}|#{output_uri}\""
    end

    def add_fixture_mapping(mappings_file, fixture_name, pigscript_name, fixture_alias, fixture_uri)
      mappings = fixture_mappings(mappings_file)
      mappings.push({
        "name" => fixture_name,
        "pigscript" => pigscript_name,
        "alias" => fixture_alias,
        "uri" => fixture_uri
      })
      File.open(mappings_file, "w") do |f|
        f.write(JSON.pretty_generate(mappings))
      end 
    end
  end
end
