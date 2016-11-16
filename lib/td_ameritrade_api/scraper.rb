module TDAmeritradeAPI
  class Scraper
    include Capybara::DSL

    DEFAULT_OPTIONS = {
        url: 'https://www.advisorservices.com/',
        security_questions: {},
        date_start: Date.today,
        date_end: Date.today,
        advisor: 'A',
        file_type: 'A'
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
      TDAmeritradeAPI.logger.info 'Started TDAmeritradeAPI::Scraper#run'

      time = Benchmark.realtime do
        login
        navigate_to_downloads
        filter_downloads
        fetch_zip_files
        extract_file_contents
        process_entities
      end

      TDAmeritradeAPI.logger.info "Completed in #{time * 1000}ms"
    end

    private

    def login
      TDAmeritradeAPI.logger.debug ' Logging in'
      visit "#{options[:url]}servlet/advisor/LogIn"

      fill_in 'USERID', with: username
      fill_in 'PASSWORD', with: password
      find('a#loginBtn').click

      # optional security questions
      if has_selector?('form[name="securityQuestion"]')
        TDAmeritradeAPI.logger.info ' Answering security questions'
        question = find('input[name="question"]', visible: false).value
        fill_in 'answer', with: security_question_answer(question)
        find('input[name="computerType"][value="private"]').click
        find('a#submitBtn').click
      end

      # ensure we've logged in
      unless has_selector?('frame[name="main"]')
        TDAmeritradeAPI.logger.debug body
        raise 'Failed login'
      end
    end

    def navigate_to_downloads
      within_frame 'main' do
        begin
          TDAmeritradeAPI.logger.info ' Going to the downloads page'
          find('#accountTools').click
          first('#accountTools_dd_nav a[href="/servlet/advisor/accounttools/filedownloads"]').click

        rescue Exception => e
          TDAmeritradeAPI.logger.debug body
          TDAmeritradeAPI.logger.error e.message
          raise
        end
      end
    end

    def filter_downloads
      within_frame 'main' do
        begin
          TDAmeritradeAPI.logger.info ' Filtering downloads'
          # using normal Capybara form fill methods do not work for unknown reasons
          find('#invoice_fromdate').set options[:date_start].strftime('%m/%d/%Y')
          find('#invoice_todate').set options[:date_end].strftime('%m/%d/%Y')
          execute_script "$('[name=\"filesDownloadedBefore\"]').attr('checked', true);"
          execute_script "$('[name=\"advisor\"]').val('#{options[:advisor]}')"
          execute_script "$('[name=\"fileType\"]').val('#{options[:file_type]}')"
          execute_script 'document.find_files.submit();'

          # without sleeping, capybara doesn't know to wait for form submission and will throw errors when frame
          # refreshes during later execution
          sleep(1)

        rescue Exception => e
          TDAmeritradeAPI.logger.debug body
          TDAmeritradeAPI.logger.error e.message
          raise
        end
      end
    end

    def fetch_zip_files
      within_frame 'main' do
        begin
          TDAmeritradeAPI.logger.info ' Downloading ZIP Files'

          within('#files_that_match') do
            all('#files_that_match a[title="Download ZIP"]').each do |link|
              Rails.logger.info link[:href]
              zip_files << open(link[:href])
            end
          end

        rescue Exception => e
          TDAmeritradeAPI.logger.debug body
          TDAmeritradeAPI.logger.error e.message
          raise
        end
      end
    end

    def extract_file_contents
      TDAmeritradeAPI.logger.info ' Extracting ZIP files'
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
      TDAmeritradeAPI.logger.info ' Processing entities'
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

    def security_question_answer(question)
      if options[:security_questions].has_key?(question)
        options[:security_questions][question]
      else
        raise "Unknown security question: #{question}"
      end
    end

  end
end