module Octo

  private

  # Generate the recommender instance
  # @return [Octo::Recommender]
  def recommender
    @recommender = Octo::Recommender.new unless @recommender
    @recommender
  end
end