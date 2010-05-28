#core stuff
require 'rubygems'
require 'sinatra'

#for xml fetch and parse
require 'httparty'
require 'crack'
require 'nokogiri'

#datamapper stuff
require 'dm-core'
require 'dm-serializer'
require 'dm-timestamps'
require 'dm-aggregates'

#template systems
require 'json' 
require 'rack/contrib/jsonp'
require 'builder'

require 'sinatra/respond_to'
Sinatra::Application.register Sinatra::RespondTo

# MySQL connection:
configure do
  DataMapper::Logger.new('log/datamapper.log', :debug)
  @config = YAML::load( File.open( 'conf/settings.yml' ) )
  @connection = "#{@config['adapter']}://#{@config['username']}:#{@config['password']}@#{@config['host']}/#{@config['database']}";
  DataMapper::setup(:default, @connection)
end

#Models - to be moved to individual files
class Artist
    include DataMapper::Resource
    property :id, Serial
    property :artistname, String, :length => 512
    property :artistnote, Text
    property :artistlink, Text
    property :created_at, DateTime
    has n, :tracks, :through => Resource
end

class Album
    include DataMapper::Resource
    property :id, Serial
    property :albumname, String, :length => 512
    property :albumimage, Text
    property :created_at, DateTime 
    has n, :tracks, :through => Resource
end

class Track
    include DataMapper::Resource
    property :id, Serial
    property :title, String, :length => 512
    property :tracknote, Text
    property :tracklink, Text
    property :show, Text
    property :talent, Text
    property :aust, String, :length => 512
    property :duration, Integer
    property :publisher, Text
    property :datecopyrighted, Integer
    property :created_at, DateTime
    has n, :artists, :through => Resource
    has n, :albums, :through => Resource
    has n, :plays
    def date
        created_at.strftime "%R on %B %d, %Y"
    end
    def playcount
      Play.count(:track_id => self.id);
    end
end

class Play
    include DataMapper::Resource
    property :id, Serial
    property :playedtime, DateTime
    belongs_to :track
    belongs_to :channel
    def date
        #converting from utc to aussie time
        playedtime.strftime "%Y-%m-%d %H:%M:%S"
        #playedtime.new_offset(Rational(+20,24)).strftime "%R on %B %d, %Y"
    end
    #before :save, :update_count
    #def update_count
      #augment count with one on Track.play_count where track_id
    #end
end

class Channel
    include DataMapper::Resource
    property :id, Serial
    property :channelname, String, :length => 512
    has n, :plays
end


#Caching 1 minute - must adjust
before do
    response['Cache-Control'] = "public, max-age=60" unless development?
end

#Error handling
not_found do
  'This is nowhere to be found'
end

error do
  'Sorry there was a nasty error - ' + request.env['sinatra.error'].name
end

helpers do
  
  def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Testing HTTP Auth")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'admin']
    end
    
    def make_to_from(played_from, played_to)
      #both to and from parameters provided
      if (!played_from.nil? && !played_to.nil?)
       return "AND playedtime < '#{played_to}' AND playedtime > '#{played_from}'"
      end
      #no parameter, sets from a week ago
      if (played_from.nil? && played_to.nil?)
        now_date = DateTime.now - 7
        return "AND playedtime > '#{now_date.strftime("%Y-%m-%d %H:%M:%S")}'"
      end
      #only to parameter, setting from a week before that
      if (played_from.nil? && !played_to.nil?)
        from_date = DateTime.parse(played_to) - 7
        return "AND playedtime < '#{played_to}' AND playedtime > '#{from_date.strftime("%Y-%m-%d %H:%M:%S")}'"
      end
      #only from parameter
      if (!played_from.nil? && played_to.nil?)
       return "AND playedtime > '#{played_from}'"
      end
    end
end

#ROUTES

#GET
# Front page
get '/' do
  erb :front
end

#show all artists
get '/artists' do
  @artists =  Artist.all(:limit => 10, :order => [:created_at.desc ])
  respond_to do |wants|
    wants.html { erb :artists }
    wants.xml { builder :artists }
    wants.json { @artists.to_json }
  end
end

#show all artists
get '/artists/:limit' do
  @artists =  Artist.all(:limit => params[:limit].to_i, :order => [:created_at.desc ])
  respond_to do |wants|
    wants.html { erb :artists }
    wants.xml { builder :artists }
    wants.json { @artists.to_json }
  end
end

# show artist from id
get '/artist/:id' do
  @artist = Artist.get(params[:id])
  respond_to do |wants|
    wants.html { erb :artist }
    wants.xml { builder :artist }
    wants.json { @artist.to_json }
  end
end

# show tracks from artist
get '/artist/:id/tracks' do
  @artist = Artist.get(params[:id])
  @tracks = Artist.get(params[:id]).tracks
  respond_to do |wants|
    wants.html { erb :artist_tracks }
    wants.xml { builder :artist_tracks }
  end
end

# show tracks from artist
get '/artist/:id/plays' do
  @artist = Artist.get(params[:id])
  @plays = Artist.get(params[:id]).tracks.plays
  respond_to do |wants|
    wants.html { erb :artist_plays }
    wants.xml { builder :artist_plays }
  end
end

#show all albums
get '/albums' do
  @albums =  Album.all(:limit => 10, :order => [:created_at.desc ])
    respond_to do |wants|
      wants.html { erb :albums }
      wants.xml { builder :albums }
      wants.json { @albums.to_json }
    end
end

#show all albums with limit
get '/albums/:limit' do
  @albums =  Album.all(:limit => params[:limit].to_i, :order => [:created_at.desc ])
  respond_to do |wants|
    wants.html { erb :albums }
    wants.xml { builder :albums }
    wants.json { @albums.to_json }
  end
end

# show album from id
get '/album/:id' do
  @album = Album.get(params[:id])
  respond_to do |wants|
    wants.html { erb :album }
    wants.xml { builder :album }
    wants.json {@album.to_json}
  end
end

# show tracks for an album - json version not perfect
get '/album/:id/tracks' do
  @album = Album.get(params[:id])
  @tracks = Album.get(params[:id]).tracks
  respond_to do |wants|
    wants.html { erb :album_tracks }
    wants.xml { builder :album_tracks }
    wants.json {@tracks.to_json }
  end
end

#show tracks
get '/tracks' do
 @tracks = Track.all(:limit => 10, :order => [:created_at.desc ])
 respond_to do |wants|
    wants.html { erb :tracks }
    wants.xml { builder :tracks }
    wants.json {@tracks.to_json}
  end
end

#show tracks with limit
get '/tracks/:limit' do
  @tracks = Track.all(:limit => params[:limit].to_i, :order => [:created_at.desc ])
  respond_to do |wants|
    wants.html { erb :tracks }
    wants.xml { builder :tracks }
    wants.json {@tracks.to_json}
  end
end

# show track
get '/track/:id' do
  @track = Track.get(params[:id])
  respond_to do |wants|
    wants.html { erb :track }
    wants.xml { builder :track }
    wants.json {@track.to_json}
  end
end

#show artists for a track
get '/track/:id/artists' do
  @track = Track.get(params[:id])
  @artists = Track.get(params[:id]).artists
  respond_to do |wants|
    wants.html { erb :track_artists }
    wants.xml { builder :track_artists }
    wants.json {@artists.to_json}
  end
end

#show albums for a track
get '/track/:id/albums' do
  @track = Track.get(params[:id])
  @albums = Track.get(params[:id]).albums
  respond_to do |wants|
    wants.html { erb :track_albums }
    wants.xml { builder :track_albums }
    wants.json {@albums.to_json}
  end
end

# show plays for a track
get '/track/:id/plays' do
  @track = Track.get(params[:id])
  @plays = Track.get(params[:id]).plays
  respond_to do |wants|
    wants.html { erb :track_plays }
    wants.xml { builder :track_plays }
    wants.json {@plays.to_json}
  end
end

# show all channels
get '/channels' do
    @channels = Channel.all
    respond_to do |wants|
      wants.xml { @channels.to_xml }
      wants.json { @channels.to_json }  
    end
end

# show channel from id
get '/channel/:id' do
    @channel = Channel.get(params[:id])
    respond_to do |wants|
      wants.xml { @channel.to_xml }
      wants.json { @channel.to_json }  
    end
end

# show tracks for specific channel
get '/channel/:id/plays' do
  @channel_plays = Channel.get(params[:id]).plays
  @channel_tracks = Channel.get(params[:id]).plays(:limit =>10,:order => [:playedtime.desc ]).tracks
  respond_to do |wants|
    wants.xml { @channel_tracks.to_xml }
    wants.json { @channel_tracks.to_json }
  end
end

# chart of top tracks by name
get '/chart/track' do
  #date in this format: 2010-05-11 01:06:14
  to_from = make_to_from(params[:played_from], params[:played_to])
  @tracks = repository(:default).adapter.select("select artists.artistname, tracks.id, tracks.title, count(*) as cnt from tracks, plays, artists, artist_tracks where tracks.id=plays.track_id AND artists.id=artist_tracks.artist_id AND artist_tracks.track_id=tracks.id #{to_from} group by tracks.id order by cnt DESC limit 10")
  respond_to do |wants|
     wants.xml { builder :track_chart }
   end
end

# chart of top artist by name
get '/chart/artist' do
 to_from = make_to_from(params[:played_from], params[:played_to])
 @artists = repository(:default).adapter.select("select sum(cnt) as count, har.artistname, har.id from (select artists.artistname, artists.id, artist_tracks.artist_id, count(*) as cnt from tracks, plays, artists, artist_tracks where tracks.id=plays.track_id AND tracks.id=artist_tracks.track_id AND artist_tracks.artist_id= artists.id #{to_from} group by tracks.id) as har group by har.artistname order by count desc limit 10")
 respond_to do |wants|
    wants.xml { builder :artist_chart }
  end
end

get '/chart/album' do
  to_from = make_to_from(params[:played_from], params[:played_to])
  @albums = repository(:default).adapter.select("select albums.albumname, albums.id as album_id, tracks.id as track_id, count(*) as cnt from tracks, plays, albums, album_tracks where tracks.id=plays.track_id AND albums.id=album_tracks.album_id AND album_tracks.track_id=tracks.id #{to_from} group by albums.id order by cnt DESC limit 10")
  respond_to do |wants|
      wants.xml { builder :album_chart }
  end
end

# search artist by name
get '/search/:q' do
  @artists = Artist.all(:artistname.like =>'%'+params[:q]+'%')
  respond_to do |wants|
    wants.html { erb :artists }
    wants.xml { builder :artists }
    wants.json { @artists.to_json }
  end
end

#Sinatra version info
get '/about' do
  "I'm running version " + Sinatra::VERSION 
end

#Count all artists
get '/stats' do
  @artistcount = Artist.count
  @trackcount = Track.count
  @playcount = Play.count
  @albumcount = Album.count 
  respond_to do |wants|
    wants.html { erb :stats }
  end
end

#POST
# create from form
=begin
post '/' do
  @artist = Artist.first_or_create(:artistname => params[:artistname])
  if @artist.save
    @albums = Album.first_or_create(:albumname => params[:albumname])
    @albums.save
    @tracks = @albums.tracks.first_or_create(:title => params[:tracktitle])
    @tracks.save
    @johns = @artist.tracks << @tracks
 
    @plays = @johns.plays.new(:track_id => @tracks.id, :channel_id => 1)
    @plays.save
    @artist.save
    redirect "/artist/#{@artist.id}"
  else
    redirect '/'
  end
end
=end

#Fetching xml, parsing and storing it to db
get '/parse' do
  protected!
  #utf-16 issue with triple j feed
  # http://www.abc.net.au/triplej/feeds/playout/triplejsydneyplayout.xml
  xml_files = ["http://www.abc.net.au/dig/xml/ABC_Dig_MusicJustPlayed.xml",
               "http://www.abc.net.au/jazz/xml/ABC_JazzJustPlayed.xml",
               "http://www.abc.net.au/country/xml/ABC_CountryJustPlayed.xml"]

  xml_files.each_with_index do |file,index|
    xml = Crack::XML.parse(HTTParty.get(file).body)
      xml["abcmusic_playout"]["items"]["item"].each do |item|
        if !item['artist']['artistname'].nil?
        @artist = Artist.first_or_create({:artistname => item['artist']['artistname']},{:artistname => item['artist']['artistname'], :artistnote => item['artist']['artistnote'], :artistlink => item['artist']['artistlink']})
        if @artist.save
          #creating and saving album
          @albums = Album.first_or_create(:albumname => item['album']['albumname'], :albumimage=>item['album']['albumimage'])
          @albums.save
      
          #creating and saving track
          @tracks = Track.first_or_create({:title => item['title'],:duration => item['duration']},{:title => item['title'],:show => item['show'],:talent => item['talent'],:aust => item['aust'],:tracklink => item['tracklink'],:tracknote => item['tracknote'],:duration => item['duration'],:publisher => item['publisher'],:datecopyrighted => item['datecopyrighted']})
          @tracks.save
      
          #add the track to album
          @album_tracks = @albums.tracks << @tracks
          @album_tracks.save
      
          #add the track to the artist
          @johns = @artist.tracks << @tracks
          @johns.save
      
          #artist.tracks.plays: only add if playedtime does not exsist
          play_items = Play.count(:playedtime=>item['playedtime'], :channel_id=>index+1)
          if play_items < 1
            @player = Play.new(:track_id =>@tracks.id, :channel_id => index+1, :playedtime=>item['playedtime'])
            @player.save
            @plays = @tracks.plays << @player
            @plays.save
          end  
          @artist.save
        end
      end
      end
    end
    redirect '/stats'
  end

DataMapper.auto_upgrade!
#DataMapper::auto_migrate!