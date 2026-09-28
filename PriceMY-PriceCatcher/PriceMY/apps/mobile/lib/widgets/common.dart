import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';

class Panel extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  const Tag(this.text, {super.key, this.color = lime});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
  );
}

class ProductArt extends StatelessWidget {
  final Product product;
  final double size;
  const ProductArt(this.product, {super.key, this.size = 90});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Color(int.parse('FF${product.color}', radix: 16)),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Center(
      child: Transform.rotate(
        angle: -.08,
        child: Container(
          width: size * .53,
          height: size * .73,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(product.unit == 'ml' ? 12 : 5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 8,
                offset: Offset(3, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                product.category == 'Household'
                    ? Icons.cleaning_services_outlined
                    : product.category == 'Bakery'
                    ? Icons.breakfast_dining_outlined
                    : Icons.eco_outlined,
                color: ink,
                size: size * .19,
              ),
              Text(
                product.brand.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: size * .075,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              Text(
                product.pack,
                style: TextStyle(fontSize: size * .075, color: muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget gap([double h = 16]) => SizedBox(height: h);
Widget section(String title, {Widget? action}) => Padding(
  padding: const EdgeInsets.only(top: 24, bottom: 14),
  child: Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
      ),
      if (action != null) action,
    ],
  ),
);
