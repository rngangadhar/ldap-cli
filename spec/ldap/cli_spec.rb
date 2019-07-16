# frozen_string_literal: true

require 'ldap/cli'
require 'yaml'

RSpec.describe Ldap::Cli do
  before(:all) do
    @env = 'test'
    @database_details = YAML.safe_load(
      File.read('spec/config/database.yml'),
      [Symbol]
    )[@env]
    @config = YAML.safe_load(File.read('spec/config/ldap.yml'), [Symbol])
    @fixtures_path = 'spec/fixtures'
    @headers = %w[cn sn mail uid].freeze
    @table_dn = @config['person']['dn']
    @fixtures_path = 'spec/fixtures'
    @ldap = Ldap::Cli.new(@database_details, @headers, @table_dn)
  end

  before(:all) do
    @ldap.delete dn: "uid=5000, #{@table_dn}"
    @ldap.delete dn: "uid=10000, #{@table_dn}"
  end

  after(:all) do
    @ldap.delete dn: "uid=5000, #{@table_dn}"
    @ldap.delete dn: "uid=10000, #{@table_dn}"
  end

  describe 'reading from csv and upload to ldap' do
    it 'should check if connected to ldap' do
      expect(@ldap.bind).to eq(true)
    end

    it 'should check if input csv file have expected headers' do
      expect do
        @ldap.import(@fixtures_path + '/invalid_data.csv')
      end.to raise_error('Require headers to process the file.')
    end

    it 'should be success' do
      @ldap.import(@fixtures_path + '/valid_data.csv')
      expect(@ldap.errors.empty?).to eq(true)
    end
  end

  describe 'writing to csv from ldap' do
    context 'should generate csv' do
      before(:all) do
        @output_file_path = @fixtures_path + '/ldap_data_output.csv'
        @ldap.export(output_file_path: @output_file_path)
      end

      after(:all) do
        FileUtils.rm_f(@output_file_path)
      end

      it 'creates a results csv file' do
        expect(File.file?(@output_file_path)).to be true
      end

      it 'without filter with valid search results' do
        data = CSV.read(@output_file_path)
        expect(data.flatten).to include('Hunfredo Lamyman')
      end

      it 'without filter with valid search count' do
        data = CSV.read(@output_file_path)
        expect(data.size).to be > 1
      end
    end
  end

  context 'should generate csv with specific filter' do
    before(:all) do
      filter = 'cn=Hunfredo*'
      @output_file_path = @fixtures_path + '/ldap_data_output_with_filter.csv'
      @ldap.export(output_file_path: @output_file_path, filter: filter)
    end

    after(:all) do
      FileUtils.rm_f(@output_file_path)
    end

    it 'creates a results csv file' do
      expect(File.file?(@output_file_path)).to be true
    end

    it 'with filter with valid search results' do
      data = CSV.read(@output_file_path)
      expect(data.flatten).to include('Hunfredo Lamyman')
    end

    it 'with filter with valid search count' do
      data = CSV.read(@output_file_path)
      expect(data.size).to eq(2)
    end
  end
end
