module TDAmeritradeAPI
  class Entity

    def initialize(attributes = {})
      attributes.each { |k, v| instance_variable_set("@#{k}", v) }
    end

    def self.import(file)
      entities = []

      CSV.foreach(file) do |row|
        attributes = Hash[self.class::HEADERS.zip(row)]
        entities << self.class::MODEL.new(attributes)
      end

      return entities
    end

  end

  class CostBasisReconciliation < Entity
    HEADERS = %w(custodial_id business_date account_number account_type security_type symbol current_quantity cost_basis adjusted_cost_Basis unrealized_gain_loss cost_basis_fully_known certified_flag original_purchase_date original_purchase_price wash_sale_indicator disallowed_amount)

    attr_reader :custodial_id, :business_date, :account_number, :account_type, :security_type, :symbol,
                :current_quantity, :cost_basis, :adjusted_cost_Basis, :unrealized_gain_loss, :cost_basis_fully_known,
                :certified_flag, :original_purchase_date, :original_purchase_price, :wash_sale_indicator,
                :disallowed_amount
  end

  class DemographicFile < Entity
  end

  class InitialPosition < Entity
  end

  class Position < Entity
    HEADERS = %w(account_number account_type security_type symbol quantity amount)

    attr_reader :account_number, :account_type, :security_type, :symbol, :quantity, :amount
  end

  class Price < Entity
    HEADERS = %w(symbol security_type date price factor)

    attr_reader :symbol, :security_type, :date, :price, :factor
  end

  class Security < Entity
    HEADERS = %w(symbol security_type description expiration_date call_date call_price issue_date first_coupon interest_rate share_per_contract annual_income_amount comment)

    attr_reader :symbol, :security_type, :description, :expiration_date, :call_date, :call_price, :issue_date,
                :first_coupon, :interest_rate, :share_per_contract, :annual_income_amount, :comment
  end

  class Transaction< Entity
    HEADERS = %w(broker_account file_date account_number transaction_code activity cancel_status_flag symbol security_type trade_date quantity net_amount principal_amount broker_fee other_fees settle_date from_to_account account_type accrued_interest closing_account_method comments)

    attr_reader :broker_account, :file_date, :account_number, :transaction_code, :activity, :cancel_status_flag,
                :symbol, :security_type, :trade_date, :quantity, :net_amount, :principal_amount, :broker_fee,
                :other_fees, :settle_date, :from_to_account, :account_type, :accrued_interest, :closing_account_method,
                :comments
  end
end