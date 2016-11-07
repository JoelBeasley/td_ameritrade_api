module TdAmeritradeApi
  class Scraper
    include Capybara::DSL

    DEFAULT_OPTIONS = {
        url: 'https://www.advisorservices.com/',
        date: Date.today,
        security_questions: {}
    }

    attr_reader :username, :password, :options, :agent, :files

    def initialize(username, password, options = {})
      Capybara.default_driver = :poltergeist
      Capybara.default_max_wait_time = 5

      Capybara.register_driver :poltergeist do |app|
        Capybara::Poltergeist::Driver.new(app, js_errors: false)
      end

      @username = username
      @password = password
      @options = DEFAULT_OPTIONS.merge options
      @files = []
    end

    def run
      visit "#{options[:url]}servlet/advisor/LogIn"

      TDAmeritradeAPI.logger.debug page.body

      fill_in 'USERID', with: username
      fill_in 'PASSWORD', with: password
      find('a#loginBtn').click

      TDAmeritradeAPI.logger.debug body

      # optional security questions
      if has_selector?('form[name="securityQuestion"]')
        question = find('input[name="question"]', visible: false).value
        fill_in 'answer', with: options[:security_questions][question]
        find('input[name="computerType"][value="private"]').click
        find('a#submitBtn').click

        TDAmeritradeAPI.logger.debug body
      end

      within_frame 'main' do
        # navigate to downloads page
        find('#accountTools').click
        first('#accountTools_dd_nav a[href="/servlet/advisor/accounttools/filedownloads"]').click
        TDAmeritradeAPI.logger.debug body

        # filter downloads to specific date
        fill_in 'fromDate', with: options[:date].strftime('%m/%d/%Y')
        fill_in 'toDate', with: options[:date].strftime('%m/%d/%Y')
        check 'filesDownloadedBefore'
        find('a#filterbtn').click

        # grab the files
        all('a[title="Download ZIP"]').each do |link|
          files << link[:href]
        end
      end

      return files
    end

  end
end