# -*- encoding: utf-8 -*-
# Author:: Farzad FARID (<ffarid@pragmatic-source.com>)
# Copyright:: Copyright (c) 2011 Farzad FARID
# License:: Simplified BSD License

begin
  require "readline"
rescue LoadError
  # No readline
end


module Zabby
  class Runner
    attr_reader :config, :connection

    # Meta-create methods with the same name as the configuration settings.
    # This way we can write:
    #   set host "http://my.zabbix.server"
    # instead of:
    #   set :host => "http://my.zabbix.server"
    # or "set host" instead of "set :host"
    # All the created method does is return the second form which will be
    # used by "set".
    Zabby::Config::SETTING_LIST.each { |setting|
      # TODO: Ruby 1.8 does not support default values for block arguments..
      # Writing "... do |value = nil|" would be more elegant.
      define_method(setting) do |*args|
        if args.empty?
          setting.intern
        else
          { setting.intern => args.first }
        end
      end
    }

    def initialize &block
      @config = Zabby::Config.new &block
      @connection = Zabby::Connection.new
      @pure_binding = instance_eval "binding"

      if Object.const_defined?(:Readline)
        @readline = true
        Readline.basic_word_break_characters = ""
			  Readline.completion_append_character = nil
			  #Readline.completion_proc = completion_proc

			  $last_res = nil
      else
        @readline = false
      end
    end

    def setup &block
      @config.setup &block
    end

    def set(key_value = nil)
      if key_value.nil?
        @config.list
      elsif [ String, Symbol ].include?(key_value.class)
        puts "#{key_value} = #{@config.send(key_value)}"
      elsif key_value.instance_of? Hash
        key = key_value.keys.first
        value = key_value[key]
        @config.send(key, value)
      end
    end

    def login
      @connection.login(@config)
    end

    def logout
      @connection.logout
    end

    def logged_in?
      @connection.logged_in?
    end

    def version
      Zabby::VERSION
    end

    # @param command_file [String] Filename containing commands to execute.
    # @param block [Proc] A block containing commands to execute.
    def run(command_file = nil, &block)
      unless command_file.nil?
        commands = File.read(command_file)
        instance_eval(commands)
      end
      instance_eval(&block) if block_given?
    end

    # Execute an irb like shell in which we can type Zabby commands.
    def shell
      raise RuntimeError.new("Shell cannot run because 'readline' is missing.") if !@readline

      puts "** This is an experimental Zabbix Shell. Multiline commands do not work for e.g. **"
      loop do
        cmd = Readline.readline('zabby> ')

        exit(0) if cmd.nil? or cmd == 'exit'
        next if cmd == ""
        Readline::HISTORY.push(cmd)

        execute(cmd)
      end
    end

    private

    # Run a single command.
    # @param cmd [String] A command to execute in the object's context.
    def execute(cmd)
      res = eval(cmd, @pure_binding)
      $last_res = res
      eval("_ = $last_res", @pure_binding)
      print_result res
    rescue ::Exception => e
      puts "Exception #{e.class} -> #{e.message}"
      e.backtrace.each do |t|
        puts "   #{::File.expand_path(t)}"
      end
    end

    def print_result(res)
      if res.kind_of? String
        puts res
      else
        puts "=> #{res.inspect}"
      end
    end
  end
end