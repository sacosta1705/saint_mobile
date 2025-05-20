// transaction_model.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductItem {
  String coditem;
  String description;
  double quantity;
  double priceNoTax;
  double priceTax;
  late double totalNoTax;
  late double itemTaxAmount;
  List<TextEditingController> commentControllers; // Controllers para los comentarios

  ProductItem({
    required this.coditem,
    required this.description,
    this.quantity = 1.0,
    required this.priceNoTax,
    required this.priceTax,
  }) : commentControllers = List.generate(10, (_) => TextEditingController()){
    _calculateTotals();
  }

  void _calculateTotals(){
    totalNoTax = quantity * priceNoTax;
    if(priceTax > priceNoTax){
      itemTaxAmount = (priceTax - priceNoTax) * quantity;
    } else {
      itemTaxAmount = 0;
    }
  }

  void updateQuantity(double newQuantity) {
    quantity = newQuantity > 0 ? newQuantity : 0;
    _calculateTotals();
  }

  // Los comentarios se actualizan directamente a través de los controllers en la UI

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

class PaymentItem {
  String codtarj;
  String descrip;
  double amount;
  String fechae;

  PaymentItem({
    required this.codtarj,
    required this.descrip,
    required this.amount,
    required this.fechae,
  });

  Map<String, dynamic> toJson() {
    return {
      "monto": amount,
      "codtarj": codtarj,
      "fechae": fechae,
      "descrip": descrip,
    };
  }
}

class SearchResultItem {
  final String id;
  final String description;
  final String? secondaryId;
  final double? price1;
  final double? pricei1;
  final Map<String, dynamic> originalData;

  SearchResultItem({
    required this.id,
    required this.description,
    this.secondaryId,
    this.price1,
    this.pricei1,
    required this.originalData,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json, String type) {
    switch (type) {
      case 'Cliente':
        return SearchResultItem(
          id: json['codclie'] as String? ?? '',
          description: json['descrip'] as String? ?? 'N/A',
          secondaryId: json['id3'] as String?,
          originalData: json,
        );
      case 'Producto':
        return SearchResultItem(
          id: json['codprod'] as String? ?? '',
          description: json['descrip'] as String? ?? 'N/A',
          price1: (json['precio1'] as num?)?.toDouble(),
          pricei1: (json['precioi1'] as num?)?.toDouble(),
          originalData: json,
        );
      case 'Vendedor':
        return SearchResultItem(
          id: json['codvend'] as String? ?? '',
          description: json['descrip'] as String? ?? 'N/A',
          originalData: json,
        );
      case 'Depósito':
         return SearchResultItem(
          id: json['codubic'] as String? ?? '',
          description: json['descrip'] as String? ?? 'N/A',
          originalData: json,
        );
      case 'InstrumentoPago':
         return SearchResultItem(
          id: json['codtarj'] as String? ?? '',
          description: json['descrip'] as String? ?? 'N/A',
          originalData: json,
        );
      default:
        return SearchResultItem(
          id: json['id']?.toString() ?? json.keys.firstWhere((k) => k.toLowerCase().contains("cod"), orElse: () => "N/A"),
          description: json['descrip']?.toString() ?? json.keys.firstWhere((k) => k.toLowerCase().contains("desc"), orElse: () => "N/A"),
          originalData: json,
        );
    }
  }
}