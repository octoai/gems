module Octo

  module KLDivergence

    # Calculates the KL-Divergance of two probabilities
    # https://en.wikipedia.org/wiki/Kullback–Leibler_divergence
    # @param [Float] p The first or observed probability
    # @param [Float] q The second or believed probability. Must be non-zero
    # @return [Float] KL-Divergance score
    def kl_divergence(p, q)
      p * Math.log(p/q)
    end
  end
end
