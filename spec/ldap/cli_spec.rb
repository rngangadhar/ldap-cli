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
    @table_dn = @config['person']['dn']
    @ldap = Ldap::Cli.new(@database_details, %w[cn sn mail uid], @table_dn)
    @ldap.delete dn: "uid=5000, #{@table_dn}"
    @ldap.delete dn: "uid=10000, #{@table_dn}"
  end

  after(:all) do
    @ldap.delete dn: "uid=5000, #{@table_dn}"
    @ldap.delete dn: "uid=10000, #{@table_dn}"
  end

  shared_examples 'data check csv' do
    it 'creates a csv file with results' do
      expect(File.file?(@output_file_path)).to be true
    end

    it 'validates search results' do
      expect(CSV.read(@output_file_path).flatten).to include('Lamyman')
    end
  end

  describe 'read from csv and upload to ldap' do
    it 'checks the ldap connection' do
      expect(@ldap.bind).to eq(true)
    end

    it 'checks the input csv file for expected headers' do
      expect do
        @ldap.import('spec/fixtures/invalid_data.csv')
      end.to raise_error('Require headers to process the file.')
    end

    it 'succeeds on importing a csv with valid data' do
      @ldap.import('spec/fixtures/valid_data.csv')
      binding.pry
      expect(@ldap.errors.empty?).to eq(true)
    end
  end

  describe 'exporting to csv from ldap without filter' do
    context 'generating csv file' do
      before(:all) do
        @output_file_path = 'spec/fixtures/ldap_data_output.csv'
        @ldap.export(output_file_path: @output_file_path)
      end

      after(:all) do
        FileUtils.rm_f(@output_file_path)
      end

      include_examples 'data check csv'

      it 'validates search result count' do
        expect(CSV.read(@output_file_path).size).to eq(3)
      end
    end
  end

  context 'generates csv with specific filter' do
    before(:all) do
      @output_file_path = 'spec/fixtures/ldap_data_output_with_filter.csv'
      @ldap.export(output_file_path: @output_file_path, filter: 'cn=Hunfredo*')
    end

    after(:all) do
      FileUtils.rm_f(@output_file_path)
    end

    include_examples 'data check csv'

    it 'validates search result count' do
      expect(CSV.read(@output_file_path).size).to eq(2)
    end
  end
end
