# frozen_string_literal: true

class Site < ActiveRecord::Base
  SORT_COLUMNS = %w[id created_at updated_at].freeze
  ORDERS = %w[asc desc].freeze

  def per_page
    super || '10'
  end

  def default_order
    super.blank? ? 'created_at DESC' : "id #{super}"
  end

  def method_missing(method, *args)
    if method.to_s.match?(/=$/)
      super
    else
      option = Option.where(name: method).first
      option.value
    end
  end
end
