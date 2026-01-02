import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/waypoint.dart';

/// Bottom sheet widget for displaying landmark information
class LandmarkInfoSheet extends StatelessWidget {
  final Waypoint landmark;
  final bool hasReached;

  const LandmarkInfoSheet({
    super.key,
    required this.landmark,
    required this.hasReached,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // City image (if available)
          if (landmark.cityImage != '-' && landmark.cityImage.isNotEmpty)
            _buildCityImage(landmark.cityImage),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // City name and status indicator
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        landmark.city,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusBadge(hasReached),
                  ],
                ),
                const SizedBox(height: 8),

                // Welcome message
                if (landmark.welcomeMessage != '-' &&
                    landmark.welcomeMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      landmark.welcomeMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // City description
                if (landmark.cityMessage != '-' &&
                    landmark.cityMessage.isNotEmpty)
                  Text(
                    landmark.cityMessage,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                const SizedBox(height: 16),

                // Steps info
                _buildStepsInfo(landmark, hasReached),

                const SizedBox(height: 20),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasReached
                          ? const Color(0xFF19b30b)
                          : const Color(0xFFFF9800), // Bright orange for locked
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black, // Black text on bright background
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityImage(String imageUrl) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: const Color(0xFFFFF3E0), // Light orange background
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF9800)),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: const Color(0xFFFFF3E0), // Light orange background
          child: const Icon(Icons.error, color: Color(0xFFFF5722)),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool hasReached) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasReached
            ? const Color(0xFFFFF9C4) // Light yellow for reached
            : const Color(0xFFFFE0B2), // Light orange for locked
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasReached ? Icons.check_circle : Icons.lock,
            size: 16,
            color: hasReached
                ? const Color(0xFFF57F17) // Dark yellow for reached
                : const Color(0xFFE65100), // Dark orange for locked
          ),
          const SizedBox(width: 4),
          Text(
            hasReached ? 'Reached' : 'Locked',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasReached
                  ? const Color(0xFFF57F17) // Dark yellow for reached
                  : const Color(0xFFE65100), // Dark orange for locked
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsInfo(Waypoint landmark, bool hasReached) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Light orange background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStepsStat(
              'Steps to reach',
              landmark.cumulativeSteps.toString(),
              Icons.directions_walk,
            ),
          ),
          if (landmark.stepsToNext > 0) ...[
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFFFF9800), // Orange divider
            ),
            Expanded(
              child: _buildStepsStat(
                'Steps to next',
                landmark.stepsToNext.toString(),
                Icons.arrow_forward,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepsStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFFE65100),
            ), // Dark orange icon
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100), // Dark orange numbers
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFE65100), // Dark orange label
          ),
        ),
      ],
    );
  }

  /// Show landmark info sheet
  static void show(BuildContext context, Waypoint landmark, int userSteps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LandmarkInfoSheet(
        landmark: landmark,
        hasReached: landmark.hasReached(userSteps),
      ),
    );
  }
}
