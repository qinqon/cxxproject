require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/binary_library'
require 'cxxproject/buildingblocks/source_library'
require 'cxxproject/buildingblocks/executable'
require 'cxxproject/utils/cleanup'

describe Cxxproject::Executable do
  SOURCE_NAME = './hello.cpp'
  OUTDIR = "#{Dir.pwd}/out"
  COMMAND = 'cmd'
  MUSTFLAG1 = '-mustflag1'
  MUSTFLAG2 = '-mustflag2'
  FLAGS = '-flags'
  EXE_FLAG = 'exeflag'
  OUTPUT_ENDING = '.exe'
  LIB_PREFIX = 'libprefix'
  LIB_POSTFIX = 'libpostfix'
  START_OF_WHOLE_ARCHIVE = {:UNIX => 'startofwholearchive', :OSX => 'startofwholearchiveforosx'}
  END_OF_WHOLE_ARCHIVE = {:UNIX => 'endofwholearchive', :OSX => 'endofwholearchiveforosx'}
  LIB_FLAG = 'libflag'
  LIB_PATH_FLAG = 'libpathflag'
  USER_LIB_FLAG = 'userlibflag'
  before(:each) do
    Cxxproject::Utils.cleanup_rake

    File.open(SOURCE_NAME, 'w') do |io|
      io.puts('// just for testing')
    end
    @lib1 = Cxxproject::SourceLibrary.new('lib1', true)
    @lib1.set_output_dir(OUTDIR)
    @lib1.set_project_dir('.')
    @lib1.set_sources([SOURCE_NAME])
    @lib1.complete_init
    @exe = Cxxproject::Executable.new('test')
    @exe.set_output_dir(OUTDIR)
    @exe.set_project_dir('.')
    @exe.set_sources([SOURCE_NAME])
    @exe.set_dependencies(['lib1'])
    @exe.complete_init
    @toolchain = double('Toolchain')
    @linker = double('Linker')
    @linker.stub(:[]).with(:COMMAND).and_return(COMMAND)
    @linker.stub(:[]).with(:MUST_FLAGS).and_return("#{MUSTFLAG1} #{MUSTFLAG2}")
    @linker.stub(:[]).with(:FLAGS).and_return([FLAGS])
    @linker.stub(:[]).with(:EXE_FLAG).and_return(EXE_FLAG)
    @linker.stub(:[]).with(:OUTPUT_ENDING).and_return(OUTPUT_ENDING)
    @linker.stub(:[]).with(:LIB_PREFIX_FLAGS).and_return(LIB_PREFIX)
    @linker.stub(:[]).with(:LIB_POSTFIX_FLAGS).and_return(LIB_POSTFIX)
    @linker.stub(:[]).with(:START_OF_WHOLE_ARCHIVE).and_return(START_OF_WHOLE_ARCHIVE)
    @linker.stub(:[]).with(:END_OF_WHOLE_ARCHIVE).and_return(END_OF_WHOLE_ARCHIVE)
    @linker.stub(:[]).with(:LIB_FLAG).and_return(LIB_FLAG)
    @linker.stub(:[]).with(:LIB_PATH_FLAG).and_return(LIB_PATH_FLAG)
    @toolchain.stub(:[]).with(:LINKER).and_return(@linker)
    @exe.set_tcs(@toolchain)
    @exe.convert_to_rake
  end

  after(:each) do
    File.delete(SOURCE_NAME)
  end

  [:OSX, :UNIX].each do |os|
    it 'should work for #{os}' do
      @toolchain.stub(:[]).with(:TARGET_OS).and_return(os)
      @exe.calc_command_line.should eq([COMMAND, MUSTFLAG1, MUSTFLAG2, FLAGS, EXE_FLAG, 'out/test.exe', LIB_PREFIX, START_OF_WHOLE_ARCHIVE[os], @lib1.get_archive_name, END_OF_WHOLE_ARCHIVE[os], LIB_POSTFIX])
    end
  end

end