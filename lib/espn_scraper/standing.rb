module ESPN
  class Standing
    attr_accessor :league, :group

    GROUPS = [
      LEAGUE     = 1,
      CONFERENCE = 2,
      DIVISION   = 3
    ]

    HEADERS = {
      nhl: %w[GP W L OTL PTS],
      mlb: %w[W L PCT GB L10],
      nfl: %w[W L T PCT STRK],
      ncf: %w[CONF OVERALL],
      ncb: %w[CONF OVERALL],
      nba: %w[W L PCT GB L10]
    }

    def initialize(league, group)
      #raise "Unsupported league" unless %w[nhl nba nfl mlb].include?(league.downcase)

      self.league = league.downcase
      self.group  = group unless league == 'ncf'
    end

    def self.find(league, group)
      %w[mlb nba nfl ncf].include?(league) ? new(league, group).get_updated : new(league, group).get
    end

    def get_updated
      data = {
        league: self.league,
        headers: HEADERS[self.league.to_sym],
        teams: {}
      }

      if league == 'mlb'
        markup.css('table.standings').each do |header_table|
          starting_caption = header_table.at_css('caption').content

          header_table.css('tr').each do |header|
            next unless header.children.first.name == 'th'

            data[:teams]["#{starting_caption} #{header.children.first.content}"] = []
          end
        end
      else
        markup.css('caption').each do |header|
          data[:teams][header.content] = []
        end
      end

      current_key = -1
      markup.css('.responsive-table-wrap tr').each do |team|
        if team.children.first.name == 'th'
          current_key += 1
          next
        end

        key = data[:teams].keys[current_key] || data[:teams].keys.last
        children = team.children

        next if children.css('a').size == 0

        data[:teams][key] << {
          team: (children.first.css('a').last.at_css('abbr').content.downcase),
          team_name: children.first.css('a').last.at_css('span .team-names').content,
          league: self.league,
          stats: get_stats(team)
        }
      end

      data
    end

    def get
      data = {
        league: self.league,
        headers: HEADERS[self.league.to_sym],
        teams: {}
      }
      current_key = -1

      if college_leagues.include?(league)
        markup.css('.stathead').each do |league|
          data[:teams][league.content.titleize.gsub(/Standings/, '').strip] = []
        end
      end

      markup.css('tr').each do |team|
        current_css_klass = team.attributes['class'].value

        if college_leagues.include?(league)
          if current_css_klass.match(/colhead/)
            current_key += 1
          end

          next if %w[stathead colhead].include?(current_css_klass)
        end

        if current_css_klass.match(/colhead/) && !college_leagues.include?(league)
          data[:teams][team.at_css('td').content.titleize] = []
        elsif current_css_klass.match(/oddrow|evenrow/)
          data_name = ESPN.parse_data_name_from(team)
          city_name = team.at_css('a').content
          next if team.content.match(/Expanded/)

          key = data[:teams].keys[current_key] || data[:teams].keys.last

          data[:teams][key] << {
            team: data_name,
            team_name: city_name,
            league: self.league,
            stats: get_stats(team)
          }
        end
      end

      return data
    end

    private

    def get_stats(team_div)
        #nba: %w[W L PCT GB L10]
      if league == 'nhl'
        [
          content_at_xpath(team_div, 2), # GP
          content_at_xpath(team_div, 3), # W
          content_at_xpath(team_div, 4), # L
          content_at_xpath(team_div, 5), # OTL
          content_at_xpath(team_div, 6), # PTS
        ]
      elsif league == 'mlb'
        [
          content_at_xpath(team_div, 2), # W
          content_at_xpath(team_div, 3), # L
          content_at_xpath(team_div, 4), # PCT
          content_at_xpath(team_div, 5), # GB
          content_at_xpath(team_div, 12), # L10
        ]
      elsif league == 'nfl'
        [
          content_at_xpath(team_div, 2), # W
          content_at_xpath(team_div, 3), # L
          content_at_xpath(team_div, 4), # T
          content_at_xpath(team_div, 5), # PCT
          content_at_xpath(team_div, 13), # STRK
        ]
      elsif league == 'ncf'
        [
          content_at_xpath(team_div, 2), # CONF
          content_at_xpath(team_div, 3), # OVERALL
        ]
      elsif league == 'ncb'
        [
          content_at_xpath(team_div, 2), # CONF
          content_at_xpath(team_div, 3), # OVERALL
        ]
      elsif league == 'nba'
        [
          content_at_xpath(team_div, 2), # W
          content_at_xpath(team_div, 3), # L
          content_at_xpath(team_div, 4), # PCT
          content_at_xpath(team_div, 5), # GB
          content_at_xpath(team_div, 14), # L10
        ]
      end
    end

    def content_at_xpath(team_div, xpath_location)
      team_div.at_xpath("td[#{xpath_location}]").content
    end

    def markup
      @markup ||= ESPN.get("#{league}/standings/_/group/#{group}")
    end

    def college_leagues
      @college_leagues ||= %w[ncb ncf]
    end
  end
end
