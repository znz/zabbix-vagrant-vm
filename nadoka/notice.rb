#!/usr/bin/ruby
require 'socket'
path = ARGV.shift
if ARGV.empty?
  abort("usage: #{$0} /path/to/sock message...")
end
stat = File.stat(path)
unless stat.writable?
  require 'etc'
  exec("sudo", "-u", Etc.getpwuid(stat.uid).name, $0, path, *ARGV)
end
UNIXSocket.open(path) do |s|
  ARGV.each do |message|
    s.puts message
  end
end
