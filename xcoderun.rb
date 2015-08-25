#!/usr/bin/env ruby
module XCodeRun# {{{
  def self.run args
    opts = RuntimeFlags.new.hashify_args(args)
    runner = Runner.new(opts.args_hash)
    runner.run
  end

  class Runner# {{{
    def initialize options = {}
      @opts = options
      @xcode_args = filter_xcode options
      @tmp_file = File.new("#{options[:temp_dir]}/cc-tmp.json", 'a')
      @log_file = options[:log_file]
    end

    def filter_xcode opts_hash
      available_args = [:project, :sdk, :workspace, :scheme]
      opts_hash.select { |k,v| available_args.include? k }
    end

    def format_keys opts_hash
      formatted = []
      options.each do |key, value|
        formatted.push "-#{key}", value
      end
    end

    def update_compilation_db
      puts "Updating compilation database..."
      `oclint-xcodebuild -o #{@tmp_file}/cc_tmp.json #{@log_file}`
      `node ~/bin/clang_compilation_db_merger.js #{@tmp_file} #{@opts[:compile_commands]}`
      puts "Done."
    end

    def perl_one_liners
      puts "Removing unwanted flags to keep YCM happy..."
      `perl -i -ple 's/--serialize-diagnostics \S* //g' #{@opts[:compile_commands]}`
      `perl -i -ple 's/(-MMD |-MT dependencies |-MF \S* |)//g' #{@opts[:compile_commands]}`
      `perl -i -ple 's/(-iquote|-I|-F)\s*\S*DerivedData\S* (?<!hmap )//g' #{@opts[:compile_commands]}`
    end

    def run
      `xcodebuild #{format_keys(@xcode_args).join(" ")} | tee -a #{@log_file} | xcpretty -c`
      build_success?
      update_compilation_db
      perl_one_liners
    end

    def build_success?
      if $? == 0
        puts "================================================================================"
        puts "=============================== BUILD SUCCESSFUL ==============================="
        puts "================================================================================"
      else
        puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        puts "!!!!!!!!!!!!!!!!!!!!!!  SCARY ERROR - XCODE BUILD FAILED  !!!!!!!!!!!!!!!!!!!!!!"
        puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        puts "Check the above messages to figure out what went wrong..."
      end
    end

    def runnable? target
      File.exist? target and File.executable? target
    end

    def find_available_targets
      available = Dir['build/Release/**.app/**/{MacOS,iphone,iOS}/*']
      if available.length == 0
        puts "No targets found"
      elsif avaliable.length == 1
        target = available.first
        puts "Found #{target}. Checking to make sure it exists and is executable"
      else
        target = target_select available
      end
      execute_target target
    end

    def execute_target target
      exit unless runnable? target
      `./#{File.path target}`
    end

    def target_select list_of_targets
      puts "Multiple targets found. Please select one by entering the number you see on the left."
      list_of_targets.each_with_index do |target, index|
        puts "#{index} -- #{File.basename target} -- #{File.path target}"
      end
      selection = gets.chomp!
      list_of_targets[selection]
    end
  end# }}}

  class RuntimeFlags# {{{
    attr_reader :flags, :args_hash
    def initialize *args
      @flags = {
        "-p" => "--project",
        "-w" => "--workspace",
        "-s" => "--scheme",
        "-sdk" => "--sdk",
        "-t" => "--temp-dir",
        "-cc" => "--compile-commands",
        "-l" => "--log-file"
      }

      @args_hash = {
        sdk: 'macosx10.10',
        temp_dir: '.tmp',
        compile_commands: 'compile-commands.json',
        log_file: 'xcodebuild.log'
      }

      hashify_args args
    end

    def hashify_args args
      while args.length > 0
        arg_pair = args.shift(2)

        if valid_flag? arg_pair[0]
          temp = { fetch_arg(arg_pair[0]) => arg_pair[1] }
          @args_hash.merge!(temp)
        else
          puts "#{arg_pair[0]} is not valid"
        end
      end
    end

    private

    def short_flag? current_arg
      @flags.key? current_arg
    end

    def full_flag? current_arg
      @flags.value? current_arg
    end

    def valid_flag? current_arg
      short_flag?(current_arg) or full_flag?(current_arg)
    end

    def to_snake string
      drop_dashes string
      string.gsub('-', '_')
    end

    def drop_dashes string
      case string[0,2]
      when "--" then string[0,2] = ''
      else string[0] = ''
      end
      string
    end

    def fetch_arg string
      if full_flag? string
        to_snake(string).to_sym
      else
        to_snake(@flags[string]).to_sym
      end
    end

  end# }}}
end# }}}

XCodeRun.run ARGV
