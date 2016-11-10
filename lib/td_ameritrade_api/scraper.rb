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
      TDAmeritradeAPI.logger.info 'Started TDAmeritradeAPI::Scraper#run'
      time = Benchmark.realtime do
        fetch_zip_files
        extract_file_contents
        process_entities
      end
      TDAmeritradeAPI.logger.info "Completed in #{time * 1000}ms"
    end

    def fetch_zip_files
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
      if has_selector?('frame[name="main"]')

        # navigate to downloads page
        within_frame 'main' do
          TDAmeritradeAPI.logger.info ' Going to the downloads page'
          find('#accountTools').click
          first('#accountTools_dd_nav a[href="/servlet/advisor/accounttools/filedownloads"]').click
        end

        # filter downloads to specific date
        within_frame 'main' do
          TDAmeritradeAPI.logger.info ' Filtering downloads'
          # using normal Capybara form fill methods do not work for unknown reasons
          find('#invoice_fromdate').set options[:date].strftime('%m/%d/%Y')
          find('#invoice_todate').set options[:date].strftime('%m/%d/%Y')
          execute_script '$(\'[name="filesDownloadedBefore"]\').attr(\'checked\', true);'
          execute_script 'document.find_files.submit();'
        end

        # grab files
        within_frame 'main' do
          TDAmeritradeAPI.logger.info ' Downloading ZIP Files'

          if has_selector?('#files_that_match a[title="Download ZIP"]')
            all('#files_that_match a[title="Download ZIP"]').each do |link|
              zip_files << open(link[:href])
            end
          end
        end

      else
        raise 'Failed login'
      end

    rescue Exception => e
      TDAmeritradeAPI.logger.debug body
      raise
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

    private

    def security_question_answer(question)
      if options[:security_questions].has_key?(question)
        options[:security_questions][question]
      else
        raise "Unknown security question: #{question}"
      end
    end

  end
end