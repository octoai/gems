
module Octo
  module Scheduler

    # Setup Schedule for recommenders
    def schedule_recommender
      name = 'recommender_processing'
      config = {
            class: 'Octo::Recommender',
            args: [],
            cron: '0,30 * * * *',
            persist: true,
            queue: 'recommender'
          }
      Resque.set_schedule name, config
    end

  end
end
