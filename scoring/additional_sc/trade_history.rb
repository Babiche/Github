module Algorithm
  module AdditionalSC
    # Determines points for trade history part of additional SC
    class TradeHistory
      # TH stands for Trade History

      POINTS_TH = {
          at_least_5:  100,
          at_least_7:  125,
          at_least_12: 150,
          at_least_18: 175,
          at_least_24: 200
      }.freeze

      TRADE_HISTORY_DENOMINATOR = 200

      def get_points(trades)
        @count = trades.count

        assign_points
      end

      def assign_points
        case @count
          when 5...7
            calculate_points(:at_least_5, :at_least_7, 5)
          when 7...12
            calculate_points(:at_least_7, :at_least_12, 7)
          when 12...18
            calculate_points(:at_least_12, :at_least_18, 12)
          when 18...24
            calculate_points(:at_least_18, :at_least_24, 18)
          else
            POINTS_TH[:at_least_24]
        end
      end

      def calculate_points(lower_limit, upper_limit, deduct)
        POINTS_TH[lower_limit] + ((POINTS_TH[upper_limit] - POINTS_TH[lower_limit]) * (@count - deduct))
      end
    end
  end
end
