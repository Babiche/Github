require_relative 'norm/norm'
require_relative 'additional_sc/score_additional_sc'

module Algorithm
  # Adds up all the results found in the three parts of the score
  class TotalScore
    attr_reader :score

    REQUIRED_BUCKETS_KNOWN_NO_USER = 2
    REQUIRED_BUCKETS_KNOWN = 5

    def initialize(company)
      @norm             = Algorithm::Norm::Score.new(company)
      @additional_sc    = Algorithm::AdditionalSC::Score.new(company)

      @score = if company.type == 'Unclaimed Company'
                 count_buckets_known >= REQUIRED_BUCKETS_KNOWN_NO_USER ? calc_total_score : nil
               else
                 count_buckets_known >= REQUIRED_BUCKETS_KNOWN ? calc_total_score : nil
               end
    end

    def count_buckets_known
      norm_buckets_known = [
          @norm.time_in_business_known?,
          @norm.company_size_known?,
          @norm.social_media_known?,
          @norm.website_known?,
          @norm.member_of_industry_association?
      ]

      additional_buckets_known = [
          @additional_sc.verification_level?,
          @additional_sc.peer_reviews?,
          @additional_sc.trade_reviews?,
          @additional_sc.historic_trades?
      ]

      norm_buckets_known.count(true) + additional_buckets_known.count(true)
    end

    def calc_total_score
      ((calc_total_numerator / calc_total_denominator) * 1000).round(0)
    end

    def calc_total_numerator
      (@norm.numerator + @additional_sc.numerator).to_f
    end

    def calc_total_denominator
      (@norm.denominator + @additional_sc.denominator).to_f
    end
  end
end