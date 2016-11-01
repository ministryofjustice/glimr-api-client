class CaseRequest
  include ActiveModel::Model

  attr_accessor :case_reference,
    :confirmation_code,
    :fees

  def initialize(case_reference, confirmation_code)
    @case_reference = case_reference
    @confirmation_code = confirmation_code
    @fees = []
  end

  validates :case_reference, presence: true

  def process!
    glimr_case.fees.each do |fee|
      fees << prepare_fee(fee)
    end
  end

  def all_fees_paid?
    fees.all?(&:paid?)
  end

  def fees?
    fees.present?
  end

  private

  def prepare_fee(fee)
    Fee.create(
      case_title: glimr_case.title,
      description: fee.description,
      amount: fee.amount,
      glimr_id: fee.glimr_id
    )
  end

  def glimr_case
    @glimr_case_request ||= GlimrApiClient::Case.find(case_reference, confirmation_code)
  end
end
