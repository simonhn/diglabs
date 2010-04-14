builder do |xml|
xml.instruct! :xml, :version => '1.0'
xml.tracks do
@tracks.each do |track|
xml.track :id => track.id do
  xml.plays track.cnt
  xml.tracktitle track.title
  xml.artistname track.artistname
end
end
end
end
