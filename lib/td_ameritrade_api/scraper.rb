module TDAmeritradeAPI
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
        fill_in 'fromDate', with: options[:date].strftime('%m/%d/%Y')
        fill_in 'toDate', with: options[:date].strftime('%m/%d/%Y')
        find('input[name="filesDownloadedBefore"]').click
        execute_script 'document.find_files.submit();'
      end

      # grab files
      within_frame 'main' do
        all('a[title="Download ZIP"]').each do |link|
          files << open(link[:href])
        end
      end

      return files
    end

  end
end