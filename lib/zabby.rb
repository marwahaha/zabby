# -*- encoding: utf-8 -*-
# Author:: Farzad FARID (<ffarid@pragmatic-source.com>)
# Copyright:: Copyright (c) 2011 Farzad FARID
# License:: Simplified BSD License

require 'rubygems'
require 'json'
require 'net/http'
require 'net/https'
require 'openssl'
require 'uri'
require 'pp'

require 'zabby/version'
require 'zabby/exceptions'
require 'zabby/config'
require 'zabby/zobject'
require 'zabby/connection'
require 'zabby/runner'

module Zabby
  def self.init &block
    Zabby::Runner.instance &block
  end
end
