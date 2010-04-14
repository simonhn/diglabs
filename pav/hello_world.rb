require 'rubygems'
require 'sinatra'

require 'httparty'
require 'crack'

require 'dm-core'
require 'dm-serializer'
require 'dm-timestamps'
require 'dm-aggregates'

require 'json' 
require 'rack/contrib/jsonp'
require 'builder'
require 'sinatra/respond_to'
Sinatra::Application.register Sinatra::RespondTo

# A MySQL connection: 
configure do
  @config = YAML::load( File.open( 'conf/settings.yml' ) )
  @connection = "#{@config['adapter']}://#{@config['username']}:#{@config['password']}@#{@config['host']}/#{@config['database']}";
  DataMapper::setup(:default, @connection)
  DataMapper::Logger.new('/home/simonhn/datamapper.log', :info)
  #DataObjects::Mysql.logger = DataObjects::Logger.new('/home/simonhn/datamapper.log', 0)
end

#Models
class Artist
    include DataMapper::Resource
    property :id, Serial
    property :artistname, String
    property :artistnote, Text
    property :artistlink, String
    property :created_at, DateTime
    has n, :tracks, :through => Resource
end

class Album
    include DataMapper::Resource
    property :id, Serial
    property :albumname, String
    property :albumimage, String
    property :created_at, DateTime 
    has n, :tracks, :through => Resource
end

class Track
    include DataMapper::Resource
    property :id, Serial
    property :title, String
    property :tracknote, Text
    property :tracklink, String
    property :show, String
    property :talent, String
    property :aust, String
    property :duration, Integer
    property :publisher, String
    property :datecopyrighted, DateTime
    property :created_at, DateTime
    has n, :artists, :through => Resource
    has n, :albums, :through => Resource
    has n, :plays
end

class Play
    include DataMapper::Resource
    property :id, Serial
    property :playedtime, DateTime
    belongs_to :track
    belongs_to :channel
    before :save, :update_count
    def update_count
      #track_id
    end
end

class Channel
    include DataMapper::Resource
    property :id, Serial
    property :channelname, String
    has n, :plays
end

DataMapper.auto_upgrade!
#DataMapper.auto_migrate!

#Caching 10 minutes - might be a tad too much
before do
    response['Cache-Control'] = "public, max-age=600" unless development?
end

#Error handling
not_found do
  'This is nowhere to be found'
end

error do
  'Sorry there was a nasty error - ' + request.env['sinatra.error'].name
end

#Routes

# Frontpage: Add new artist, track, album
get '/' do
  erb :new
end

#
get '/parse' do
  xml = Crack::XML.parse(HTTParty.get('http://www.abc.net.au/dig/xml/ABC_Dig_MusicJustPlayed.xml').body)
  xml.inspect
  #xml["abcmusic_playout"]["items"]["item"][].each do |item|
    #item.inspect
  #end
end


#Sinatra version info
get '/about' do
  "I'm running version " + Sinatra::VERSION 
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

#POST
# create
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

#GET

#Count all artists
get '/stats' do
  artistcount = Artist.count
  trackcount = Track.count
  playcount = Play.count
  albumcount = Album.count 
  "There's #{artistcount} artists, #{trackcount} tracks, #{playcount} plays and #{albumcount} albums in the database"
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

# show track
get '/track/:id' do
  @track = Track.get(params[:id])
  respond_to do |wants|
    wants.html { erb :track }
    wants.xml { builder :track }
    wants.json {@track.to_json}
  end
end

# show plays for a track
get '/track/:id/play/all' do
  content_type 'text/xml', :charset => 'utf-8'
    @plays = Track.get(params[:id]).plays
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

# show tracks for an album
get '/album/:id/tracks' do
  @album = Album.get(params[:id])
  @tracks = Album.get(params[:id]).tracks
  respond_to do |wants|
    wants.html { erb :album_tracks }
    wants.xml { builder :album_tracks }
  end
end

# show tracks for specific channel
get '/channel/:id/plays' do
  @channel_tracks = Channel.get(params[:id]).plays.tracks
  respond_to do |wants|
    wants.xml { @channel_tracks.to_xml }
    wants.json { @channel_tracks.to_json }
  end
end

# show channel
get '/channel/:id' do
    @channel = Channel.get(params[:id])
    respond_to do |wants|
      wants.xml { @channel.to_xml }
      wants.json { @channel.to_json }  
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

# chart of top tracks by name
get '/chart/track' do
  @tracks = repository(:default).adapter.select('select artists.artistname, tracks.id, tracks.title, count(*) as cnt from tracks, plays, artists, artist_tracks where tracks.id=plays.track_id AND artists.id=artist_tracks.artist_id AND artist_tracks.track_id=tracks.id group by tracks.id order by cnt DESC limit 100')
  respond_to do |wants|
      wants.xml { builder :track_chart }
  end
end

# chart of top artist by name
get '/chart/artist' do
 @artists = repository(:default).adapter.select('select sum(cnt) as count, har.artistname from (select artists.artistname, artists.id, artist_tracks.artist_id, count(*) as cnt from tracks, plays, artists, artist_tracks where tracks.id=plays.track_id AND tracks.id=artist_tracks.track_id AND artist_tracks.artist_id= artists.id group by tracks.id) as har group by har.artistname order by count desc')
 respond_to do |wants|
    wants.xml { builder :artist_chart }
  end
end