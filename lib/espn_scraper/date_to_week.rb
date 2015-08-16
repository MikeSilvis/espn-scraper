module ESPN
  class DateToWeek
    attr_accessor :league,
                  :date,
                  :game_dates

    def initialize(league, date)
      self.league = league
      self.date   = date
    end

    def self.find(league, date)
      new(league, date)
    end

    def uri
      http_params = %W[ seasonYear=#{self.date.year} seasonType=#{season_type} weekNumber=#{week} confId=80 ]

      "#{self.league}/scoreboard?#{http_params.join('&')}"
    end

    def week
      # TODO: Remove after preseason
      self.date > Date.new(2015, 8, 9) && league == 'nfl' ? closest_game_week + 1 : closest_game_week
    end

    def season_type
      league == 'nfl' ? 1 : 2
    end

    def closest_game_week
      return self.game_dates[date] if self.game_dates[date]

      closest_date = self.game_dates.keys.sort.detect do |game_date|
        (game_date > date)
      end

      return self.game_dates[closest_date]
    end

    def game_dates
      @game_dates ||= begin
                        ESPN::Schedule::League.new(league).get_with_cache(false).inject({}) do |hash, game|
                          hash[game[:date]] = game[:week]
                          hash
                        end
                      end
    end
  end
end
