module TdAmeritradeApi
  class Scraper

    DEFAULT_OPTIONS = {
        url: 'https://www.advisorservices.com/',
        date: Date.today,
        security_questions: {}
    }

    attr_reader :username, :password, :options, :agent, :files

    def initialize(username, password, options = {})
      @username = username
      @password = password
      @options = DEFAULT_OPTIONS.merge options
      @agent = Mechanize.new
      @files = []
    end

    def run
      agent.get("#{options[:url]}servlet/advisor/LogIn") do |login_page|
        # login
        login_form = login_page.forms.first
        login_form.field_with(name: 'USERID').value = username
        login_form.field_with(name: 'PASSWORD').value = password
        after_login_page = login_form.submit

        TDAmeritradeAPI.logger.debug after_login_page.body

        # optional security questions
        if security_form = after_login_page.form_with(name: 'securityQuestion')
          question = security_form.field_with(name: 'question').value
          security_form.field_with(name: 'answer').value = options[:security_questions][question]
          security_form.radiobuttons_with(name: 'computerType').first.check
          after_login_page = security_form.submit

          TDAmeritradeAPI.logger.debug after_login_page.body
        end

        # navigate to downloads page
        downloads_page = after_login_page.link_with(text: 'Download Files').click
        TDAmeritradeAPI.logger.debug downloads_page.body

        # filter downloads to specific date
        find_files_form = downloads_page.form_with(name: 'find_files').first
        find_files_form.field_with(name: 'fromDate').value = options[:date].strftime('%m/%d/%Y')
        find_files_form.field_with(name: 'toDate').value = options[:date].strftime('%m/%d/%Y')
        downloads_page = find_files_form.submit

        TDAmeritradeAPI.logger.debug downloads_page.body

        # download files
        downloads_page.links_with(title: 'Download ZIP').each do |download_link|
          files << download_link.click
        end
      end

      return files
    end

  end
end