require 'stringio'

module ThreadOut

  def self.write(stuff='')
    if Thread.current[:stdout] then
      Thread.current[:stdout].write stuff
    else
      STDERR.write stuff
    end
  end

  def self.puts(stuff='')
    if Thread.current[:stdout] then
      Thread.current[:stdout].puts stuff
    else
      STDOUT.puts stuff
    end
  end
  def self.print(stuff='')
    if Thread.current[:stdout] then
      Thread.current[:stdout].puts stuff
    else
      STDOUT.write stuff
    end
  end

  def self.flush
    if Thread.current[:stdout] then
      Thread.current[:stdout].flush
    else
      STDOUT.flush
      STDERR.flush
    end
  end
end

STDOUT.sync = true
STDERR.sync = true
$stdout = ThreadOut
$stderr = ThreadOut
