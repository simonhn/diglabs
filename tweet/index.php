<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1" 
/>
<title>DIG + Twitter Search Flow</title>
<style type="text/css">
.woork{
	color:#444;
	font-family:"Lucida Grande", "Lucida Sans Unicode", Verdana, 
Arial, Helvetica, sans-serif;
	font-size:12px;
	width:600px;
	margin: 0 auto;
}
.twitter_container{
	color:#444;
	font-family:"Lucida Grande", "Lucida Sans Unicode", Verdana, 
Arial, Helvetica, sans-serif;
	font-size:12px;
	width:450px;
	margin: 0 auto;
	background:#DEDEDE;
	padding:8px;
}
.twitter_container a{
	color:#0066CC;
}
.twitter_header{
	clear:both;
	float:none;
	position:relative;
}
.twitter_header img{
left:20px; 

}
.twitter_status{
	height:60px;
	padding:6PX;
	border-bottom:solid 1px #DEDEDE;
	background:#FFF;
}
.twitter_image{
	float:left; 
	margin-right:14px;
	border:solid 2px #DEDEDE;
	width:50px;
	height:50px;
}
.twitter_small{
 font-size:11px;
 padding-top:4px;
 color:#999;
 display:block;
}
#twitter-results{padding-top:8px;}
</style>
<script type="text/javascript" 
src="jquery/jquery-1.3.2.min.js"></script>
<script type="text/javascript">
  $(document).ready(function(){
   var twitterq = '';
   
  function displayTweet(){
	var i= 0;
	var limit = $("#twitter-results > div").size();
	var myInterval = window.setInterval(function () {
	var element =  $("#twitter-results div:last-child");
	$("#twitter-results").prepend(element);
	element.fadeIn("slow");
	i++;
	if(i==limit){
		 window.setTimeout(function () {
		 clearInterval(myInterval);
		 });
		}
		
	},4000);
  }
 	

			twitterq = $('#simon').text();
		$('#twitterq').attr('value',twitterq);
		
			
$.getJSON("http://search.twitter.com/search.json?rpp=20&q="+twitterq+"&callback=?",
			function(tweets){
				if(tweets.results == null){
				$("#twitter-results").append('NO RESULTS');}
			for(i in tweets.results)
			{

			html = "<div class=\"twitter_status\" >";
			html += "<img src=" + tweets.results[i].profile_image_url + " class=\"twitter_image\"></img>";
			html += tweets.results[i].text;
			html += "<span class=\"twitter_small\">";
			html += '<strong>From:</strong> <a href="http://www.twitter.com/'+tweets.results[i].from_user+'">'+tweets.results[i].from_user+'</a>';
			html += '<strong>at:</strong> '+tweets.results[i].created_at;
			html +='</span>';
			html += "</div>";

			$("#twitter-results").append(html);
			
			}
			});
displayTweet();

	
});
  
</script>
</head>

<body>
	<img src="http://abcdigmusic.net.au/sites/all/themes/dig2/images/dig/bg_heading.png" style="display:block; margin-left: auto; margin-right: auto;" />
<div class="twitter_container">
	<div class="twitter_header">
<strong>DIG the tweet demo:</strong><br />
<br/>
<!-- <form id="twittersearch" method="post" action="">
<input name="twitterq" type="text" id="twitterq" />
<button type="submit">Search</button></form> -->

<?php

	$nowNext = 
file_get_contents('http://www.abc.net.au/dig/xml/ABC_Dig_MusicNowNext.xml');
	  libxml_use_internal_errors(true);
	  $xml = new SimpleXMLElement($nowNext);

	  $returnItems = array();

	  foreach ($xml->items->item as $item)
	  {
	    $returnItem = new Item();
	    $returnItem->trackId         = (string) $item->trackid;
	    $returnItem->playedTime      = strtotime((string) 
$item->playedtime);
	    $returnItem->duration        = (string) $item->duration;
	    $returnItem->playing         = (string) $item->playing;
	    $returnItem->trackNote       = (string) $item->tracknote;
	    $returnItem->artistName      = (string) 
$item->artist->artistname;
	    $returnItem->title           = (string) $item->title;
	    $returnItem->publisher       = (string) $item->publisher;
	    $returnItem->dateCopyrighted = (string) 
$item->datecopyrighted;
	    $returnItem->albumName       = (string) 
$item->album->albumname;
	    $returnItem->albumImage      = (string) 
$item->album->albumimage;
	    $returnItem->links = array();/*
		    array(
		      'type' => 'Interview',
		      'date' => 'Oct 09 2008',
		      'title' => 'A Punk Past',
		      'url' => '#1a',
		    ),
		    array(
		      'type' => 'Interview',
		      'date' => 'Oct 09 2008',
		      'title' => 'A Punk Past',
		      'url' => '#1b',
		    ),
		    array(
		      'type' => 'Interview',
		      'date' => 'Oct 09 2008',
		      'title' => 'A Punk Past',
		      'url' => '#1c',
		    ),
		    array(
		      'type' => 'Interview',
		      'date' => 'Oct 09 2009',
		      'title' => 'A Punk Past',
		      'url' => '#1d',
		    ),
		    array(
		      'type' => 'Interview',
		      'date' => 'Oct 09 2009',
		      'title' => 'A Punk Past',
		      'url' => '#1e',
		    ),
		    array(
		      'type' => 'Interview',
		      'date' => 'Oct 09 2009',
		      'title' => 'A Punk Past',
		      'url' => '#1f',
		    ),
		  );*/

	    $returnItems[] = $returnItem;
	  }
echo "Tweets for next artist on abcdigmusic: <div id=\"simon\">".$returnItems[0]->artistName."</div> <img src=\"".$returnItems[0]->albumImage."\"  />";



	class Item
	{
	  public $trackId,
	    $playedTime,
	    $duration,
	  	$playing,
	  	$artistName,
	  	$artistNote,
	  	$title,
	  	$publisher,
	  	$dateCopyrighted,
	  	$albumName,
	  	$albumImage,
	  	$links;
	}
	
?>
</div>
<div id="twitter-results"></div>

</div>
</body>
</html>


