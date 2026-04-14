# frozen_string_literal: true

require 'erb'
require_relative 'helpers/field_helper'

module Micontrato
  class HtmlGenerator
    include Helpers::FieldHelper

    def initialize(contract:, mica_rent: nil, show_admin_info: false, watermark_image: nil)
      @contract = contract
      @mica_rent = mica_rent
      @show_admin_info = show_admin_info
      @watermark_image = watermark_image
      @cover_sections = contract.cover_sections
      all_clauses = contract.clauses.respond_to?(:reorder) ? contract.clauses.reorder(:position) : contract.clauses.sort_by(&:position)
      @header_clauses = all_clauses.select { |c| c.section == 'header' }
      @clauses = all_clauses.reject { |c| c.section == 'header' }
    end

    def generate
      template = File.read(template_path)
      ERB.new(template).result(binding)
    end

    private

    def clause_image_src(clause)
      if clause.clause_attachment.present?
        clause.clause_attachment.url
      elsif clause.text.present?
        clause.text
      end
    end

    def render_clauses(clauses)
      html = +'' # Mutable string needed because frozen_string_literal is enabled
      clauses.each do |clause|
        case clause.clause_type
        when 'image'
          image_src = clause_image_src(clause)
          if image_src.present?
            html << '<div style="display: table; width: 100%; height: 355.6mm; text-align: center;">'
            html << '<div style="display: table-cell; vertical-align: middle;">'
            html << "<img src=\"#{image_src}\" style=\"max-width: 100%; height: auto;\" />"
            html << '</div></div>'
          end
        when 'standard'
          html << '<div class="clause">'
          if clause.show_title && clause.title.present?
            html << "<p><strong>#{clause.title}</strong></p>"
          end
          html << clause.text.to_s if clause.text.present?
          html << '</div>'
        end
      end
      html
    end

    def template_path
      File.join(__dir__, 'templates', 'contract.html.erb')
    end
  end
end
