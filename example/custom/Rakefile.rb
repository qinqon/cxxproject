$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'cxxproject'
BuildDir = "BuildDir"

dependent_projects =  ['./project.rb']
CxxProject2Rake.new(dependent_projects, BuildDir, "gcc", './')

unittest_flags = {
  :DEFINES => ['UNIT_TEST','CPPUNIT_MAIN=main'],
  :FLAGS => "-O0 -g3 -Wall"
}
toolchain = Provider.modify_cpp_compiler("gcc", unittest_flags)