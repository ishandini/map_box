import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/waypoint.dart';

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
        color: AppColors.white,
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
                color: AppColors.lightGrey,
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.mediumGrey,
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
                          ? AppColors.progressGreen
                          : AppColors.statusLockedButton,
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
                        color: AppColors.black,
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
          color: AppColors.lightOrangeBackground,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.statusLockedButton,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: AppColors.lightOrangeBackground,
          child: const Icon(Icons.error, color: AppColors.errorBackground),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool hasReached) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasReached
            ? AppColors.statusReachedBackground
            : AppColors.statusLockedBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasReached ? Icons.check_circle : Icons.lock,
            size: 16,
            color: hasReached
                ? AppColors.statusReachedIcon
                : AppColors.statusLockedIcon,
          ),
          const SizedBox(width: 4),
          Text(
            hasReached ? 'Reached' : 'Locked',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasReached
                  ? AppColors.statusReachedIcon
                  : AppColors.statusLockedIcon,
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
        color: AppColors.lightOrangeBackground,
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
              color: AppColors.statusLockedButton,
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
            Icon(icon, size: 16, color: AppColors.statusLockedIcon),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.statusLockedIcon,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.statusLockedIcon,
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
