import 'package:flutter/material.dart';
import '../services/battery_service.dart';

class BatteryLevelIndicator extends StatefulWidget {
  final bool compact;
  final Color? textColor;

  const BatteryLevelIndicator({
    super.key,
    this.compact = false,
    this.textColor,
  });

  @override
  State<BatteryLevelIndicator> createState() => _BatteryLevelIndicatorState();
}

class _BatteryLevelIndicatorState extends State<BatteryLevelIndicator> with SingleTickerProviderStateMixin {
  int? _batteryLevel;
  bool _isLoading = false;
  String _statusMessage = 'Fetching battery...';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fetchBatteryLevel();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchBatteryLevel() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _pulseController.repeat(reverse: true);

    try {
      final level = await BatteryService.getBatteryLevel();
      if (!mounted) return;
      setState(() {
        _batteryLevel = level;
        _isLoading = false;
        if (level != null) {
          _statusMessage = 'Native Battery: $level%';
        } else {
          _statusMessage = 'Battery status unavailable (Web/Desktop)';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error reading battery';
      });
    } finally {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  Color _getBatteryColor(int? level) {
    if (level == null) return Colors.grey;
    if (level > 50) return const Color(0xFF00C853); // Fresh Green
    if (level > 20) return const Color(0xFFFF9100); // Amber Orange
    return const Color(0xFFFF3D00); // Red Alert
  }

  IconData _getBatteryIcon(int? level) {
    if (level == null) return Icons.battery_unknown;
    if (level >= 90) return Icons.battery_full;
    if (level >= 75) return Icons.battery_6_bar;
    if (level >= 50) return Icons.battery_4_bar;
    if (level >= 30) return Icons.battery_3_bar;
    if (level >= 15) return Icons.battery_2_bar;
    if (level >= 5) return Icons.battery_1_bar;
    return Icons.battery_alert;
  }

  void _showBatteryInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getBatteryIcon(_batteryLevel), color: _getBatteryColor(_batteryLevel)),
            const SizedBox(width: 10),
            const Text('Native Battery Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _batteryLevel != null
                  ? 'Current Native Battery: $_batteryLevel%'
                  : 'Battery MethodChannel responded with: Unavailable (Running on Web/Simulator/Unsupported host).',
              style: const TextStyle(fontSize: 14.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Channel: com.example.chat_application/battery\nMethod: getBatteryLevel()',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _fetchBatteryLevel();
            },
            child: const Text('Refresh', style: TextStyle(color: Color(0xFF0078FF))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0078FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batteryColor = _getBatteryColor(_batteryLevel);

    if (widget.compact) {
      return Tooltip(
        message: _statusMessage,
        child: InkWell(
          onTap: _showBatteryInfoDialog,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: batteryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: batteryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.8, color: batteryColor),
                  )
                else
                  Icon(
                    _getBatteryIcon(_batteryLevel),
                    size: 16,
                    color: batteryColor,
                  ),
                const SizedBox(width: 4),
                Text(
                  _batteryLevel != null ? '$_batteryLevel%' : 'N/A',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.textColor ?? batteryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: const Color(0xFFF8F9FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: _showBatteryInfoDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: batteryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getBatteryIcon(_batteryLevel), color: batteryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Device Battery',
                      style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _batteryLevel != null ? '$_batteryLevel% Charged' : 'MethodChannel (Web/Host)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _batteryLevel != null ? Colors.black87 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0078FF)),
                      )
                    : const Icon(Icons.refresh, size: 20, color: Color(0xFF0078FF)),
                tooltip: 'Refresh battery level',
                onPressed: _isLoading ? null : _fetchBatteryLevel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
