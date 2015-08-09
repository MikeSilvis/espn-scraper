module ESPN
  class Team
    attr_accessor :league, :divisions

    def initialize(league)
      self.league    = league.to_s.downcase
      self.divisions = {}
    end

    def self.find(league)
      new(league).get_with_cache
    end

    def get_with_cache
      ESPN::Cache.fetch("get_teams_with_cache_#{league}") do
        get
      end
    end

    def get
      ESPN::Division.new(league).get do |name, div|
        self.divisions[name] = div.css('.mod-content li').map do |team|
          team_elem = team.at_css('h5 a.bi')
          team_name = team_elem.content
          url_array = team_elem['href'].split('/')
          url = url_array[0..url_array.size-2].join('/')
          data_name = ESPN.parse_data_name_from(team)

          { name: team_name, data_name: data_name, url: url }
        end
      end

      divisions
    end
  end
end
