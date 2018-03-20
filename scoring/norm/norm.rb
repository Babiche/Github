require './models/due_diligence/due_diligence_check'
require './models/company/company_badge'
require 'yaml'

module Algorithm
  module Norm
    # Calculates the part of the score concerning public available information
    class Score
      attr_accessor :company

      DENOMINATOR_NORM = 275

      POINTS_TIME_IN_BUSINESS = {
          less_than_a_year:           20,
          between_one_and_two_years:  40,
          between_two_and_five_years: 60,
          between_five_and_ten_years: 80,
          over_ten_years:             100,
          denominator:                100
      }.freeze

      POINTS_COMPANY_SIZE = {
          '1'              => 10,
          '2 - 10'         => 15,
          '11 - 50'        => 20,
          '51 - 200'       => 25,
          '201 - 500'      => 30,
          '501 - 1,000'    => 35,
          '1,001 - 5,000'  => 40,
          '5,001 - 10,000' => 45,
          '10,000+'        => 50,
          denominator:        50
      }.freeze

      POINTS_SOCIAL_MEDIA = 15
      POINTS_WEBSITE = 30
      POINTS_MEMBER_INDUSTRY_ASSOCIATION = 80

      def initialize(company)
        @numerator_norm = 0
        @company        = company

        calc_numerator
      end

      def calc_numerator
        @numerator_norm += time_in_business_points            if time_in_business_known?
        @numerator_norm += company_size_points                if company_size_known?
        @numerator_norm += POINTS_SOCIAL_MEDIA                if social_media_known?
        @numerator_norm += POINTS_WEBSITE                     if website_known?
        @numerator_norm += POINTS_MEMBER_INDUSTRY_ASSOCIATION if member_of_industry_association?
      end

      def calc_denominator
        denominator_norm = 0
        denominator_norm += POINTS_TIME_IN_BUSINESS[:denominator] if time_in_business_known?
        denominator_norm += POINTS_COMPANY_SIZE[:denominator]     if company_size_known?
        denominator_norm += POINTS_SOCIAL_MEDIA                   if social_media_known?
        denominator_norm += POINTS_WEBSITE                        if website_known?
        denominator_norm += POINTS_MEMBER_INDUSTRY_ASSOCIATION    if member_of_industry_association?
        denominator_norm
      end

      def time_in_business_points
        case company.in_business_years
        when 0..1
          POINTS_TIME_IN_BUSINESS[:less_than_a_year]
        when 1..2
          POINTS_TIME_IN_BUSINESS[:between_one_and_two_years]
        when 2..5
          POINTS_TIME_IN_BUSINESS[:between_two_and_five_years]
        when 5..10
          POINTS_TIME_IN_BUSINESS[:between_five_and_ten_years]
        else
          POINTS_TIME_IN_BUSINESS[:over_ten_years]
        end
      end

      def company_size_points
        POINTS_COMPANY_SIZE.each do |size, points|
          return points if company.size.to_s == size.to_s
        end
        0
      end

      def time_in_business_known?
        company.date_incorporated.present?
      end

      def company_size_known?
        company.size.present?
      end

      def social_media_known?
        company.dd_check_confirmed?(:linkedin_profile)
      end

      def website_known?
        company.dd_check_confirmed?(:website) || company[:website].present?
      end

      def member_of_industry_association?
        badges = YAML.load_file('config/badges.yaml')
        badge_names = badges.keys.select { |name| name =~ /trade_/ }

        badge_names.each do |badge_name|
          return true if company.has_badge?(badge_name)
        end
        false
      end

      def denominator
        company.type == 'Unclaimed Company' ? calc_denominator : DENOMINATOR_NORM
      end

      def numerator
        @numerator_norm
      end
    end
  end
end