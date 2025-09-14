import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import '../models/product.dart';

class DatabaseService extends ChangeNotifier {
  final Isar _isar;
  DatabaseService(this._isar);

  // 新增商品
  Future<void> addProduct(Product product) async {
    await _isar.writeTxn(() async {
      await _isar.products.put(product);
    });
    notifyListeners();
  }

  // 取得所有商品
  Future<List<Product>> getProducts() async {
    return await _isar.products.where().findAll();
  }
}
