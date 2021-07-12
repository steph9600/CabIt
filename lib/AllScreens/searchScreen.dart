import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:rider_app/Assistants/address.dart';
import 'package:rider_app/Assistants/appData.dart';
import 'package:rider_app/Assistants/placePredictions.dart';
import 'package:rider_app/Assistants/requestAssistant.dart';
import 'package:rider_app/Widgets/divider.dart';
import 'package:rider_app/Widgets/progressDialog.dart';
import 'package:rider_app/components/configMaps.dart';

class SearchScreen extends StatefulWidget {
  static const String id = 'searchScreen';
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController dropOffTextEditingController = TextEditingController();
  List<PlacePredictions> placePredictionList = [];

  @override
  Widget build(BuildContext context) {
    String placeAddress =
        Provider.of<AppData>(context).pickUpLocation.placeName ?? "";
    setState(() {
      pickUpTextEditingController.text = placeAddress;
    });
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 220.0,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 6.0,
                  spreadRadius: 0.5,
                  offset: Offset(0.7, 0.7),
                )
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                  left: 25.0, top: 30.0, right: 25.0, bottom: 20.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 6.0,
                  ),
                  Stack(
                    children: [
                      GestureDetector(
                        child: Icon(Icons.arrow_back),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      Center(
                        child: Text('Set drop off',
                            style: TextStyle(
                                fontSize: 18.0, fontFamily: 'Brand-Bold')),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    children: [
                      Image.asset('images/pickicon.png',
                          height: 25.0, width: 25.0),
                      SizedBox(width: 18.0),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[500],
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(4.0),
                            child: TextField(
                              controller: pickUpTextEditingController,
                              decoration: InputDecoration(
                                  hintText: 'Pick up location.',
                                  fillColor: Colors.white70,
                                  filled: true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(
                                      left: 11.0,
                                      bottom: 8.0,
                                      right: 11.0,
                                      top: 8.0)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    children: [
                      Image.asset('images/desticon.png',
                          height: 25.0, width: 25.0),
                      SizedBox(width: 18.0),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[500],
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(4.0),
                            child: TextField(
                              onChanged: (val) {
                                findPlace(val);
                              },
                              controller: dropOffTextEditingController,
                              decoration: InputDecoration(
                                  hintText: 'Where to?',
                                  fillColor: Colors.white70,
                                  filled: true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(
                                      left: 11.0,
                                      bottom: 8.0,
                                      right: 11.0,
                                      top: 8.0)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          SizedBox(height: 10.0),
          (placePredictionList.length > 0)
              ? Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  child: ListView.separated(
                    padding: EdgeInsets.all(0.0),
                    itemBuilder: (context, index) {
                      return PredictionTile(
                        placePredictions: placePredictionList[index],
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        DividerWidget(),
                    itemCount: placePredictionList.length,
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                  ),
                )
              : Container()
          //tile for places predictions
        ],
      ),
    );
  }

  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      String autoCompleteURL =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$apiKey&sessiontoken=1234567890&components=country:ng";
      var res = await RequestAssistant.getRequest(autoCompleteURL);
      if (res == "failed") {
        return;
      }
      if (res["status"] == "OK") {
        var predictions = res["predictions"];
        var placesList = (predictions as List)
            .map((e) => PlacePredictions.fromJson(e))
            .toList();
        setState(() {
          placePredictionList = placesList;
        });
      }
    }
  }
}

class PredictionTile extends StatelessWidget {
  final PlacePredictions placePredictions;
  const PredictionTile({Key key, this.placePredictions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style:
          ButtonStyle(padding: MaterialStateProperty.all(EdgeInsets.all(0.0))),
      onPressed: () {
        getPlaceAddressDetails(placePredictions.place_id, context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(height: 5.0),
            Row(
              children: [
                Icon(Icons.add_location, size: 25.0, color: Color(0xffff9800)),
                SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.0),
                      Text(
                        placePredictions.main_text,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16.0),
                      ),
                      SizedBox(height: 2.0),
                      Text(placePredictions.secondary_text,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.0, color: Colors.grey)),
                      SizedBox(height: 6.0),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: 5.0),
          ],
        ),
      ),
    );
  }

  void getPlaceAddressDetails(String placeId, context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: 'Getting location. Please wait...',
            ));
    String placeDetailsUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey";
    var res = await RequestAssistant.getRequest(placeDetailsUrl);
    Navigator.pop(context);

    if (res == "failed") {
      return;
    }
    if (res["status"] == "OK") {
      Address address = Address();
      address.placeName = res["result"]["name"];
      address.placeId = placeId;
      address.latitude = res["result"]["geometry"]["location"]["lat"];
      address.longitude = res["result"]["geometry"]["location"]["lng"];

      Provider.of<AppData>(context, listen: false)
          .updatedropOffLocationAddress(address);

      Navigator.pop(context, "obtainDirection");
    }
  }
}
