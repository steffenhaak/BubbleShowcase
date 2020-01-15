import 'package:flutter/material.dart';

class BubbleShowcaseController extends ValueNotifier<bool> {
  
  BubbleShowcaseController() : super(false);

  void open() {
    value = true;
  }

}