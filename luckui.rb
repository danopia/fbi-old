#!/usr/bin/env ruby

require 'rubygems'
require 'luck'

require File.join(File.dirname(__FILE__), 'common', 'client')

#require File.join(File.dirname(__FILE__), 'irc')

display = Luck::Display.new nil

#~ connection = nil
#~ Thread.new {
  #~ EM.run {
    #~ connection = IRC.connect 'irc.eighthbit.net', 6667, "luckirc-#{`hostname`.chomp}", '#programming', 'luckirc'
    #~ #connection.send 'names', '#programming'
    #~ #def initialize(nick, channels=nil, admins=[], ident=nil, realname=nil, password=nil)
  #~ }
#~ }

trap 'INT' do
  display.undo_modes
  exit
end

class FBI::SilentClient < FBI::Client
  def receive_object action, data
    handle action.to_sym, data
  end
end

client = FBI::SilentClient.new 'luckui', 'hil0l'
client.subscribe_to '#debug'

$components = ['luckui']

client.on :auth do |data|
  display.panes[:main].controls[:history].data << "Logged in as #{data['user']}"
  display.dirty! :main

  EM.add_periodic_timer 5 do
    client.send_object 'components', {}
    client.send_object 'channels', {}
  end
  
  client.send_object 'components', {}
  client.send_object 'channels', {}
end

client.on :subscribe do |data|
  display.panes[:main].controls[:history].data << "Subscribed to #{data['channels'].join ', '}"
  display.dirty! :main
end

client.on :components do |data|
  (data['components'] - $components).each do |new|
    #display.panes[:main].controls[:history].data << "New component: #{new}"
    #display.dirty! :main
    client.send new, :method => 'select', :table => 'users'
  end
  $components = data['components']
  
  display.panes[:left].controls[:comps].data = data['components']
  display.dirty! :left
end

client.on :channels do |data|
  display.panes[:left2].controls[:chans].data = data['channels']
  display.dirty! :left2
end

client.on :publish do |data|
  display.panes[:main].controls[:history].data << data.inspect
  display.dirty! :main
end

Thread.new { begin; client.start_loop; rescue => ex; puts ex,ex.message,ex.backtrace; end }

begin
  display.pane :left, 1, 1, 20, 10, 'Components' do
    control :comps, Luck::ListBox, 2, 1, -2, -1
  end
  display.pane :left2, 1, 10, 20, -1, 'Channels' do
    control :chans, Luck::ListBox, 2, 1, -2, -1
  end

  display.pane :main, 20, 1, -1, -1, 'Debug' do
    control :history, Luck::ListBox, 2, 1, -2, -2
    display.active_control = control :input, Luck::TextBox, 2, -1, -2, -1 do
      #self.label = 'danopia'
      self.text = ''
    end
  end

  #~ display.pane :right, -20, 1, -1, -1, 'Nicks' do
    #~ control :nicks, Luck::ListBox, 2, 1, -2, -1
  #~ end
  
  display.panes[:main].controls[:input].on_submit do |message|
    #~ if !(message =~ /^\/([^ ]+) ?(.+)$/)
      #~ connection.message '#programming', message
      #~ display.panes[:main].controls[:history].data << "<#{connection.nick}> #{message}"
      #~ display.dirty! :main
    #~ elsif $1 == 'me'
      #~ connection.action '#programming', $2
      #~ display.panes[:main].controls[:history].data << "* #{connection.nick} #{$2}"
      #~ display.dirty! :main
    #~ end
  end
  
  display.handle while sleep 0.01

rescue => ex
  display.undo_modes
  puts ex.class, ex.message, ex.backtrace
  exit
end
