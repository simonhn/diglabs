xml.instruct! :xml, :version => '1.0'
xml.chart do
@artists.each do |artist|
  xml.track :count => artist.count.to_i, :artistname => artist.artistname
end
end
