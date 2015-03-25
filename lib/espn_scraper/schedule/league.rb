module ESPN::Schedule
  class League
    attr_accessor :league

    def initialize(league)
      self.league = league
    end

    def self.find(league)
      new(league).get_with_cache
    end

    def self.precache
      %w[ncb nba nhl].each do |league|
        new(league).get_with_cache
      end
    end

    def get_with_cache(just_dates = true)
      games = ESPN::Cache.fetch("espn_schedule_#{league}", expires_in: 1.year) do
        get
      end.flatten

      if just_dates
        games.map { |g| g[:date] }.uniq.sort
      else
        games
      end
    end

    def get
      team_data_names.map do |team|
        ESPN::Schedule::Team.find(league, team)[:games]
      end
    end

    private

    def team_data_names
      @team_data_names ||= ESPN::Team.find(league).values.flatten.map { |a| a[:data_name] }
    end
  end
end
