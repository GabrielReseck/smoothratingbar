import 'package:flutter/material.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var rating = 0.0;
  var hoverValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rating bar demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            children: [
              SmoothStarRating(
                rating: rating,
                isReadOnly: false,
                size: 80,
                filledIconData: Icons.star,
                halfFilledIconData: Icons.star_half,
                defaultIconData: Icons.star_border,
                starCount: 5,
                allowHalfRating: true,
                onRated: (value) {
                  print("onPress $value");
                  rating = value;
                  setState(() {});
                },
                onHover: (x) {
                  setState(() {
                    hoverValue = x;
                    //print('onHover $hoverValue');
                  });
                },
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    rating == 5 ? rating = 0 : rating = 5;
                    print('New rating: $rating');
                  });
                },
                child: Text('Toggle ($rating , $hoverValue)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
