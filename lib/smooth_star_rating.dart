library smooth_star_rating;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef void RatingChangeCallback(double rating);

class SmoothStarRating extends StatefulWidget {
  final int starCount;
  final double rating;
  final RatingChangeCallback onRated;
  final RatingChangeCallback onHover;
  final Color color;
  final Color borderColor;
  final double size;
  final bool allowHalfRating;
  final IconData filledIconData;
  final IconData halfFilledIconData;
  final IconData
      defaultIconData; //this is needed only when having fullRatedIconData && halfRatedIconData
  final double spacing;
  final bool isReadOnly;
  SmoothStarRating({
    this.starCount = 5,
    this.isReadOnly = false,
    this.spacing = 0.0,
    this.rating = 0.0,
    this.defaultIconData = Icons.star_border,
    this.onRated,
    this.onHover,
    this.color,
    this.borderColor,
    this.size = 25,
    this.filledIconData = Icons.star,
    this.halfFilledIconData = Icons.star_half,
    this.allowHalfRating = true,
  }) {
    assert(this.rating != null);
  }
  @override
  _SmoothStarRatingState createState() => _SmoothStarRatingState();
}

class _SmoothStarRatingState extends State<SmoothStarRating> {
  final double halfStarThreshold =
      0.53; //half star value starts from this number

  //tracks for user tapping on this widget
  bool isWidgetTapped = false;
  double initialRating;
  double currentRating;
  Timer debounceTimer;

  @override
  void initState() {
    initialRating = widget.rating;
    currentRating = widget.rating;
    super.initState();
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    debounceTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (initialRating != widget.rating) {
      currentRating = widget.rating;
      initialRating = widget.rating;
    }

    //print('Rebuild CR:$currentRating WR:${widget.rating}');
    return Material(
      color: Colors.transparent,
      child: Wrap(
          alignment: WrapAlignment.start,
          spacing: widget.spacing,
          children: List.generate(
              widget.starCount, (index) => buildStar(context, index))),
    );
  }

  Widget buildStar(BuildContext context, int index) {
    Icon icon;
    if (index >= currentRating) {
      icon = Icon(
        widget.defaultIconData,
        color: widget.borderColor ?? Theme.of(context).primaryColor,
        size: widget.size,
      );
    } else if (index >
            currentRating -
                (widget.allowHalfRating ? halfStarThreshold : 1.0) &&
        index < currentRating) {
      icon = Icon(
        widget.halfFilledIconData,
        color: widget.color ?? Theme.of(context).primaryColor,
        size: widget.size,
      );
    } else {
      icon = Icon(
        widget.filledIconData,
        color: widget.color ?? Theme.of(context).primaryColor,
        size: widget.size,
      );
    }
    final Widget star = widget.isReadOnly
        ? icon
        : kIsWeb
            ? MouseRegion(
                onExit: (event) {
                  if (widget.onRated != null && !isWidgetTapped) {
                    //reset to zero only if rating is not set by user
                    setState(() {
                      currentRating = 0;
                      if (widget.onHover != null) widget.onHover(0);
                    });
                  }
                },
                onEnter: (event) {
                  isWidgetTapped = false; //reset
                },
                onHover: (event) {
                  RenderBox box = context.findRenderObject();
                  var _pos = box.globalToLocal(event.position);
                  var i = _pos.dx / widget.size;
                  setNewRating(i);
                },
                child: GestureDetector(
                  onTapDown: (detail) {
                    isWidgetTapped = true;

                    RenderBox box = context.findRenderObject();
                    var _pos = box.globalToLocal(detail.globalPosition);
                    var i = ((_pos.dx - widget.spacing) / widget.size);
                    setNewRating(i);
                    if (widget.onRated != null) {
                      widget.onRated(normalizeRating(currentRating));
                    }
                  },
                  onHorizontalDragUpdate: (dragDetails) {
                    isWidgetTapped = true;

                    RenderBox box = context.findRenderObject();
                    var _pos = box.globalToLocal(dragDetails.globalPosition);
                    var i = _pos.dx / widget.size;
                    var newRating = setNewRating(i);

                    debounceTimer?.cancel();
                    debounceTimer = Timer(Duration(milliseconds: 100), () {
                      if (widget.onRated != null) {
                        currentRating = normalizeRating(newRating);
                        widget.onRated(currentRating);
                      }
                    });
                  },
                  child: icon,
                ),
              )
            : GestureDetector(
                onTapDown: (detail) {
                  RenderBox box = context.findRenderObject();
                  var _pos = box.globalToLocal(detail.globalPosition);
                  var i = ((_pos.dx - widget.spacing) / widget.size);
                  setNewRating(i, normalize: true);
                },
                onTapUp: (e) {
                  if (widget.onRated != null) widget.onRated(currentRating);
                },
                onHorizontalDragUpdate: (dragDetails) {
                  RenderBox box = context.findRenderObject();
                  var _pos = box.globalToLocal(dragDetails.globalPosition);
                  var i = _pos.dx / widget.size;
                  var newRating = setNewRating(i);
                  debounceTimer?.cancel();
                  debounceTimer = Timer(Duration(milliseconds: 100), () {
                    if (widget.onRated != null) {
                      currentRating = normalizeRating(newRating);
                      widget.onRated(currentRating);
                    }
                  });
                },
                child: icon,
              );

    return star;
  }

  double setNewRating(double i, {bool normalize = false}) {
    var newRating = widget.allowHalfRating ? i : i.round().toDouble();
    if (newRating > widget.starCount) {
      newRating = widget.starCount.toDouble();
    }
    if (newRating < 0) {
      newRating = 0.0;
    }
    if (normalize) {
      newRating = normalizeRating(newRating);
    }

    setState(() {
      if (widget.onHover != null && currentRating != newRating)
        widget.onHover(newRating);
      currentRating = newRating;
    });

    return newRating;
  }

  double normalizeRating(double newRating) {
    var k = newRating - newRating.floor();
    if (k != 0) {
      //half stars
      if (k >= halfStarThreshold) {
        newRating = newRating.floor() + 1.0;
      } else {
        newRating = newRating.floor() + 0.5;
      }
    }
    return newRating;
  }
}
