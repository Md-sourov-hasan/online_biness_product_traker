import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Failed to get connectivity: $e');
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    final connected = result.isNotEmpty && !result.contains(ConnectivityResult.none);
    final wasConnected = isConnected.value;
    isConnected.value = connected;
    
    // Only alert if transitioning from connected to disconnected and overlay context is active
    if (wasConnected && !connected && Get.context != null) {
      try {
        Get.rawSnackbar(
          title: 'No Internet',
          message: 'Please check your internet connection',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.redAccent,
        );
      } catch (e) {
        debugPrint('Could not display offline snackbar: $e');
      }
    }
  }

  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty && !result.contains(ConnectivityResult.none);
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}
