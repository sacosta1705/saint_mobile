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
