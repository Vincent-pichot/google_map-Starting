import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_mao/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({Key? key}) : super(key: key);

  @override
  State<OrderTrackingPage> createState() => OrderTrackingPageState();
}

class RequestReceiver {
  final String latitude;
  final String longitude;

  RequestReceiver({required this.latitude, required this.longitude});

  factory RequestReceiver.fromJson(Map<String, dynamic> json) {
    return RequestReceiver(
        latitude: json['latitude'], longitude: json['longitude']);
  }
}

class OrderTrackingPageState extends State<OrderTrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();

  // this will hold the generated polylines
  // Set<Polyline> _polylines = {};
  // // this will hold each polyline coordinate as Lat and Lng pairs
  List<LatLng> polylineCoordinates = [];
  // // this is the key object - the PolylinePoints
  // // which generates every polyline between start and finish
  // PolylinePoints polylinePoints = PolylinePoints();
  // String googleAPIKey = ;
  Timer? timer;

  LatLng destination = LatLng(37.33429383, -122.06600055);

  // List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;

  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;

  void getCurrentLocation() async {
    Location location = Location();

    location.getLocation().then(
      (location) {
        currentLocation = location;
      },
    );

    GoogleMapController googleMapController = await _controller.future;

    location.onLocationChanged.listen(
      (newLoc) {
        currentLocation = newLoc;

        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
                zoom: 13.5,
                target: LatLng(
                  newLoc.latitude!,
                  newLoc.longitude!,
                )),
          ),
        );

        setState(() {});
      },
    );
  }

  // setPolylines() async {
  //   List<PointLatLng> result = await polylinePoints?.getRouteBetweenCoordinates(
  //       googleAPIKey,
  //       PointLatLng(currentLocation!.latitude!),
  //       PointLatLng(currentLocation!.longitude!),
  //       DEST_LOCATION.latitude,
  //       DEST_LOCATION.longitude);
  //   if (result.isNotEmpty) {
  //     // loop through all PointLatLng points and convert them
  //     // to a list of LatLng, required by the Polyline
  //     result.forEach((PointLatLng point) {
  //       polylineCoordinates.add(LatLng(point.latitude, point.longitude));
  //     });
  //   }

  //   setState(() {
  //     // create a Polyline instance
  //     // with an id, an RGB color and the list of LatLng pairs
  //     Polyline polyline = Polyline(
  //         polylineId: PolylineId("poly"),
  //         color: Color.fromARGB(255, 40, 122, 198),
  //         points: polylineCoordinates);

  //     // add the constructed polyline as a set of points
  //     // to the polyline set, which will eventually
  //     // end up showing up on the map
  //     _polylines.add(polyline);
  //   });
  // }

  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration.empty, "assets/Pin_current_location.png")
        .then((icon) {
      currentLocationIcon = icon;
    });

    BitmapDescriptor.fromAssetImage(
            ImageConfiguration.empty, "assets/Pin_destination.png")
        .then((icon) {
      destinationIcon = icon;
    });
  }

  @override
  void initState() {
    getData();
    getCurrentLocation();
    setCustomMarkerIcon();
    timer = Timer.periodic(const Duration(seconds: 180), (Timer t) {getData();setState(() {});} );
    //getPolyPoints();
    super.initState();
  }

  Future getData() async {
    var url = 'http://82.165.248.152/get.php';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // var data = RequestReceiver.fromJson(jsonDecode(response.body));
      var data = jsonDecode(response.body);
      var data2 = RequestReceiver.fromJson(data.last);
      destination =
          LatLng(double.parse(data2.latitude), double.parse(data2.longitude));
      print(destination);
      print(data);
      print(data2.latitude);
      print(data2.longitude);
    }
    // print(response.statusCode);
    // print(data.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Track order",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: currentLocation == null
          ? Center(
              child: TextButton(
                  child: const Text("View you pet location"),
                  onPressed: () => setState(() {})))
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    currentLocation!.latitude!, currentLocation!.longitude!),
                zoom: 13.5,
              ), //CameraPosition
              polylines: {
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: polylineCoordinates,
                  color: primaryColor,
                  width: 6,
                ),
              }, //Polylines
              markers: {
                Marker(
                    markerId: const MarkerId("currentLocation"),
                    icon: currentLocationIcon,
                    position: LatLng(currentLocation!.latitude!,
                        currentLocation!.longitude!)),
                Marker(
                  markerId: const MarkerId("destination"),
                  icon: destinationIcon,
                  position: destination,
                ),
              }, //Markers
              onMapCreated: (mapController) {
                _controller.complete(mapController);
                // setPolylines();
              },
            ),
    );
  }
}
