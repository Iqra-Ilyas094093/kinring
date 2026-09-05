import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Camera QR scanner for Join Group (product doc 5.6.2's "Scan QR Code"
/// button — previously a "coming soon" toast even though `mobile_scanner`
/// was already a dependency, just never wired to a real screen).
///
/// Pops with the decoded string (the invite code — same plain-text
/// payload [InviteMembersScreen]'s `QrImageView` encodes, so scanning
/// and typing converge on the exact same [GroupsViewModel.joinGroup]
/// path) the moment ANY code is detected — no manual "confirm" step,
/// since JoinGroupScreen itself still shows a "Group found" preview
/// before the user taps Join.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _popped = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_popped) return;
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.trim().isEmpty) return;
    _popped = true;
    Navigator.of(context).pop(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark1,
      appBar: AppBar(
        backgroundColor: AppColors.dark1,
        foregroundColor: AppColors.white,
        title: const Text('Scan Invite QR'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: AppColors.white,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.white, width: 3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          const Positioned(
            bottom: 48,
            child: Text(
              'Point your camera at a KinRing invite QR code',
              style: TextStyle(color: AppColors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
