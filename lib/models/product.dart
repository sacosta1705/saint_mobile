class Product {
  final int id;
  final String sku;
  final String descrip1;
  final String descrip2;
  final String descrip3;
  final double price1;
  final double pricet1;
  final double price2;
  final double pricet2;
  final double price3;
  final double pricet3;
  final double stock;
  final bool iscompound;
  final bool hascomission;
  final bool hasserials;
  final bool haslots;
  final bool isexempt;

  Product({
    required this.id,
    required this.sku,
    required this.descrip1,
    required this.descrip2,
    required this.descrip3,
    required this.price1,
    required this.pricet1,
    required this.price2,
    required this.pricet2,
    required this.price3,
    required this.pricet3,
    required this.stock,
    required this.iscompound,
    required this.hascomission,
    required this.hasserials,
    required this.haslots,
    required this.isexempt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'], // Identificador unico
      sku: json['codprod'], // Codigo SKU creado por el usuario final
      descrip1: json['descrip'], // Primera parte del nombre del producto
      descrip2: json['descrip2'], // Segunda parte del nombre del porducto
      descrip3: json['descrip3'], // Tercera parte del nombre del producto
      price1: json['precio1'], // Precion 1 sin impuesto
      pricet1: json['precioi1'], // Precio 1 con impuesto
      price2: json['precio2'], // Precio 2 sin impuesto
      pricet2: json['precioi2'], // Precio 2 con impuesto
      price3: json['precio3'], // Precio 3 sin impuesto
      pricet3: json['precioi3'], // Precio 3 con impuesto
      stock: json['existen'], // Existencia en inventario del producto
      iscompound: json['descomp'], // Es un producto compuesto?
      hascomission: json['descomi'], // Es un producto con comision?
      hasserials: json['deesseri'], // Es un producto con serial?
      haslots: json['deslote'], // Es un producto con lotes?
      isexempt: json['esexento'], // Es un producto exento de impuesto?
    );
  }
}
