require 'active_support/time'
require 'addressable/uri'
require 'cgi'

module ESPN
  class Score
    attr_accessor :league, :date

    def initialize(league, date)
      self.league = league
      self.date   = date
    end

    ## Warning, can be extremely expensive.
    ## Highly recommend running `rake espn_scraper:precache`
    def self.find(league, date)
      cache_key = "score_cache_#{league}_#{date}"

      espn_scores = if ESPN::Cache.read(cache_key)
                      ESPN::Cache.read(cache_key)
                    else
                      new(league, date).public_send("#{league}_scores").select do |score|
                        score[:game_date] == date
                      end
                    end

      if espn_scores.any? && espn_scores.all? { |score| score[:state] == 'postgame' }
        ESPN::Cache.write(cache_key, espn_scores)
      end

      return espn_scores
    end

    def nfl_scores
      updated_visitor_home_parse.tap do |scores|
        scores.each { |report| report[:league] = 'nfl' }
      end
    end

    def ncf_scores
      visitor_home_parse.tap do |scores|
        scores.each { |report| report[:league] = 'ncf' }
      end
    end

    def mlb_scores
      updated_visitor_home_parse
    end

    def nba_scores
      updated_visitor_home_parse
    end

    def nhl_scores
      nhl_mlb_scores.tap do |scores|
        scores.each { |report| report[:league] = 'nhl' }
      end
    end

    def ncb_scores
      visitor_home_parse.tap do |scores|
        scores.each { |report| report.merge! league: 'ncb', game_date: date }
      end
    end

    def teams
      @teams ||= ESPN::Team.find(league).values.flatten.map  { |t| t[:data_name] }.to_set
    end

    def markup_from_date
      @markup_from_date ||= begin
                              if %w[ncf].include?(league)
                                ESPN.get ESPN::DateToWeek.find(league, date).uri
                              elsif %w[mlb nba].include?(league)
                                league_string = league == 'mlb' ? 'baseball' : 'basketball'
                                day = date.to_date.to_s.gsub(/[^\d]+/, '')
                                http_url = "http://site.api.espn.com/apis/site/v2/sports/#{league_string}/#{league}/scoreboard?dates=#{day}"
                                Nokogiri::HTML( HTTParty.get(http_url, timeout: 10).body)
                              elsif league == 'nfl'
                                date_to_week = ESPN::DateToWeek.find(league, date)
                                http_url = "http://site.api.espn.com/apis/site/v2/sports/football/#{league}/scoreboard?seasontype=#{date_to_week.season_type}&week=#{date_to_week.week}"
                                Nokogiri::HTML( HTTParty.get(http_url, timeout: 10).body)
                              else
                                ESPN.get('scores', league, "scoreboard?date=#{ day }")
                                day = date.to_date.to_s.gsub(/[^\d]+/, '')
                              end
                            end
    end

    def updated_visitor_home_parse
      espn_state_to_scraper = {
        'Scheduled' => 'pregame',
        'In Progress' => 'in-progress',
        'Final' => 'postgame'
      }
      JSON.parse(markup_from_date)['events'].map do |event|
        game_info = {}

        game_info[:game_date] = Date.parse(event['date'])
        game_info[:league]    = self.league
        game_info[:boxscore]  = event['id']
        game_info[:preview]   = event['id']

        current_competition  = event['competitions'].detect { |a| Date.parse(a['date']) == Date.today } || event['competitions'].last
        game_info[:line]     = current_competition['odds'].first['details'] rescue nil
        game_info[:state]    = espn_state_to_scraper[event['status']['type']['description']] || espn_state_to_scraper['Scheduled']

        current_competition['competitors'].each_with_index do |competitor, index|
          score_index = league == 'mlb' ? 1 : 9

          if index == 0
            game_info[:home_team_record] = competitor['records'].first['summary']
            game_info[:home_team_name]   = competitor['team']['shortDisplayName']
            game_info[:home_team]        = competitor['team']['abbreviation'].downcase
            game_info[:home_score]       = competitor['statistics'][score_index]['displayValue'].to_i unless game_info[:state] == 'pregame' rescue competitor['linescores'].map { |a| a['value'] }.inject{|sum,x| sum + x }
            game_info[:home_score]       = competitor['score'] if league == 'nfl'
          else
            game_info[:away_team_record] = competitor['records'].first['summary']
            game_info[:away_team_name]   = competitor['team']['shortDisplayName']
            game_info[:away_team]        = competitor['team']['abbreviation'].downcase
            game_info[:away_score]       = competitor['statistics'][score_index]['displayValue'].to_i unless game_info[:state] == 'pregame' rescue competitor['linescores'].map { |a| a['value'] }.inject{|sum,x| sum + x }
            game_info[:away_score]       = competitor['score'] if league == 'nfl'
          end
        end

        if league == 'mlb'
          game_info[:time_remaining] = event['status']['type']['shortDetail'].split(" ")[0].strip if game_info[:state] == 'in-progress'
          game_info[:progress] = event['status']['type']['shortDetail'].split(" ")[1].strip if game_info[:state] == 'in-progress'
        else
          game_info[:time_remaining] = event['status']['type']['shortDetail'].split("-")[0].strip if game_info[:state] == 'in-progress'
          game_info[:progress] = event['status']['type']['shortDetail'].split("-")[1].strip if game_info[:state] == 'in-progress'
        end

        game_info[:start_time] = event['status']['type']['shortDetail'].match(/\d.*/).to_s if game_info[:state] == 'pregame'
        game_info[:ended_in] = event['status']['type']['description'] if game_info[:state] == 'postgame'
        game_info
      end
    end

    # parsing strategies
    def visitor_home_parse(date = nil)
      game_dates = markup_from_date.css('.games-date text()').map do |node|
        if node.content == "Today's Games"
          Time.now.in_time_zone("Mountain Time (US & Canada)").to_date
        else
          Date.parse(node.content) rescue nil
        end
      end.compact

      game_scores = []
      markup_from_date.css('.gameDay-Container').each_with_index do |container, i|
        container.css(".mod-#{league}-scorebox").each do |game|
          next if game.at_css('.team-name').content == 'TBD'
          visitorKlass = league == 'nba' ? 'away' : 'visitor'

          game_info = {}
          game_info[:game_date]      = date ? date : game_dates[i]
          game_info[:home_team]      = ESPN.parse_data_name_from game.at_css('.home .team-name')
          game_info[:home_team_name] = game.at_css('.home .team-name a').content.strip rescue game.at_css(".#{visitorKlass} .team-name").content
          game_info[:home_team_abbr] = game_info[:home_team_name].upcase
          game_info[:away_team]      = ESPN.parse_data_name_from game.at_css(".#{visitorKlass} .team-name")
          game_info[:away_team_name] = game.at_css(".#{visitorKlass} .team-name a").content.strip rescue game.at_css(".#{visitorKlass} .team-name").content
          game_info[:away_team_abbr] = game_info[:away_team_name].upcase

          next unless teams.include?(game_info[:home_team]) && teams.include?(game_info[:away_team])

          scoreKlass = league == 'nba' ? '.finalScore' : '.score .final'
          game_info[:home_score]     = game.at_css(".home #{scoreKlass}").content.to_i
          game_info[:away_score]     = game.at_css(".#{visitorKlass} #{scoreKlass}").content.to_i

          ## Ranks (Primarily for College)
          game_info[:home_team_rank] = Float(game.at_css('.home .team-name span').content).to_i.to_s rescue ''
          game_info[:away_team_rank] = Float(game.at_css('.visitor .team-name span').content).to_i.to_s rescue ''

          ## Logos
          if league != 'nba'
            game_info[:away_team_logo] = game.at_css(".team.visitor .logo-small img")['src'].gsub("=50", "=200")
            game_info[:home_team_logo] = game.at_css('.team.home .logo-small img')['src'].gsub("=50", "=200")
          end

          ## Records
          record_regex = /\d*-\d*/
          game_info[:home_team_record] = game.at_css('.home .record').content.match(record_regex).to_s
          game_info[:away_team_record] = game.at_css(".#{visitorKlass} .record").content.match(record_regex).to_s

          ## Game Progress
          cssKlass = game.attributes['class'].value.split(' ')
          if cssKlass.include?('preview')
            game_info[:state] = 'pregame'
            game_info[:start_time] = game.at_css('.game-status').content

            game_info[:preview] = ESPN.parse_game_id_from(game.at_css('.flag a'))

            ## Money Line
            if game.at_css('.oddsleft, .oddsright')
              if game.at_css('.oddsleft').content.match(/Pick/)
                money_line = game.at_css('.oddsright').children
              elsif game.at_css('.oddsleft')
                money_line = game.at_css('.oddsleft').children
              end
              game_info[:line] = (money_line[1].content rescue '')
              if money_line[3]
                game_info[:line] = "#{game_info[:line]} O/U #{money_line[3].content}"
              end
            end

          elsif cssKlass.include?('in-game')
            game_info[:state] = 'in-progress'
            game_status = game.at_css('.game-status').content.split(' ')
            game_info[:time_remaining] = game_status.first.gsub(/\p{Space}/, ' ').strip
            game_info[:progress] = game_status.drop(1).join(' ')
          elsif cssKlass.include?('final-state')
            game_info[:state] = 'postgame'
            game_info[:ended_in] = game.at_css('.game-status').content
          end

          if %w[in-progress postgame].include?(game_info[:state])
            selector = %w[nba ncb].include?(league) ? '.expand-gameLinks a' : '.more-links ul li a'
            game_info[:boxscore] = ESPN.parse_game_id_from(game.css(selector).detect { |l| l.content.match(/Box/) })
          end

          game_scores.push game_info
        end
      end
      game_scores
    end

    def nhl_mlb_scores
      markup_from_date.css('.mod-scorebox, .mod-scorebox-pregame, .mod-scorebox-in-progress, .mod-scorebox-final').map do |game|
        game_info = { game_date: date }
        cssKlass = league == 'nhl' ? 'td.team-name:not([colspan])' : '.team-name'
        team_info = game.css(cssKlass)

        ## Team names
        game_info[:away_team_name], game_info[:home_team_name] = team_info.css('a').map(&:content).map(&:strip)
        next if game_info[:away_team_name].nil? || game_info[:home_team_name].nil?

        if league == 'mlb'
          game_info[:away_team_logo] = game.at_css(".team.away .logo-small img")['src'].gsub("=50", "=200")
          game_info[:home_team_logo] = game.at_css('.team.home .logo-small img')['src'].gsub("=50", "=200")
        elsif league == 'nhl'
        end

        ## Records
        cssKlass = league == 'nhl' ? '.game-header-table .team-name' : '.team-capsule p:last'
        regex = /\(|,(.*)$/
        if league == 'nhl'
          records = game.css('.game-header-table .team-name')
          records = records.select { |row| row.attributes['id'] && row.attributes['id'].value.match(/awayRecord|homeRecord/) }
          records = records.map { |record| record.children[1].content.gsub(regex, '') }
        else
          records = game.css('.team-capsule p:last')
          records = records.map { |record| record.content.gsub(regex, '') }
        end
        game_info[:away_team_record], game_info[:home_team_record] = records

        ## Data names
        data_names = team_info.map { |td| ESPN.parse_data_name_from(td) }
        game_info[:away_team], game_info[:home_team] = data_names
        cssKlass = league == 'nhl' ? '.team-score' : '.finalScore'
        scores = if league == 'nhl'
                   game.css('.team-score').map { |td| td.at_css('span').content.to_i }
                 else
                   game.css('.finalScore')[1..2].map { |s| s.content.to_i }
                 end
        game_info[:away_score], game_info[:home_score] = scores
        game_info[:away_team_abbr] = game_info[:away_team].upcase
        game_info[:home_team_abbr] = game_info[:home_team].upcase

        ## Scores, Start time, etc.
        timeCssKlass = league == 'nhl' ? '.game-info li' : '.game-status'
        time = game.css(timeCssKlass).last.children
        cssKlass = game.attributes['class'].value.split(' ')
        if cssKlass.include?('mod-scorebox-pregame') || cssKlass.include?('preview')
          game_info[:state] = 'pregame'
          game_info[:start_time] = time.first.content
          game_info[:line] = game.at_css('.expand-gameLinks strong').content if game.at_css('.expand-gameLinks strong')
          game_info[:preview] = ESPN.parse_game_id_from(game.at_css('.flag a'))
        elsif cssKlass.include?('mod-scorebox-in-progress') || cssKlass.include?('in-game')
          game_info[:state] = 'in-progress'
          game_info[:progress] = time.first.content
          game_info[:time_remaining] = time.at_css('.time-remaining').content.gsub(/\p{Space}/, ' ').strip unless league == 'mlb'
        elsif cssKlass.include?('mod-scorebox-final') || cssKlass.include?('final-state')
          game_info[:state] = 'postgame'
          game_info[:ended_in] = game.css(timeCssKlass).first.content
        end

        if cssKlass.include?('mod-scorebox-in-progress') || cssKlass.include?('mod-scorebox-final') || cssKlass.include?('final-state')
          game_info[:boxscore] = ESPN.parse_game_id_from(game.css('.expand-gameLinks a').detect { |l| l.content.match(/Box/) })
        end

        game_info
      end.compact
    end
  end
end
