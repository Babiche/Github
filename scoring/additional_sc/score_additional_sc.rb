require './models/due_diligence/due_diligence_check'
require './models/company/company_review'
require './models/trading/trade'
require './models/trading/trade_review'
require './models/impex/data'
require_relative 'reviews'
require_relative 'trade_history'

module Algorithm
  module AdditionalSC
    # Calculates the part of the score concerning information specifically known to Scrap Connection
    class Score
      attr_accessor :company, :denominator, :numerator

      POINTS_SC_VERIFICATION = {
          non_verified: 0,
          bronze:       25,
          silver:       50,
          gold:         80,
          denominator:  80
      }.freeze

      DEDUCTION_SC_VERIFICATION_UNKNOWN = -15
      DEDUCTION_PEER_REVIEWS_UNKNOWN    = -25
      DEDUCTION_TRADE_REVIEWS_UNKNOWN   = -50
      DEDUCTION_TRADE_HISTORY_UNKNOWN   = -10

      TRADE_HISTORY_DENOMINATOR         = 200

      def initialize(company)
        @numerator           = 0
        @denominator         = 0
        @company             = company
        @trade_history_score = Algorithm::AdditionalSC::TradeHistory.new

        calc_numerator
        calc_denominator
      end

      def calc_numerator
        @numerator += verification_level? ? sc_verification        : DEDUCTION_SC_VERIFICATION_UNKNOWN
        @numerator += peer_reviews?       ? reviews_points(:peer)  : DEDUCTION_PEER_REVIEWS_UNKNOWN
        @numerator += trade_reviews?      ? reviews_points(:trade) : DEDUCTION_TRADE_REVIEWS_UNKNOWN
        @numerator += historic_trades?    ? trade_history          : DEDUCTION_TRADE_HISTORY_UNKNOWN
      end

      def calc_denominator
        @denominator += POINTS_SC_VERIFICATION[:denominator] if verification_level?
        @denominator += peer_review_denominator              if peer_reviews?
        @denominator += trade_review_denominator             if trade_reviews?
        @denominator += TRADE_HISTORY_DENOMINATOR            if historic_trades?
      end

      def sc_verification
        return POINTS_SC_VERIFICATION[:gold] if company.type == 'Unclaimed Company'

        case company.dd_level
        when 1
          POINTS_SC_VERIFICATION[:bronze]
        when 2
          POINTS_SC_VERIFICATION[:silver]
        when 3
          POINTS_SC_VERIFICATION[:gold]
        else
          POINTS_SC_VERIFICATION[:non_verified]
        end
      end

      def reviews_points(review_type)
        reviews      = send("#{review_type}_reviews")
        review_score = Algorithm::AdditionalSC::Reviews.new
        review_score.get_points(review_type, reviews, company.type)
      end

      def peer_reviews
        @peer_reviews ||= CompanyReview.where(company_id: company.id).all
      end

      def trade_reviews
        @trade_reviews ||= buyer_trade_reviews + seller_trade_reviews
      end

      def buyer_trade_reviews
        TradeReview
            .where(reviewer_type: 'buyer')
            .where(trade: Trade.where(seller_co_id: company.id))
            .all
      end

      def seller_trade_reviews
        TradeReview
            .where(reviewer_type: 'seller')
            .where(trade: Trade.where(buyer_co_id: company.id))
            .all
      end

      def trade_history
        @trade_history_score.get_points(all_trades)
      end

      def all_trades
        @all_trades ||= ImpexData
                            .where(Sequel.|({exporter_company_id: company.id}, {importer_company_id: company.id}))
                            .where{arrival_date >= 12.months.ago}
                            .all
      end

      def peer_review_denominator
        if peer_reviews.count <= 2
          peer_reviews.count * Algorithm::AdditionalSC::Reviews::POINTS_PR[:five_star]
        else
          Algorithm::AdditionalSC::Reviews::POINTS_PR[:max]
        end
      end

      def trade_review_denominator
        if trade_reviews.count <= 3
          trade_reviews.count * Algorithm::AdditionalSC::Reviews::POINTS_TR[:five_star]
        else
          Algorithm::AdditionalSC::Reviews::POINTS_TR[:max]
        end
      end

      def verification_level?
        company.dd_level.present?
      end

      def peer_reviews?
        peer_reviews.present?
      end

      def trade_reviews?
        trade_reviews.present?
      end

      def historic_trades?
        all_trades.count >= 5
      end
    end
  end
end