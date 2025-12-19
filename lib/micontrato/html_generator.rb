# frozen_string_literal: true

require 'erb'
require_relative 'helpers/field_helper'

module Micontrato
  class HtmlGenerator
    include Helpers::FieldHelper

    def initialize(contract:, mica_rent: nil, show_admin_info: false)
      @contract = contract
      @mica_rent = mica_rent
      @show_admin_info = show_admin_info
      @cover_sections = contract.cover_sections
      @clauses = contract.clauses.respond_to?(:reorder) ? contract.clauses.reorder(:position) : contract.clauses.sort_by(&:position)
    end

    def generate
      template = File.read(template_path)
      ERB.new(template).result(binding)
    end

    private

    def template_path
      File.join(__dir__, 'templates', 'contract.html.erb')
    end
  end
end
