library smooth_star_rating;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef void RatingChangeCallback(double rating);

class SmoothStarRating extends StatefulWidget {
  final int starCount;
  final double rating;
  final RatingChangeCallback? onRated;
  final RatingChangeCallback? onHover;
  final Color? color;
  final Color? borderColor;
  final double size;
  final bool allowHalfRating;
  final IconData filledIconData;
  final IconData halfFilledIconData;
  final IconData
      defaultIconData; //this is needed only when having fullRatedIconData && halfRatedIconData
  final bool isReadOnly;
  const SmoothStarRating({
    this.starCount = 5,
    this.isReadOnly = false,
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
  });

  @override
  _SmoothStarRatingState createState() => _SmoothStarRatingState();
}

class _SmoothStarRatingState extends State<SmoothStarRating> {
  ///Half star value starts from this number
  static const double halfStarThreshold = 0.53;

  late double initialRating;
  late double currentRating;
  double lastTappedRating = 0.0;

  Timer? debounceTimer;

  @override
  void initState() {
    initialRating = widget.rating;
    currentRating = widget.rating;
    super.initState();
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (initialRating != widget.rating) {
      currentRating = widget.rating;
      initialRating = widget.rating;
    }

    return Material(
      color: Colors.transparent,
      child: Wrap(
        alignment: WrapAlignment.start,
        children: List.generate(
          widget.starCount,
          (index) => buildStar(context, index),
        ),
      ),
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
                  //Resets to lastTappedRating onExit
                  setState(() {
                    currentRating = lastTappedRating;
                    if (widget.onHover != null)
                      widget.onHover!(lastTappedRating);
                  });
                },
                onHover: (event) {
                  RenderBox box = context.findRenderObject() as RenderBox;
                  var _pos = box.globalToLocal(event.position);
                  var i = _pos.dx / widget.size;
                  setNewRating(i);
                },
                child: GestureDetector(
                  onTapDown: (detail) {
                    RenderBox box = context.findRenderObject() as RenderBox;
                    var _pos = box.globalToLocal(detail.globalPosition);
                    var i = _pos.dx / widget.size;
                    setNewRating(i, isTap: true);
                    if (widget.onRated != null) {
                      widget.onRated!(normalizeRating(currentRating));
                    }
                  },
                  onHorizontalDragUpdate: (dragDetails) {
                    RenderBox box = context.findRenderObject() as RenderBox;
                    var _pos = box.globalToLocal(dragDetails.globalPosition);
                    var i = _pos.dx / widget.size;
                    var newRating = setNewRating(i, isTap: true);

                    debounceTimer?.cancel();
                    debounceTimer = Timer(Duration(milliseconds: 100), () {
                      if (widget.onRated != null) {
                        currentRating = normalizeRating(newRating);
                        widget.onRated!(currentRating);
                      }
                    });
                  },
                  child: icon,
                ),
              )
            : GestureDetector(
                onTapDown: (detail) {
                  RenderBox box = context.findRenderObject() as RenderBox;
                  var _pos = box.globalToLocal(detail.globalPosition);
                  var i = _pos.dx / widget.size;
                  setNewRating(i, normalize: true, isTap: true);
                },
                onTapUp: (e) {
                  if (widget.onRated != null) {
                    widget.onRated!(currentRating);
                  }
                },
                onHorizontalDragUpdate: (dragDetails) {
                  RenderBox box = context.findRenderObject() as RenderBox;
                  var _pos = box.globalToLocal(dragDetails.globalPosition);
                  var i = _pos.dx / widget.size;
                  var newRating = setNewRating(i, isTap: true);
                  debounceTimer?.cancel();
                  debounceTimer = Timer(Duration(milliseconds: 100), () {
                    if (widget.onRated != null) {
                      currentRating = normalizeRating(newRating);
                      widget.onRated!(currentRating);
                    }
                  });
                },
                child: icon,
              );

    return star;
  }

  double setNewRating(
    double i, {
    bool normalize = false,
    bool isTap = false,
  }) {
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
      if (widget.onHover != null && currentRating != newRating) {
        widget.onHover!(newRating);
      }
      currentRating = newRating;
      if (isTap) {
        lastTappedRating = newRating;
      }
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
