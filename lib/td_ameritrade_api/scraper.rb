module TDAmeritradeAPI
  class Scraper
    include Capybara::DSL

    DEFAULT_OPTIONS = {
        url: 'https://www.advisorservices.com/',
        date: Date.today,
        security_questions: {}
    }

    attr_reader :username, :password, :options, :zip_files, :processed_files, :entities

    def initialize(username, password, options = {})
      Capybara.default_driver = :poltergeist
      Capybara.default_max_wait_time = 5

      Capybara.register_driver :poltergeist do |app|
        Capybara::Poltergeist::Driver.new(app, js_errors: false)
      end

      @username = username
      @password = password
      @options = DEFAULT_OPTIONS.merge options
      @zip_files = []
      @processed_files = []
      @entities = {}
    end

    def run
      fetch_zip_files
      extract_file_contents
      process_entities
    end

    def fetch_zip_files
      visit "#{options[:url]}servlet/advisor/LogIn"

      fill_in 'USERID', with: username
      fill_in 'PASSWORD', with: password
      find('a#loginBtn').click

      # optional security questions
      if has_selector?('form[name="securityQuestion"]')
        question = find('input[name="question"]', visible: false).value
        fill_in 'answer', with: options[:security_questions][question]
        find('input[name="computerType"][value="private"]').click
        find('a#submitBtn').click
      end

      # navigate to downloads page
      within_frame 'main' do
        find('#accountTools').click
        first('#accountTools_dd_nav a[href="/servlet/advisor/accounttools/filedownloads"]').click
      end

      # filter downloads to specific date
      within_frame 'main' do
        # using normal Capybara form fill methods do not work for unknown reasons
        find('#invoice_fromdate').set options[:date].strftime('%m/%d/%Y')
        find('#invoice_todate').set options[:date].strftime('%m/%d/%Y')
        execute_script '$(\'[name="filesDownloadedBefore"]\').attr(\'checked\', true);'
        execute_script 'document.find_files.submit();'

        # manual sleep needed to ensure Capybara waits for page refresh
        sleep 3
      end

      # grab files
      within_frame 'main' do
        all('#files_that_match a[title="Download ZIP"]').each do |link|
          zip_files << open(link[:href])
        end
      end
    end

    def extract_file_contents
      zip_files.each do |file|
        Zip::File.open_buffer(file) do |ar|
          ar.each do |f|
            processed_files << {
                advisor: file.meta['filename'].split('.')[0][1..-7],
                name: f.name,
                contents: f.get_input_stream.read
            }
          end
        end
      end
    end

    def process_entities
      processed_files.each do |file|
        entities[file[:advisor]] ||= {
            'SEC' => [],
            'PRI' => [],
            'POS' => [],
            'TRD' => [],
            'TRN' => [],
            'INI' => [],
            'CBL' => []
        }

        importer = Importer.new(tempfile(file[:name], file[:contents]), file[:name])
        file_type = file[:name].split('.')[1]

        entities[file[:advisor]][file_type].concat importer.run
      end

      return entities
    end

    def tempfile(name, contents)
      tempfile = Tempfile.new(name.split('.'))
      tempfile << contents
      tempfile
    end

  end
end