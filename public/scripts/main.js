var map = undefined;
var marker = undefined;
var position = [42.354066, -71.102626];

function initialize() {

	var latlng = new google.maps.LatLng(position[0], position[1]);
	var myOptions = {
		zoom: 15,
		center: latlng,
		disableDefaultUI: true,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	map = new google.maps.Map(document.getElementById("map"), myOptions);

	marker = new google.maps.Marker({
		position: latlng,
		map: map,
		title: "Your current location!"
	});

	google.maps.event.addListener(map, 'click', function(me) {
		var result = [me.latLng.lat(), me.latLng.lng()];
		transition(result);
	});

	

}

var numDeltas = 100;
var delay = 10; //milliseconds
var i = 0;
var deltaLat;
var deltaLng;
function transition(result){
	console.log(result);
	i = 0;
	deltaLat = (result[0] - position[0])/numDeltas;
	deltaLng = (result[1] - position[1])/numDeltas;
	moveMarker();
}

function moveMarker(){
	position[0] += deltaLat;
	position[1] += deltaLng;
	var latlng = new google.maps.LatLng(position[0], position[1]);
	marker.setPosition(latlng);
	if(i!=numDeltas){
		i++;
		setTimeout(moveMarker, delay);
	}
}

function build_slider(data){

	var slider = $("#slider");
	min_time = data['moments'][0]['timestamp'] 
	max_time = data['moments'][0]['timestamp']



	for (i in data['moments']) {
		if (data['moments'][i]['timestamp'] < min_time) {
			min_time = data['moments'][i]['timestamp']
		} else if (data['moments'][i]['timestamp'] > max_time) {
			max_time = data['moments'][i]['timestamp']
		}
	}

	console.log("max_time: " + max_time);
	console.log("min_time: " + min_time);

	//step_value = (max_time - min_time) / data['moments'].length
	step_value = 1;

	var startingSeconds = 0;
	$( "#time" ).text( moment.unix(min_time).format('MMMM Do YYYY, h:mm:ss a') );
	$( ".moments-box" ).text(data['moments'][0]['transcription'])

	slider.slider({
		min: min_time,
		max: max_time,
		step: step_value,
		value: min_time,

		slide: function( event, ui ) {
			$( "#time" ).text( moment.unix(ui.value).format('MMMM Do YYYY, h:mm:ss a') );
			

			for (i in data['moments']) {
				if (data['moments'][i]['timestamp'] == ui.value ) {
					$( ".moments-box").empty()
					$( ".moments-box" ).text(data['moments'][i]['transcription'])
					var result = [data['moments'][ i ]['lat'], data['moments'][ i ]['lon']];
					transition(result);
				}
			}

		}
	});

}

function makeRequest(username) {
    var requestURL = "/api/users/" + username
    $.getJSON(requestURL, function(data){
    	//console.log(data)
    	build_slider(data)
    });
}



$(document).ready(function() {
	initialize();
	//build_slider();
	makeRequest(username)
});

