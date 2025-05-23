import 'package:saint_mobile/models/payment_item.dart';
import 'package:saint_mobile/models/product_item.dart';

class Transaction {
  final String type;
  final String number;
  final String station;
  final String usercode;
  final String client;
  final String salesperson;
  final String clientname;
  final String address1;
  final String address2;
  final double taxbase;
  final double taxamount;
  final double exemptamount;
  final ProductItem items;
  final PaymentItem payitems;

  Transaction({
    required this.type,
    required this.number,
    required this.station,
    required this.usercode,
    required this.client,
    required this.salesperson,
    required this.clientname,
    required this.address1,
    required this.address2,
    required this.taxbase,
    required this.taxamount,
    required this.exemptamount,
    required this.items,
    required this.payitems,
  });
}
