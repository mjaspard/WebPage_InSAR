
<!doctype html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="initial-scale=1,user-scalable=no,maximum-scale=1,width=device-width">
        <meta name="mobile-web-app-capable" content="yes">
        <meta name="apple-mobile-web-app-capable" content="yes">
		<link rel="stylesheet" href="css/qgis2web.css">
        <link rel="stylesheet" href="css/fontawesome-all.min.css">
        <link rel="stylesheet" href="css/leaflet-measure.css">
        <link rel="stylesheet" href="css/leaflet.css">
        <link href="css/main.css" rel="stylesheet"> 		
        <link href="css/max.css" rel="stylesheet"> 
	
		
        <style>
        #map {
         	width: 800px;
            height: 700px;
            padding: 0;
            margin: 0;
        }

        </style>
        <title></title>
    </head>
    <body>

<div class="container">

	<div class="page-header">
		<center>
		<table width="100" align="center">
			<tr>
				<td rowspan="2"><img src="logo_musee.png" width="80"/></td>
				<th class="inline"><a href="http://www.ecgs.lu"><img src="logo_ecgs_2.png" width="420"/></a>
				<a href="http://resist.africamuseum.be"><img src="logo_resist.png" width="80"/></a></th>
			</tr>
			<tr>
				<th class="inline"><img src="logo_master.png" width="230"/>
				<a href="https://iipg.conicet.gov.ar"><img src="logo_IIPG.png" width="230"/><a></th>
			</tr>
		</table>
		
		<p class="ref">Information provided below are generated automatically by computers and were not validated a posteriori by a scientific analysis. Results are issued from a complex and unsupervised processing. Consequently they may be inaccurate or even erroneous. In particular, solution computed for the most recent dates are potentially less robust. 
Institutions and individuals involved with the production of these results shall not in any way be responsible for possible erroneous results or failure of the web service. 
The usage of these data is free and open. If you make use of it in publication of any kind (papers, news papers, web pages, reports…), please mention the web page and acknowledge the European Center for Geodynamics and Seismology (<a href="http://www.ecgs.lu">ECGS</a>, Luxembourg) and the Instituto de Investigación en Paleobiología y Geología (<a href="https://iipg.conicet.gov.ar"> IIPG</a>, Universidad Nacional de Río Negro, Argentina). For usage in scientific works, please cite the papers listed below.
</p>
<?php
$output = array();
exec("df -h | grep doris", $output);
$DORISPRO = implode(",", $output);
$output2 = array();
exec("df -h | grep hp-D3602", $output2);
$HPSERVER = implode(",", $output2);
$empty = '';
if ((strcmp($DORISPRO, $empty) ==0) || (strcmp($HPSERVER, $empty) ==0))  {
?>
<h2 class="blinking"> Maintenance on server: in progress </h2>
<?php 
} 
$output3 = array();
exec("ps -ax | grep Custom_TS.sh | wc -l | awk '{print $1}'", $output3);

if ($output3[0] > 2) {
?>
<h2 class="blinking_2"> Calculation in progress: </h2>
<?php 
}
?>

	

<div class="jumbotron">    

	<input type="button" value="Main page" onclick="location.href='http://terra3.ecgs.lu/defo-domuyo/'">

    
    <div id="map">
    </div>
        

		
	<div class="styleform">	
 		<p class="mini">Coordinates of Point 1: <span id="mapcoords"></span> ;  Relative position :<span id="mapcoords3"></span><br>
		 Coordinates of Point 2: <span id="mapcoords2"></span> ;  Relative position :<span id="mapcoords4"></span></p>
		<br>
	 
	 	<p>Calculate and display customised Times Series:<br></br>
	 	Click two points in the coherence area (Coherence is colorised in MSBAS maps) <br>
		 Drag both points on the map for fine adjustment <br>
		 Enter your email address and a name for the request <br>
		 --> Click on "Submit Time Series request"</p>
		<form action="index.php" method="get" accept-charset="utf-8">
			<label for="text">Coordinate:</label>
			<input name="X1" id="X1" type="text" placeholder="point A: X" required>
			<input name="Y1" id="Y1" type="text" placeholder="point A: Y" required>
			<input name="X2" id="X2" type="text" placeholder="point B: X" required>
			<input name="Y2" id="Y2" type="text" placeholder="point B: Y" required><br></br> 	
			<label for="email">Enter your email:</label>
			<input type="email" id="email" name="email" required><br></br>
			<label for="ReqName">Enter a request name:</label>
			<input type="ReqName" id="info" name="info" required><br></br>
			<input type="submit" name="submit" value="Submit Time Series request" onclick="location.href='#info'">
		</form>
	</div>


<?php
$message = ''; //initi variable


if(isset($_GET['submit']))
	{
	
$data_file = fopen("TS_Data.txt", "w");
$X1 = $_GET["X1"];
$Y1 = $_GET["Y1"];
$X2 = $_GET["X2"];
$Y2 = $_GET["Y2"];
$text_to_write = $X1."_". $Y1."_".$X2."_".$Y2;
// Write data to server side
fwrite($data_file, $text_to_write);
fclose($data_file);

$data_file = fopen("Request_info.txt", "w");
$email = $_GET["email"];
$info = $_GET["info"];
$text_to_write = $email."\n".$info;
fwrite($data_file, $text_to_write);
fclose($data_file);



$qgispath = "Time_Series/TS_all";
$TS_EW = $qgispath."/_timeLines_".$text_to_write."_Auto_2_0.04_Domuyo_EW_UD_combi.jpg";
$TS_Asc = $qgispath."/_timeLines_".$text_to_write."_Auto_2_0.04_Domuyo_LOS_Asc_combi.jpg";
$TS_Desc = $qgispath."/_timeLines_".$text_to_write."_Auto_2_0.04_Domuyo_LOS_Desc_combi.jpg";

//
$command = "/Library/Server/Web/Data/Sites/defo-domuyo/Qgis2Web/Link.sh";
//shell_exec ($command);
exec ($command, $output);
//print_r($output);  // to see the response to your command

$message = file_get_contents('Message.txt');
echo '<textarea class="box" rows="10" cols="100">'.$message.'</textarea>';
		
	}


?>

</div>

        <script src="js/qgis2web_expressions.js"></script>
        <script src="js/leaflet.js"></script>
        <script src="js/leaflet.rotatedMarker.js"></script>
        <script src="js/leaflet.pattern.js"></script>
        <script src="js/leaflet-hash.js"></script>
        <script src="js/Autolinker.min.js"></script>
        <script src="js/rbush.min.js"></script>
        <script src="js/labelgun.min.js"></script>
        <script src="js/labels.js"></script>
        <script src="js/leaflet-measure.js"></script>
        <script type="text/javascript" src="js/proj4js-compressed.min.js"></script>
        <script src="js/fs.js"></script>
        <script>
        var map = L.map('map', {
            zoomControl:true, maxZoom:28, minZoom:1
        })
        var hash = new L.Hash(map);
         map.attributionControl.setPrefix('<a href="https://github.com/tomchadwin/qgis2web" target="_blank">qgis2web</a> &middot; <a href="https://leafletjs.com" title="A JS library for interactive maps">Leaflet</a> &middot; <a href="https://qgis.org">QGIS</a>');
       
        var autolinker = new Autolinker({truncate: {length: 30, location: 'smart'}});
        var measureControl = new L.Control.Measure({
            position: 'topleft',
            primaryLengthUnit: 'meters',
            secondaryLengthUnit: 'kilometers',
            primaryAreaUnit: 'sqmeters',
            secondaryAreaUnit: 'hectares'
        });
        measureControl.addTo(map);
        document.getElementsByClassName('leaflet-control-measure-toggle')[0]
        .innerHTML = '';
        document.getElementsByClassName('leaflet-control-measure-toggle')[0]
        .className += ' fas fa-ruler';
        var bounds_group = new L.featureGroup([]);
        function setBounds() {
            if (bounds_group.getLayers().length) {
                map.fitBounds(bounds_group.getBounds());
            }
        }
//###################  Add TileLayer ##########################        
     //     map.createPane('pane_terrain_6');
//         map.getPane('pane_terrain_6').style.zIndex = 406;
        var layer_terrain_6 = L.tileLayer('http://mt0.google.com/vt/lyrs=p&hl=en&x={x}&y={y}&z={z}', {
          //   pane: 'pane_terrain_6',
            transparent: true,
            attribution: '',
            minZoom: 1,
            maxZoom: 28,
            minNativeZoom: 0,
            maxNativeZoom: 18
        });
        layer_terrain_6;
        //map.addLayer(layer_terrain_6);
//         map.createPane('pane_satellite_7');
//         map.getPane('pane_satellite_7').style.zIndex = 407;
        var layer_satellite_7 = L.tileLayer('http://mt0.google.com/vt/lyrs=s&hl=en&x={x}&y={y}&z={z}', {
         //    pane: 'pane_satellite_7',
            transparent: true,
            attribution: '',
            minZoom: 1,
            maxZoom: 28,
            minNativeZoom: 0,
            maxNativeZoom: 18
        });
        layer_satellite_7;
        map.addLayer(layer_satellite_7);




//###################  Add Amplitude ########################## 
  
  
		var img_D_83_amplitude_avg_4 = 'data/D_83_Amplitude_Average_3.png';
        var img_bounds_D_83_amplitude_avg_4 = [[-37.58750441043919,-71.88663353604751],[-35.390775980741026,-68.85218653917661]];
        var layer_D_83_amplitude_avg_4 = new L.imageOverlay(img_D_83_amplitude_avg_4, img_bounds_D_83_amplitude_avg_4, {
        opacity: 1.0
        });
        bounds_group.addLayer(layer_D_83_amplitude_avg_4);
        //map.addLayer(layer_D_83_amplitude_avg_4);
        var img_A_18_amplitude_avg_5 = 'data/A_18_Amplitude_Average_2.png';
        var img_bounds_A_18_amplitude_avg_5 = [[-37.58750441043919,-71.88663353604751],[-35.390775980741026,-68.85218653917661]];
        var layer_A_18_amplitude_avg_5 = new L.imageOverlay(img_A_18_amplitude_avg_5, img_bounds_A_18_amplitude_avg_5, {
         opacity: 1.0
        });
        bounds_group.addLayer(layer_A_18_amplitude_avg_5);
        map.addLayer(layer_A_18_amplitude_avg_5);
       
//###################  Add Defo ##########################  

             
        var img_MSBAS_LINEAR_RATE_LOS_Asc_0 = 'data/MSBAS_LINEAR_RATE_LOS_Asc_6.png';
        var img_bounds_MSBAS_LINEAR_RATE_LOS_Asc_0 = [[-37.58750441043919,-71.88663353604751],[-35.390775980741026,-68.85218653917661]];
        var layer_MSBAS_LINEAR_RATE_LOS_Asc_0 = new L.imageOverlay(img_MSBAS_LINEAR_RATE_LOS_Asc_0, img_bounds_MSBAS_LINEAR_RATE_LOS_Asc_0, {opacity: 0.7});
        bounds_group.addLayer(layer_MSBAS_LINEAR_RATE_LOS_Asc_0);
       // map.addLayer(layer_MSBAS_LINEAR_RATE_LOS_Asc_0);
        var img_MSBAS_LINEAR_RATE_LOS_Desc_1 = 'data/MSBAS_LINEAR_RATE_LOS_Desc_7.png';
        var img_bounds_MSBAS_LINEAR_RATE_LOS_Desc_1 = [[-37.58750441043919,-71.88663353604751],[-35.390775980741026,-68.85218653917661]];
        var layer_MSBAS_LINEAR_RATE_LOS_Desc_1 = new L.imageOverlay(img_MSBAS_LINEAR_RATE_LOS_Desc_1, img_bounds_MSBAS_LINEAR_RATE_LOS_Desc_1, {opacity: 0.7});
        bounds_group.addLayer(layer_MSBAS_LINEAR_RATE_LOS_Desc_1);
       // map.addLayer(layer_MSBAS_LINEAR_RATE_LOS_Desc_1);
        var img_MSBAS_LINEAR_RATE_EW_2 = 'data/MSBAS_LINEAR_RATE_EW_4.png';
        var img_bounds_MSBAS_LINEAR_RATE_EW_2 = [[-37.58750441043919,-71.88663353604751],[-35.390775980741026,-68.85218653917661]];
        var layer_MSBAS_LINEAR_RATE_EW_2 = new L.imageOverlay(img_MSBAS_LINEAR_RATE_EW_2, img_bounds_MSBAS_LINEAR_RATE_EW_2, {opacity: 0.7});
        bounds_group.addLayer(layer_MSBAS_LINEAR_RATE_EW_2);
        //map.addLayer(layer_MSBAS_LINEAR_RATE_EW_2);
        var img_MSBAS_LINEAR_RATE_UD_3 = 'data/MSBAS_LINEAR_RATE_UD_5.png';
        var img_bounds_MSBAS_LINEAR_RATE_UD_3 = [[-37.58750441043919,-71.88663353604751],[-35.390775980741026,-68.85218653917661]];
        var layer_MSBAS_LINEAR_RATE_UD_3 = new L.imageOverlay(img_MSBAS_LINEAR_RATE_UD_3, img_bounds_MSBAS_LINEAR_RATE_UD_3, {opacity: 0.7});
        bounds_group.addLayer(layer_MSBAS_LINEAR_RATE_UD_3);
        //map.addLayer(layer_MSBAS_LINEAR_RATE_UD_3);
        
    
        var baseMaps = {"satellite": layer_satellite_7,"relief": layer_terrain_6};
        L.control.layers(baseMaps,{"A_18_amplitude_avg": layer_A_18_amplitude_avg_5,"D_83_amplitude_avg": layer_D_83_amplitude_avg_4, "MSBAS_LINEAR_RATE_UD": layer_MSBAS_LINEAR_RATE_UD_3,"MSBAS_LINEAR_RATE_EW": layer_MSBAS_LINEAR_RATE_EW_2,"MSBAS_LINEAR_RATE_LOS_Desc": layer_MSBAS_LINEAR_RATE_LOS_Desc_1,"MSBAS_LINEAR_RATE_LOS_Asc": layer_MSBAS_LINEAR_RATE_LOS_Asc_0,},{collapsed:false}).addTo(map);
        setBounds();
        L.ImageOverlay.include({
            getBounds: function () {
                return this._bounds;
            }
        });
        

//###################  Management of point positionning, record and convert the coordinate ##########################  
        
             function getById(id) {
    return document.getElementById(id);
}   
  var num = 0;
var mapcoords = getById("mapcoords");
var mapcoords2 = getById("mapcoords2");
var mapcoords3 = getById("mapcoords3");
var mapcoords4 = getById("mapcoords4");
Proj4js.defs["EPSG:32719"] = "+proj=utm +zone=19 +south +datum=WGS84 +units=m +no_defs";


map.on("click", function (event) 
{
	num = num + 1;
	if (num == 1)
	{

		 var coord = event.latlng.toString().split(',');
		 var lat = coord[0].split('(');
		 var lng = coord[1].split(')');
		mapcoords.innerHTML = "LAT: " + lat[1] + " and LONG: " + lng[0];
		var pointA = L.marker(event.latlng, {title: "point"+num, alt: 'test', draggable: true})
		.addTo(map);

		var point = new  Proj4js.Point(lng[0], lat[1]); 
		var src = new  Proj4js.Proj("EPSG:32719");
		Proj4js.transform(Proj4js.WGS84, src, point) 
		var X1 = Math.round((point.x - 245000)/50);
		var Y1 = Math.round((6080000 - point.y)/50);
		mapcoords3.innerHTML = " X1 = " + X1 +"  ;  Y1 = " + Y1;
		document.getElementById("X1").value = X1;
		document.getElementById("Y1").value = Y1;

	} else if (num == 2) {
		var coord = event.latlng.toString().split(',');
		 var lat = coord[0].split('(');
		 var lng = coord[1].split(')');
		mapcoords2.innerHTML = "LAT: " + lat[1] + " and LONG: " + lng[0];
		var pointB = L.marker(event.latlng, {title: "point"+num, alt: 'test', draggable: true})
		.addTo(map);

		var point = new  Proj4js.Point(lng[0], lat[1]); 
		var src = new  Proj4js.Proj("EPSG:32719");
		Proj4js.transform(Proj4js.WGS84, src, point) 
		var X2 = Math.round((point.x - 245000)/50);
		var Y2 = Math.round((6080000 - point.y)/50);
		mapcoords4.innerHTML = " X2 = " + X2 +"  ;  Y2 = " + Y2;
		document.getElementById("X2").value = X2;
		document.getElementById("Y2").value = Y2;

		pointB.on('dragend', function(a) {
		var coord = String(pointB.getLatLng()).split(',');
		console.log(coord);
		var lat = coord[0].split('(');
		console.log(lat);
		var lng = coord[1].split(')');
		console.log(lng);
		mapcoords2.innerHTML = "LAT: " + lat[1] + " and LONG: " + lng[0];	

		var point = new  Proj4js.Point(lng[0], lat[1]); 
		var src = new  Proj4js.Proj("EPSG:32719");
		Proj4js.transform(Proj4js.WGS84, src, point) 
		var X2 = Math.round((point.x - 245000)/50);
		var Y2 = Math.round((6080000 - point.y)/50);
		mapcoords4.innerHTML = " X2 = " + X2 +"  ;  Y2 = " + Y2;
		document.getElementById("X2").value = X2;
		document.getElementById("Y2").value = Y2;
		});
	} 	  		

	pointA.on('dragend', function() 
	{
	var coord = String(pointA.getLatLng()).split(',');
	console.log(coord);
	var lat = coord[0].split('(');
	console.log(lat);
	var lng = coord[1].split(')');
	console.log(lng);
	mapcoords.innerHTML = "LAT: " + lat[1] + " and LONG: " + lng[0];	

	var point = new  Proj4js.Point(lng[0], lat[1]); 
	var src = new  Proj4js.Proj("EPSG:32719");
	Proj4js.transform(Proj4js.WGS84, src, point) 
	var X1 = Math.round((point.x - 245000)/50);
	var Y1 = Math.round((6080000 - point.y)/50);
	mapcoords3.innerHTML = " X1 = " + X1 +"  ;  Y1 = " + Y1;
	document.getElementById("X1").value = X1;
	document.getElementById("Y1").value = Y1;
	});

 
});	  		

  
        
        </script>
    </body>
  		<p class="ref">References: please cite 
- d’Oreye N., Derauw D., Libert L., Samsonov S., Dille A., Nobile A., Monsieiurs E., Dewitte O., Kervyn F. (2019). Automatization of InSAR mass processing using CSL InSAR Suite (CIS) software for Multidimensional Small Baseline Subset (MSBAS) analysis: example combining Sentinel-1 and Cosmo-SkyMed SAR data for landslides monitoring in South Kivu, DR Congo. Abstract, 13-17 May 2019, ESA Living Planet Symposium 2019, Milano, Italy
- Samsonov, S., A. Dille, O. Dewitte, F. Kervyn, and N. d'Oreye (2020). Satellite interferometry for mapping surface deformation time series in one, two and three dimensions: A new method illustrated on a slow-moving landslide. Engineering Geology, (266), 105471, doi:10.1016/j.enggeo.2019.105471.
- Derauw D., d’Oreye N., Jaspard M., Caselli A (submitted). Ongoing automated Ground Deformation monitoring of Domuyo - Laguna del Maule area (Argentina) using Sentinel-1 MSBAS time series: Methodology description and first observations for the period 2015 – 2020.
<p>


</html>
