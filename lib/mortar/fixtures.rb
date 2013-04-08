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

    def fixture_overwrite_check(fixtures_path, mappings_file, fixture_name, overwrite)
      mappings = fixture_mappings(mappings_file)
      if (mappings.select { |m| m["name"] == fixture_name }).size > 0
        if overwrite
          delete_fixture(fixtures_path, mappings_file, fixture_name)
        else
          error("Fixture #{fixture_name} already exists. To overwrite, use the -F option.")
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

    def ensure_fixtures_in_gitignore(project_root)
      if File.exists? "#{project_root}/.gitignore"
        open("#{project_root}/.gitignore", 'r+') do |gitignore|
          unless gitignore.read().include? "fixtures"
            gitignore.seek(0, IO::SEEK_END)
            gitignore.puts "fixtures"
          end
        end
      end
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

    def load_fixture_argument(mappings_file, script_name, use_all_fixtures, specific_fixtures)
      mappings = fixture_mappings(mappings_file).select { |m| m["pigscript"] = script_name }
      specific_fixtures = Array(specific_fixtures)

      if use_all_fixtures
        aliases = mappings.map { |m| m["alias"] }
        if aliases.uniq.length != aliases.length
          dups = (aliases.select { |a| aliases.index(a) != aliases.rindex(a) }).uniq
          error("Multiple fixtures specified for alias#{dups.length > 1 ? "es" : ""} #{dups.join(',')}.\n" + 
                "Use -x/--fixture options instead of -F/--usefixtures to manually specify which fixtures to use.\n" +
                "Use the command \"mortar fixtures\" to see a list of mappings between fixture names and pigscript aliases.")
        end
      else
        mappings = mappings.select { |m| specific_fixtures.include? m["name"] }
        aliases = mappings.map { |m| m["alias"] }
        if aliases.uniq.length != aliases.length
          dups = (aliases.select { |a| aliases.index(a) != aliases.rindex(a) }).uniq
          error("Multiple fixtures specified for alias#{dups.length > 1 ? "es" : ""} #{dups.join(',')}.\n" +
                "Use the command \"mortar fixtures\" to see a list of mappings between fixture names and pigscript aliases.")
        end
      end

      (mappings.map { |m| "-L \"#{m['alias']}|#{m['uri']}\"" }).join(" ")
    end
  end
end
