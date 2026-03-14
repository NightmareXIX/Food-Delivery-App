import 'package:flutter/material.dart';

import '../common/color_extension.dart';

class MenuItemRow extends StatelessWidget {
  final Map mObj;
  final VoidCallback onTap;
  const MenuItemRow({super.key, required this.mObj, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Image.network(
              mObj["image_url"].toString(),
              width: double.infinity,  // you can also use double.infinity instead of maxFinite
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey[700]),
                );
              },
            ),
            Container(
              width: double.infinity,
              height: 200,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mObj["name"],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: TColor.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.asset(
                            "assets/img/rate.png",
                            width: 10,
                            height: 10,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            mObj["rating"].toString(),
                            textAlign: TextAlign.center,
                            style:
                            TextStyle(color: TColor.primary, fontSize: 11),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            mObj["store_name"],
                            textAlign: TextAlign.center,
                            style: TextStyle(color: TColor.white, fontSize: 11),
                          ),
                          // Text(
                          //   " . ",
                          //   textAlign: TextAlign.center,
                          //   style:
                          //   TextStyle(color: TColor.primary, fontSize: 11),
                          // ),
                          // Text(
                          //   mObj["food_type"],
                          //   textAlign: TextAlign.center,
                          //   style: TextStyle(color: TColor.white, fontSize: 12),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}