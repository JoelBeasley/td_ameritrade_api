module TDAmeritradeAPI
  class Entity

    attr_reader :file_name, :date

    def initialize(attributes = {})
      attributes.each { |k, v| instance_variable_set("@#{k}", v) }
      @date = date_from_file_name
    end

    def self.import(file, file_name)
      entities = []

      CSV.foreach(file) do |row|
        attributes = Hash[self::HEADERS.zip(row)]
        attributes[:file_name] = file_name
        entities << new(attributes)
      end

      return entities
    end

    def date_from_file_name
      raw_date = file_name.gsub(/\D/, '')
      date = Date.strptime(raw_date, '%y%m%d')

      return date
    end

    def parse_date(date_str)
      date_str = date_str.gsub(/\D/, '')

      if date_str.length == 6
        Date.strptime(date_str, '%m%d%y')
      elsif date_str.length == 8
        Date.strptime(date_str, '%m%d%Y')
      else
        nil
      end
    end

  end

  class CostBasisReconciliation < Entity
    HEADERS = %w(custodial_id business_date account_number account_type security_type symbol current_quantity cost_basis
                adjusted_cost_basis unrealized_gain_loss cost_basis_fully_known certified_flag original_purchase_date
                original_purchase_price wash_sale_indicator disallowed_amount averaged_cost book_cost book_proceeds
                fixed_income_cost_adjustment id security_name covered unknown_total)

    attr_reader :custodial_id, :business_date, :account_number, :account_type, :security_type, :symbol,
                :current_quantity, :cost_basis, :adjusted_cost_basis, :unrealized_gain_loss, :cost_basis_fully_known,
                :certified_flag, :original_purchase_date, :original_purchase_price, :wash_sale_indicator,
                :disallowed_amount, :averaged_cost, :book_cost, :book_proceeds, :fixed_income_cost_adjustment, :id,
                :security_name, :covered, :unknown_total

    def initialize(attributes = {})
      super
      @business_date = parse_date(attributes['business_date'].to_s) unless @business_date.is_a?(Date)
      @original_purchase_date = parse_date(attributes['original_purchase_date'].to_s) unless @original_purchase_date.is_a?(Date)

      @cost_basis_fully_known = attributes['cost_basis_fully_known'].to_s == 'T'
      @certified_flag = attributes['certified_flag'].to_s == 'Y'
      @covered = attributes['covered'].to_s == 'Y'
    end
  end

  class Demographic < Entity
    HEADERS = %w(company first_name last_name address_1 address_2 address_3 address_4 address_5 address_6 city state zip ssn account_number advisor_id taxable phone_number fax_number account_type objective billing_account_number default_account primary_state performance_inception_date billing_inception_date federal_tax_rate state_tax_rate months_in_short_term_holding_period fiscal_year_end use_average_cost_accounting display_accrued_interest display_accrued_dividends display_accrued_gains birth_date discount_rate payout_rate)

    attr_reader :company, :first_name, :last_name, :address_1, :address_2, :address_3, :address_4, :address_5,
                :address_6, :city, :state, :zip, :ssn, :account_number, :advisor_id, :taxable, :phone_number,
                :fax_number, :account_type, :objective, :billing_account_number, :default_account, :primary_state,
                :performance_inception_date, :billing_inception_date, :federal_tax_rate, :state_tax_rate,
                :months_in_short_term_holding_period, :fiscal_year_end, :use_average_cost_accounting,
                :display_accrued_interest, :display_accrued_dividends, :display_accrued_gains, :birth_date,
                :discount_rate, :payout_rate
  end

  class InitialPosition < Entity
  end

  class Position < Entity
    HEADERS = %w(account_number account_type security_type symbol quantity amount)

    attr_reader :account_number, :account_type, :security_type, :symbol, :quantity, :amount
  end

  class Price < Entity
    HEADERS = %w(symbol security_type date price factor)

    attr_reader :symbol, :security_type, :price, :factor
  end

  class Security < Entity
    HEADERS = %w(symbol security_type description expiration_date call_date call_price issue_date first_coupon interest_rate share_per_contract annual_income_amount comment)

    attr_reader :symbol, :security_type, :description, :expiration_date, :call_date, :call_price, :issue_date,
                :first_coupon, :interest_rate, :share_per_contract, :annual_income_amount, :comment

    def initialize(attributes = {})
      super
      @expiration_date = parse_date(attributes['expiration_date'].to_s) unless @expiration_date.is_a?(Date)
      @call_date = parse_date(attributes['call_date'].to_s) unless @call_date.is_a?(Date)
      @issue_date = parse_date(attributes['issue_date'].to_s) unless @issue_date.is_a?(Date)
    end
  end

  class Transaction < Entity
    HEADERS = %w(broker_account file_date account_number transaction_code cancel_status_flag symbol security_type trade_date quantity net_amount principal_amount broker_fee other_fees settle_date from_to_account account_type accrued_interest closing_account_method comments)

    attr_reader :broker_account, :file_date, :account_number, :transaction_code, :cancel_status_flag,
                :symbol, :security_type, :trade_date, :quantity, :net_amount, :principal_amount, :broker_fee,
                :other_fees, :settle_date, :from_to_account, :account_type, :accrued_interest, :closing_account_method,
                :comments

    def initialize(attributes = {})
      super
      @file_date = parse_date(attributes['file_date'].to_s) unless @file_date.is_a?(Date)
      @trade_date = parse_date(attributes['trade_date'].to_s) unless @trade_date.is_a?(Date)
    end
  end
end