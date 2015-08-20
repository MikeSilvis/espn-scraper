module ESPN::Schedule
  class Team
    attr_accessor :league, :name

    def initialize(league, name)
      self.league = league
      self.name   = name
    end

    def self.find(league, team)
      new(league, team).get_with_cache
    end

    def get_with_cache
      ESPN::Cache.fetch("by_team_#{league}_#{name}", expires_in: 1.day) do
        get
      end
    end

    def get
      data = {}
      data[:league]     = self.league
      data[:team_name]  = self.name


      data[:games] = schedule(markup.css('tr'))

      if league == 'mlb'
        data[:games] = schedule(second_markup.css('tr'))
      end

      return data
    end

    def schedule(rows)
      headings = markup.css('.stathead').map(&:content)
      current_heading = -1

      rows.map do |row|
        starting_index = league == 'nfl' ? 1 : 0
        next if row.attributes['class'].value == 'colhead'

        if row.attributes['class'].value == 'stathead'
          current_heading = current_heading + 1
        end

        tds = row.xpath('td')
        next if tds.count == 1
        next if row.content.match(/BYE WEEK/)
        next if tds[starting_index + 2].content.match(/Postponed|Canceled/i)

        has_hall_of_fame = false
        current_week = 0

        {}.tap do |game_info|
          time_string = "#{tds[starting_index + 2].content.match(/^\d*:\d\d (PM|AM)/)} EST"
          time = (Time.parse(time_string) rescue nil) if !time_string.match(/^[WL]/)
          is_over = !time && !tds[starting_index + 2].content.match(/TBD|TBA|Half/)
          date = Date.parse("#{tds[starting_index].content} #{Date.today.year}")

          game_info[:over] = is_over
          game_info[:date] = if !is_over && Date.today > date
                               date + 1.year
                             else
                               date
                             end

          date = game_info[:date]
          #puts 'setting date initially'
          #byebug if game_info[:date] == Date.new(2016, 1, 3)

          game_info[:date] = if is_over && Date.today < date
                               date - 1.year
                             else
                               date
                             end

          #puts 'changing date'
          #byebug if game_info[:date] == Date.new(2015, 1, 3)

          game_info[:opponent] = ESPN.parse_data_name_from(tds[starting_index + 1])
          game_info[:opponent_name] = tds[(starting_index.to_i + 1)].at_css('.team-name').content.to_s.gsub(/#\d*/, '').strip
          game_info[:is_away] = !!tds[(starting_index.to_i + 1)].content.match(/^@/)
          game_info[:week] = tds[0].content.to_i if %w[ncf nfl].include?(league)
          game_info[:heading] = headings[current_heading]

          if league == 'ncf'
            game_info[:week] = current_week + 1
            current_week = current_week + 1
          end

          if game_info[:week] == 'HOF'
            game_info[:week] = 1
            has_hall_of_fame = true
          end

          if has_hall_of_fame && tds[0].content != 'HOF'
            game_info[:week] = game_info[:week].to_i + 1
          end

          if is_over
            game_info[:result] = tds[starting_index + 2].at_css('.score').content.strip
            game_info[:win]    = tds[starting_index + 2].at_css('.game-status').content == 'W' rescue nil
          else
            game_info[:time] = DateTime.parse("#{game_info[:date].to_s} #{time_string}").utc
          end

        end
      end.compact.sort_by do |game|
        game[:date]
      end
    end

    private

    def by
      %w[ncf ncb].include?(league) ? 'id' : 'name'
    end

    def markup
      @markup ||= ESPN.get "#{league}/team/schedule/_/#{by}/#{name}/year/#{Date.today.year}"
    end

    def second_markup
      @second_half ||= ESPN.get "#{league}/team/schedule/_/#{by}/#{name}/year/#{Date.today.year}/half/2"
    end
  end
end
