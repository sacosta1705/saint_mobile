import 'package:flutter/material.dart';

class ProductItem {
  String coditem;
  String description;
  double quantity;
  double priceNoTax;
  double priceTax;
  late double totalNoTax;
  late double itemTaxAmount;
  List<TextEditingController> commentControllers;

  ProductItem({
    required this.coditem,
    required this.description,
    this.quantity = 1.0,
    required this.priceNoTax,
    required this.priceTax,
  }) : commentControllers = List.generate(10, (_) => TextEditingController()) {
    _calculateTotals();
  }

  void _calculateTotals() {
    totalNoTax = quantity * priceNoTax;
    if (priceTax > priceNoTax) {
      itemTaxAmount = (priceTax - priceNoTax) * quantity;
    } else {
      itemTaxAmount = 0;
    }
  }

  void updateQuantity(double newQuantity) {
    quantity = newQuantity > 0 ? newQuantity : 0;
    _calculateTotals();
  }

  Map<String, dynamic> toJson() {
    List<String> nonEmptyComments = commentControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    return {
      "coditem": coditem,
      "comments": nonEmptyComments,
      "precio": priceNoTax,
      "cantidad": quantity,
      "mtotax": itemTaxAmount,
      "descomp": 1,
      "desseri": 0,
      "deslote": 0,
      "nrounicol": 0,
      "nrolote": "",
      "parts": [],
      "serials": [],
      "additional": []
    };
  }

  void disposeCommentControllers() {
    for (var controller in commentControllers) {
      controller.dispose();
    }
  }
}
