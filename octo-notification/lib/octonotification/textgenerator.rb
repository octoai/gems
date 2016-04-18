module Octo
  class TextGenerator

    TEMPLATES = [
      "Check out this cool new %{name} for just Rs %{price}.",
      "%{name} is trending in %{category} right now. Check it out",
      "You should totally see this %{name} in %{category}. It's just for %{price}"
    ]

    # Generate Notification Template
    # @param [Hash] product Details of the product
    # @param [String] template Text Template
    def self.generate(product, template=nil)

      pHash = {
        name: product['name'],
        category: product[:categories].shuffle[0],
        price: product['price'].round(2)
      }
      if template.nil?
        TEMPLATES.sample % pHash
      else
        template % pHash
      end
    end
  end
end