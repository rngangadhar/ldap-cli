# frozen_string_literal: true

require 'ldap/cli/version'
require 'rubygems'
require 'net/ldap'
require 'csv'
require 'pry'

module Ldap
  class Error < StandardError; end
  # Tool for reading/writing entries in an LDAP directory to/from CSV files
  class Cli
    attr_accessor :ldap, :headers, :table_dn, :errors

    def initialize(config, headers, table_dn)
      @ldap = Net::LDAP.new config
      @headers = headers
      @table_dn = table_dn
    end

    def bind
      ldap.bind
    end

    def delete(args)
      ldap.delete(args)
    end

    def valid_headers(input_headers = [])
      no_header = 'Require headers to process the file.'
      raise no_header unless (input_headers - headers).empty?
    end

    def import(input_file_path = nil)
      @errors = []
      CSV.foreach(input_file_path, headers: true, skip_blanks: true) do |row|
        valid_headers row.headers
        save_record(row)
      end
    end

    def export(args = {})
      @output_file_path = args[:output_file_path]
      @filter = args[:filter]
      add_header
      export_data
    end

    private

    def save_record(row)
      dn = dn_value(row)
      attr = row.to_h
      attr['objectclass'] = ['inetOrgPerson']
      if search(row['uid']).empty?
        ldap.add(dn: dn, attributes: attr)
      else
        ldap.modify dn: dn, attributes: attr
      end
      save_record_log(ldap, row)
    end

    def dn_value(row)
      "uid=#{row['uid']}, #{table_dn}"
    end

    def search(uid)
      ldap.search(
        base: table_dn,
        filter: "uid=#{uid}",
        scope: 1
      )
    end

    def add_header
      CSV.open(@output_file_path, 'w+', force_quotes: false) do |csv|
        csv << headers
      end
    end

    def export_data
      CSV.open(@output_file_path, 'a+', force_quotes: false) do |csv|
        ldap.search(base: table_dn, filter: @filter, scope: 1) do |entry|
          csv << headers.map { |x| entry.send(x).first }
        end
      end
    end

    def save_record_log(ldap, row)
      status = ldap.get_operation_result['message']
      error_message = ldap.get_operation_result.error_message
      if status == 'Success'
        puts "Entry created successfully for uid #{row['uid']}"
      elsif error_message.include?('did not contain any modifications')
        puts error_message
      else
        @errors << error_message
        puts error_message
      end
    end
  end
end
