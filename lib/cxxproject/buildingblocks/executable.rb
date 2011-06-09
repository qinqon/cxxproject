require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'
require 'cxxproject/buildingblocks/has_includes_mixin'

require 'tmpdir'

class Executable < BuildingBlock
  include HasLibraries
  include HasSources
  include HasIncludes

  attr_reader :linker_script
  attr_reader :mapfile
  attr_reader :output_file

  def set_linker_script(x)
    @linker_script = x
    self
  end

  def set_mapfile(x)
    @mapfile = x
    self
  end

  # set during creating the task - note: depends on the used tcs
  def set_output_file(x)
    @output_file = x
    self
  end

  def initialize(name)
    super(name)
    @linker_script = nil
    @mapfile = nil
  end

  def linker_libs_string
    @linkerString ||= ""
  end


  def get_executable_name()
    parts = [complete_output_dir]
    parts << 'exes' if @output_dir_abs
    parts << "#{@name}#{@tcs[:LINKER][:OUTPUT_ENDING]}"

    File.relFromTo(File.join(parts), @project_dir)
  end

  def get_task_name()
    get_executable_name()
  end

  # create a task that will link an executable from a set of object files
  #
  def convert_to_rake()

    calc_compiler_strings()
    objects, object_multitask = create_tasks_for_objects()

    executable = get_executable_name()
    scriptFile = ""
    script = ""
    if @linker_script
      scriptFile = File.relFromTo(@linker_script, @project_dir)
      script = "#{@tcs[:LINKER][:SCRIPT]} #{scriptFile}"  # -T xy/xy.dld
    end

    mapfileString = @mapfile ? "#{@tcs[:LINKER][:MAP_FILE_FLAG]} >#{File.relFromTo(@mapfile, complete_output_dir)}" : "" # -Wl,-m6 > xy.map

    # calc linkerLibString - order is important, duplicates are removed
    lib_searchpaths_array = []
    libs_to_search_array = []
    user_libs_array = []
    libs_with_path_array = []
    strArray = []
    all_dependencies.each do |e|
      d = ALL_BUILDING_BLOCKS[e]
      next if not HasLibraries === d

      d.lib_searchpaths.each do |k|
        tmp = File.relFromTo(k, d.project_dir)
        if not lib_searchpaths_array.include?tmp
          lib_searchpaths_array << tmp
          strArray << "#{@tcs[:LINKER][:LIB_PATH_FLAG]}#{tmp}"
        end
      end

      d.libs_to_search.each do |k|
        if not libs_to_search_array.include?k
          libs_to_search_array << k
          strArray << "#{@tcs[:LINKER][:LIB_FLAG]}#{k}"
        end
      end

      d.user_libs.each do |k|
        if not user_libs_array.include?k
          user_libs_array << k
          strArray << "#{@tcs[:LINKER][:USER_LIB_FLAG]}#{k}"
        end
      end

      d.libs_with_path.each do |k|
        tmp = File.relFromTo(k, d.project_dir)
        if not libs_with_path_array.include?tmp
          libs_with_path_array << tmp
          strArray << tmp
        end
      end
    end

    linkerLibString = strArray.reject{|e| e == ""}.join(" ")

    cmd = [@tcs[:LINKER][:COMMAND], # g++
      @tcs[:LINKER][:MUST_FLAGS], # ??
      @tcs[:LINKER][:FLAGS], # --all_load
      @tcs[:LINKER][:EXE_FLAG], # -o
      executable, # debug/x.o
      objects.reject{|e| e == ""}.join(" "), # debug/src/abc.o debug/src/xy.o
      script,
      mapfileString,
      @tcs[:LINKER][:LIB_PREFIX_FLAGS], # "-Wl,--whole-archive "
      linkerLibString,
      @tcs[:LINKER][:LIB_POSTFIX_FLAGS] # "-Wl,--no-whole-archive "
    ].reject{|e| e == ""}.join(" ")

    create_run_task(executable, @config_files, @name)

    res = file executable => object_multitask do
      # TempFile used, because some compilers, e.g. diab, uses ">" for piping to map files:

      if @@verbose
        puts cmd
      else
        puts "Linking #{executable}" unless Rake::application.options.silent
      end

      consoleOutput = `#{cmd + " 2>" + get_temp_filename}`
      consoleOutput.concat(read_temp_file.join("\n"))
      process_console_output(consoleOutput, @tcs[:LINKER][:ERROR_PARSER])
      raise "System command failed" if $?.to_i != 0
    end
    res.type = Rake::Task::EXECUTABLE
    res.progress_count = 1
    res.enhance(@config_files)
    res.enhance([scriptFile]) unless scriptFile==""
    add_output_dir_dependency(executable, res, true)

    namespace 'exe' do
      desc executable
      task @name => executable
    end
    setup_rake_dependencies(res)
    res
  end

  def create_run_task(executable, configFiles, name)
    namespace 'run' do
      desc "run executable #{executable}"
      res = task name => executable do
        sh "#{executable}"
      end
      res.type = Rake::Task::RUN
      res
    end
  end



  def get_temp_filename
    Dir.tmpdir + "/lake.tmp"
  end

  def read_temp_file
    lines = []
    File.open(get_temp_filename, "r") do |infile|
      while (line = infile.gets)
        lines << line
      end
    end
    lines
  end

end
