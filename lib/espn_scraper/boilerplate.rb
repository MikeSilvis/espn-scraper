require 'httparty'
require 'nokogiri'

module ESPN
  class << self

    def leagues
      @leagues || %w(nfl mlb nba nhl ncf ncb)
    end

    def leagues=(leagues)
      @leagues = leagues
    end

    def responding?
      HTTParty.get('http://espn.go.com/').code == 200
    end

    def down?
      !responding?
    end

    # Ex: ESPN.url('scores')
    #     ESPN.url('teams', 'nba')
    def url(*path)
      path.map { |p| p.gsub!(/\A\//, '') }
      subdomain = (path.first == 'scores') ? path.shift : nil
      domain = [subdomain, 'espn', 'go', 'com'].compact.join('.')
      ['http:/', domain, *path].join('/')
    end

    # Returns Nokogiri HTML document
    # Ex: ESPN.get('teams', 'nba')
    def get(*path)
      http_url = self.url(*path)
      response = HTTParty.get(http_url, timeout: 10)
      if response.code == 200
        Nokogiri::HTML(response.body)
      else
        raise ArgumentError, error_message(url, path)
      end
    end

    def dasherize(str)
      str.strip.downcase.gsub(/\s+/, '-')
    end

    def parse_game_id_from(link)
      begin
        query = Addressable::URI::parse(link.attributes['href'].value).query
        CGI::parse(query)['gameId'].first
      rescue
        ''
      end
    end

    def parse_data_name_from(container)
      if container.at_css('a')
        link = container.at_css('a')['href']
        query = Addressable::URI::parse(link).query
        if query
          CGI::parse(query)['team'].first
        else
          link.match(/id\/\d+|name\/\w+/).to_s.gsub('id/', '').gsub('name/', '')
        end
      else
        if container.at_css('div')
          name = container.at_css('div text()').content
        elsif container.at_css('span')
          name = container.at_css('span text()').content
        else
          name = container.at_css('text()').content
        end
      end
    end

    private

    def error_message(url, path)
      "The url #{url} from the path #{path} did not return a valid page."
    end
  end
end
