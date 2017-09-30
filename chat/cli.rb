#!/usr/bin/env ruby

require 'bundler/setup'

jid, password, operator_jid, cobrowsing_link = ARGV[0..3]


require_relative './application'

Chat::Application.new(jid, password, operator_jid).start("Please cobrowse with me: #{cobrowsing_link}")
