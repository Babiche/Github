module Algorithm
  module AdditionalSC
    # Determines points for review part of additional SC
    class Reviews
      # PR stands for Peer Review and TR stands for Trade Review
      # PROD stands for Producer and CONS stands for Consumer

      POINTS_PR = {
          one_star:   5,
          two_star:   30,
          three_star: 60,
          four_star:  80,
          five_star:  100,
          max:        200
      }.freeze

      POINTS_TR = {
          one_star:   5,
          two_star:   31,
          three_star: 57,
          four_star:  83,
          five_star:  110,
          max: 330
      }.freeze

      TR_PROD_WEIGHTS = {
          quality:       0.5,
          claims:        0.25,
          shipping:      0.125,
          communication: 0.125
      }.freeze

      TR_CONS_WEIGHTS = {
          payment:       0.5,
          claims:        0.25,
          communication: 0.25
      }.freeze

      def get_points(review_type, reviews, company_type)
        set_up_variables(review_type, reviews, company_type)
        calculate_total_points
      end

      def set_up_variables(review_type, reviews, company_type)
        @review_type    = review_type
        @company_type   = company_type
        @reviews        = reviews
        @points         = @review_type == :peer ? POINTS_PR                           : POINTS_TR
        @weights        = @review_type == :peer ? 1                                   : weights_to_use
        @max_multiplier = reviews.count <= 2    ? reviews.count * @points[:five_star] : @points[:max]
      end

      def weights_to_use
        @company_type == 'producer' ? TR_PROD_WEIGHTS : TR_CONS_WEIGHTS
      end

      def calculate_total_points
        total_points = 0

        @reviews.each do |review|
          @scores_given = retrieve_given_scores(review)

          total_points += determine_review_points
        end

        return_total_review_points(total_points)
      end

      def retrieve_given_scores(review)
        if @company_type == 'producer' && @review_type == :trade
          return [review[:quality], review[:claims_handling], review[:shipping], review[:communication]]
        end

        if @company_type == 'consumer' && @review_type == :trade
          return [review[:payment], review[:claims_handling], review[:communication]]
        end

        review[:trust_score]
      end

      def determine_review_points
        assign_points(weighted_score)
      end

      def weighted_score
        average_score = 0
        return average_score += @weights * @scores_given if @review_type == :peer

        @weights.each_with_index do |weight, index|
          average_score += weight[1] * @scores_given[index] if @scores_given[index]
        end
        average_score
      end

      def assign_points(score)
        case @score = score
        when 1...2
          calculate_points(:one_star, :two_star, 1)
        when 2...3
          calculate_points(:two_star, :three_star, 2)
        when 3...4
          calculate_points(:three_star, :four_star, 3)
        else
          calculate_points(:four_star, :five_star, 4)
        end
      end

      def calculate_points(lower_limit, upper_limit, deduct)
        @points[lower_limit] + ((@points[upper_limit] - @points[lower_limit]) * (@score - deduct))
      end

      def return_total_review_points(total)
        (total.to_f / (@reviews.count * @points[:five_star]).to_f) * @max_multiplier
      end
    end
  end
end