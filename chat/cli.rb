#!/usr/bin/env ruby

require 'bundler/setup'

jid, password, operator_jid = ARGV[0..2]

require_relative './application'

Chat::Application.new(jid, password, operator_jid).start
