import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_app/AllScreens/loginScreen.dart';
import 'package:rider_app/Assistants/appData.dart';
import 'package:rider_app/Assistants/directionDetails.dart';
import 'package:rider_app/Assistants/geoFireAssistant.dart';
import 'package:rider_app/Assistants/locator.dart';
import 'package:rider_app/Assistants/nearbyAvailableDrivers.dart';
import 'package:rider_app/Widgets/divider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:rider_app/AllScreens/searchScreen.dart';
import 'package:rider_app/Widgets/progressDialog.dart';
import 'package:rider_app/components/configMaps.dart';

class MainScreen extends StatefulWidget {
  static const String id = 'mainScreen';

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DirectionDetails tripDirectionDetails;

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight = 300.0;

  bool drawerOpen = true;
  bool nearbyAvailableDriversKeysLoaded = false;

  BitmapDescriptor nearbyIcon;

  var colorizeColors = [
    Color(0xff3f50b5),
    Colors.purple,
    Color(0xffff9800),
    Colors.yellowAccent
  ];
  var colorizeTextStyle = TextStyle(
      fontSize: 40.0, fontWeight: FontWeight.bold, fontFamily: 'Noto_Serif');

  DatabaseReference rideRequestRef;

  initState() {
    super.initState();
    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.reference().child("Ride Request").push();

    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocMap = {
      "latitude": pickUp.latitude.toString(),
      "longitude": pickUp.longitude.toString()
    };
    Map dropOffLocMap = {
      "latitude": dropOff.latitude.toString(),
      "longitude": dropOff.longitude.toString()
    };
    Map rideInfoMap = {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpLocMap,
      "dropoff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo.name,
      "rider_phone": userCurrentInfo.phone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": pickUp.placeName,
    };
    rideRequestRef.set(rideInfoMap);
  }

  void cancelRideRequest() {
    rideRequestRef.remove();
  }

  displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 300.0;
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230;
      drawerOpen = true;
    });

    saveRideRequest();
  }

  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 230;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });

    locatePosition();
  }

  void displayRideDetailsContainer() async {
    await getPlaceDirection();
    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 250.0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = false;
    });
  }

  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;
    LatLng latLngposition = LatLng(position.latitude, position.longitude);
    CameraPosition cameraPosition =
        new CameraPosition(target: latLngposition, zoom: 15);
    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address =
        await AssistantMethods.searchCoordinateAddress(position, context);
    initGeoFireListener();
  }

  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
      key: scaffoldKey,
      /*appBar: AppBar(
        backgroundColor: Color(0xff3f50b5),
        title: Center(
          child: Text(
            'Cab It',
          ),
        ),
      ),*/
      drawer: Container(
        color: Colors.white,
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              //drawer header
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/user_icon.png',
                        height: 65.0,
                        width: 65.0,
                      ),
                      SizedBox(width: 16.0),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Profile Name',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontFamily: 'Brand-Bold',
                            ),
                          ),
                          SizedBox(height: 6.0),
                          Text('Visit Profile')
                        ],
                      )
                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(height: 12.0),
              //Drawer Body Controller
              ListTile(
                leading: Icon(
                  Icons.history,
                  color: Color(0xff3f50b5),
                ),
                title: Text('History', style: TextStyle(fontSize: 15.0)),
              ),
              ListTile(
                leading: Icon(
                  Icons.person,
                  color: Color(0xff3f50b5),
                ),
                title: Text('Visit Profile', style: TextStyle(fontSize: 15.0)),
              ),
              ListTile(
                leading: Icon(
                  Icons.info,
                  color: Color(0xff3f50b5),
                ),
                title: Text('Settings', style: TextStyle(fontSize: 15.0)),
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.id, (route) => false);
                },
                child: ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Color(0xff3f50b5),
                  ),
                  title: Text('Log Out', style: TextStyle(fontSize: 15.0)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              setState(() {
                bottomPaddingOfMap = 300.0;
              });

              locatePosition();
            },
          ),
          //Button for Drawer
          Positioned(
            top: 38.0,
            left: 22.0,
            child: GestureDetector(
              onTap: () {
                if (drawerOpen = true) {
                  scaffoldKey.currentState.openDrawer();
                } else {
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.0),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black,
                        blurRadius: 6.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7))
                  ],
                ),
                child: CircleAvatar(
                  radius: 25.0,
                  backgroundColor: Colors.white,
                  child: Icon(
                    (drawerOpen) ? Icons.menu : Icons.close,
                    size: 35.0,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25.0),
                      topRight: Radius.circular(25.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 15.0,
                        spreadRadius: 1.0,
                        offset: Offset(0.7, 0.7),
                      ),
                    ]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 18.0, horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.0),
                      Text('Hello', style: TextStyle(fontSize: 12.0)),
                      Text(
                        'Where is your destination?',
                        style:
                            TextStyle(fontSize: 17.5, fontFamily: 'Brand-Bold'),
                      ),
                      SizedBox(height: 20.0),
                      GestureDetector(
                        onTap: () async {
                          var res = await Navigator.pushNamed(
                              context, SearchScreen.id);
                          if (res == "obtainDirection") {
                            displayRideDetailsContainer();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 5.0,
                                spreadRadius: 1.0,
                                offset: Offset(0.7, 0.7),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Color(0xff3f50b5),
                                ),
                                SizedBox(width: 25.0),
                                Text(
                                  'Search drop off location',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.0),
                      Row(
                        children: [
                          Icon(Icons.home, color: Color(0xff3f50b5)),
                          SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Provider.of<AppData>(context)
                                              .pickUpLocation !=
                                          null
                                      ? Provider.of<AppData>(context)
                                          .pickUpLocation
                                          .placeName
                                      : 'Add Home',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.black),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  'Your home address',
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 12.0),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 10.0),
                      DividerWidget(),
                      SizedBox(height: 10.0),
                      Row(
                        children: [
                          Icon(Icons.work_rounded, color: Color(0xff3f50b5)),
                          SizedBox(width: 12.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Work',
                                  style: TextStyle(color: Colors.black)),
                              SizedBox(height: 4.0),
                              Text(
                                'Your office address',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12.0),
                              )
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black,
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7))
                  ],
                ),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.tealAccent,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8.0))),
                        width: double.infinity,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.0, vertical: 10.0),
                          child: Row(
                            children: [
                              Image.asset(
                                'images/taxi.png',
                                height: 70.0,
                                width: 80.0,
                              ),
                              SizedBox(width: 12.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Car',
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontFamily: 'Brand-Bold')),
                                  Text(
                                    ((tripDirectionDetails != null)
                                        ? tripDirectionDetails.distanceText
                                        : ''),
                                    style: TextStyle(
                                        fontSize: 14.0,
                                        fontFamily: 'Brand-Bold',
                                        color: Colors.grey),
                                  )
                                ],
                              ),
                              Expanded(
                                child: Container(),
                              ),
                              Text(
                                ((tripDirectionDetails != null)
                                    ? '₦${AssistantMethods.calculateFare(tripDirectionDetails)}'
                                    : ''),
                                style: TextStyle(
                                  fontFamily: 'Brand-Bold',
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24.0),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.moneyCheckAlt,
                                size: 16.0, color: Colors.black54),
                            SizedBox(width: 16.0),
                            Text('Cash'),
                            SizedBox(width: 6.0),
                            Icon(Icons.keyboard_arrow_down,
                                color: Colors.black54, size: 16.0)
                          ],
                        ),
                      ),
                      SizedBox(height: 20.0),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: ElevatedButton(
                          onPressed: () {
                            displayRequestRideContainer();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(17.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Request Ride',
                                    style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                Icon(
                                  FontAwesomeIcons.taxi,
                                  color: Colors.white,
                                  size: 26.0,
                                )
                              ],
                            ),
                          ),
                          style: ButtonStyle(
                              elevation: MaterialStateProperty.all(10.0),
                              backgroundColor:
                                  MaterialStateProperty.all(Color(0xff3f50b5))),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              height: requestRideContainerHeight,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0)),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        spreadRadius: 0.5,
                        blurRadius: 16.0,
                        color: Colors.black54,
                        offset: Offset(0.7, 0.7)),
                  ]),
              child: Column(
                children: [
                  SizedBox(height: 12.0),
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          ColorizeAnimatedText(
                            'Requesting a ride...',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                          ),
                          ColorizeAnimatedText(
                            'Please wait...',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                          ),
                          ColorizeAnimatedText(
                            'Finding a driver...',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        isRepeatingAnimation: true,
                        onTap: () {
                          print("Tap Event");
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 5.0),
                  GestureDetector(
                    onTap: () {
                      cancelRideRequest();
                      resetApp();
                    },
                    child: Container(
                      child: Icon(Icons.close, size: 35.0),
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26.0),
                        border: Border.all(
                          width: 2.0,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Container(
                    width: double.infinity,
                    child: Text(
                      'Cancel ride',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.0),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        message: 'Please wait..',
      ),
    );

    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLatLng, dropOffLatLng);
    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.pop(context);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolylinePointsResults =
        polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();
    if (decodedPolylinePointsResults.isNotEmpty) {
      decodedPolylinePointsResults.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pickUpLatLng.longitude));
      });
    }
    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        color: Colors.pink,
        polylineId: PolylineId("Polyline"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
        northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
      );
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
        southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
        northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
      );
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }
    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));
    Marker pickUpLocationMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow:
          InfoWindow(title: initialPos.placeName, snippet: 'My Location'),
      position: pickUpLatLng,
      markerId: MarkerId('pickupId'),
    );
    Marker dropOffLocationMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: finalPos.placeName, snippet: 'Drop Off Location'),
        position: dropOffLatLng,
        markerId: MarkerId('dropOffId'));

    setState(() {
      markersSet.add(pickUpLocationMarker);
      markersSet.add(dropOffLocationMarker);
    });

    Circle pickUpLocationCircle = Circle(
      fillColor: Colors.blue,
      center: pickUpLatLng,
      radius: 12.0,
      strokeWidth: 4,
      strokeColor: Colors.blue,
      circleId: CircleId('pickupId'),
    );

    Circle dropOffLocationCircle = Circle(
      fillColor: Colors.deepPurple,
      center: dropOffLatLng,
      radius: 12.0,
      strokeWidth: 4,
      strokeColor: Colors.deepPurple,
      circleId: CircleId('dropOffId'),
    );

    setState(() {
      circlesSet.add(pickUpLocationCircle);
      circlesSet.add(dropOffLocationCircle);
    });
  }

  void initGeoFireListener() {
    Geofire.initialize("availableDrivers");
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 5)
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers(
                    key: map['key'],
                    latitude: map['latitude'],
                    longitude: map['key']);
            GeoFireAssistant.nearbyAvailableDriversList
                .add(nearbyAvailableDrivers);
            if (nearbyAvailableDriversKeysLoaded == true) {
              updateAvailableDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map['key']);
            break;

          case Geofire.onKeyMoved:
            // Update your key's location
            NearbyAvailableDrivers nearbyAvailableDrivers =
                NearbyAvailableDrivers(
                    key: map['key'],
                    latitude: map['latitude'],
                    longitude: map['key']);
            GeoFireAssistant.updateDriverNearbyLocation(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();

            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();

            break;
        }
      }

      setState(() {});
    });
  }

  void updateAvailableDriversOnMap() {
    setState(() {
      markersSet.clear();
    });
    Set<Marker> tMarkers = Set<Marker>();
    for (NearbyAvailableDrivers driver
        in GeoFireAssistant.nearbyAvailableDriversList) {
      LatLng driverAvailablePosition =
          LatLng(driver.latitude, driver.longitude);
      Marker marker = Marker(
          markerId: MarkerId('driver${driver.key}'),
          position: driverAvailablePosition,
          icon: nearbyIcon,
          rotation: AssistantMethods.createRandomNumber(360));
      tMarkers.add(marker);
      setState(() {
        markersSet = tMarkers;
      });
    }
  }

  void createIconMarker() {
    if (nearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, 'images/car_android.png')
          .then((value) {
        nearbyIcon = value;
      });
    }
  }
}
