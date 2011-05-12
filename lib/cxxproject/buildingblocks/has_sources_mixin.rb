module HasSources

  def sources
    @sources ||= []
  end
  def set_sources(x)
    @sources = x
    self
  end

  def includes
    @includes ||= []
  end
  def set_includes(x)
    @includes = x
    self
  end

  def include_string(type)
    @include_string[type] ||= ""
  end

  def define_string(type)
    @define_string[type] ||= ""
  end

  def calc_compiler_strings()
    @include_string = {}
    @define_string = {}
    [:CPP, :C, :ASM].each do |type|
      incArray = []
      all_dependencies.each do |e|
        d = ALL_BUILDING_BLOCKS[e]
        next if not HasSources === d
        if d.includes.length == 0
          incArray << File.relFromTo("include", d.project_dir)
        else
          d.includes.each { |k| incArray << File.relFromTo(k, d.project_dir) }
        end
      end
      @include_string[type] = incArray.uniq.map!{|k| "#{tcs[:COMPILER][type][:INCLUDE_PATH_FLAG]}#{k}"}.join(" ")

      @define_string[type] = @tcs[:COMPILER][type][:DEFINES].map {|k| "#{@tcs[:COMPILER][type][:DEFINE_FLAG]}#{k}"}.join(" ")
    end
  end

  def get_object_file(source)
    File.relFromTo(source, @complete_output_dir + "/" + @name) + ".o"
  end

  def get_dep_file(object)
    object + ".d"
  end

  def get_source_type(source)
    ex = File.extname(source)
    [:CPP, :C, :ASM].each do |t|
      return t if tcs[:COMPILER][t][:SOURCE_FILE_ENDINGS].include?(ex)
    end
    nil
  end

  def get_sources_task_name
    "Sources of #{name}"
  end

end