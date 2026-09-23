import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../projects/domain/project_provider.dart';

/// Show an interactive 1-5 star rating modal for a manager to rate an editor
Future<void> showRateEditorSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String editorId,
  required String editorName,
  String? editorPhotoUrl,
  String? projectId,
  String? projectTitle,
  bool isProjectApproval = false,
  VoidCallback? onApproved,
}) {
  final colors = context.colors;
  final currentUser = ref.read(authProvider).user;
  final agencyId = currentUser?.agencyId ?? 'agency_demo_wara';
  final managerName = currentUser?.name ?? 'Agency Director';

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      double selectedRating = 5.0;
      final noteCtrl = TextEditingController();
      final quickTags = ['🔥 Flawless Cut', '⚡ Fast Turnaround', '🎨 Superb Color', '🔊 Crisp Audio', '🎬 Creative Flow'];

      return StatefulBuilder(
        builder: (sheetContext, setModalState) {
          String getRatingLabel(double r) {
            if (r >= 5.0) return 'Exceptional • 5.0 Stars';
            if (r >= 4.0) return 'Great Deliverable • 4.0 Stars';
            if (r >= 3.0) return 'Standard Quality • 3.0 Stars';
            if (r >= 2.0) return 'Needs Polish • 2.0 Stars';
            return 'Below Standards • 1.0 Star';
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.muted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isProjectApproval ? 'Approve & Rate Deliverable' : 'Rate Creative Editor',
                              style: TextStyle(color: colors.text, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              projectTitle != null
                                  ? 'Project: $projectTitle'
                                  : 'Update editor performance & agency ranking',
                              style: TextStyle(color: colors.muted, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Editor Target Profile Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        WaraAvatar(
                          name: editorName,
                          photoUrl: editorPhotoUrl,
                          radius: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(editorName, style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold)),
                              Text('Production Contributor • In Agency Room', style: TextStyle(color: colors.muted, fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            'Editor',
                            style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Star Selector Row
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            final isFilled = selectedRating >= starIndex;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedRating = starIndex.toDouble();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: AnimatedScale(
                                  scale: selectedRating >= starIndex ? 1.15 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  child: Icon(
                                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: isFilled ? Colors.amber : colors.muted.withValues(alpha: 0.5),
                                    size: 38,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          getRatingLabel(selectedRating),
                          style: TextStyle(
                            color: Colors.amber.shade400,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Review Tags
                  Text('Quick Feedback Tags', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: quickTags.map((tag) {
                      return InkWell(
                        onTap: () {
                          setModalState(() {
                            final clean = tag.replaceFirst(RegExp(r'^[^\w\s]+\s*'), '');
                            if (noteCtrl.text.isEmpty) {
                              noteCtrl.text = clean;
                            } else if (!noteCtrl.text.contains(clean)) {
                              noteCtrl.text = '${noteCtrl.text}, $clean';
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(color: colors.text, fontSize: 11),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Feedback Notes Input
                  Text('Review Notes (Optional)', style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    style: TextStyle(color: colors.text, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. Stellar turnaround, flawless transitions and audio grading...',
                      hintStyle: TextStyle(color: colors.muted, fontSize: 12),
                      fillColor: colors.surface,
                      filled: true,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.primary)),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Action Buttons
                  Row(
                    children: [
                      if (isProjectApproval) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (projectId != null) {
                                ref.read(projectsProvider.notifier).approveProject(projectId);
                              }
                              Navigator.pop(sheetContext);
                              onApproved?.call();
                              WaraToast.show(
                                context,
                                message: '✅ Deliverable validated & payout approved!',
                                icon: Icons.check_circle_rounded,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: colors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Skip Rating', style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ] else ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: colors.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Cancel', style: TextStyle(color: colors.muted, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: isProjectApproval ? 2 : 1,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final note = noteCtrl.text.trim();
                            Navigator.pop(sheetContext);

                            // Rate in Firestore
                            await ref.read(firestoreServiceProvider).rateEditor(
                              agencyId: agencyId,
                              editorId: editorId,
                              rating: selectedRating,
                              projectId: projectId,
                              feedback: note.isNotEmpty ? note : null,
                              managerName: managerName,
                            );

                            // If project approval, approve the deliverable
                            if (isProjectApproval && projectId != null) {
                              ref.read(projectsProvider.notifier).approveProject(projectId);
                              onApproved?.call();
                            }

                            if (context.mounted) {
                              WaraToast.show(
                                context,
                                message: isProjectApproval
                                    ? '✅ Deliverable approved & ${selectedRating.toStringAsFixed(1)}★ awarded to $editorName!'
                                    : '⭐ Awarded ${selectedRating.toStringAsFixed(1)}★ rating to $editorName!',
                                icon: Icons.star_rounded,
                              );
                            }
                          },
                          icon: Icon(Icons.star_rounded, size: 18, color: colors.isDark ? Colors.black : Colors.white),
                          label: Text(
                            isProjectApproval ? 'Approve & Award ${selectedRating.toStringAsFixed(0)}★' : 'Submit Rating (${selectedRating.toStringAsFixed(0)}★)',
                            style: TextStyle(
                              color: colors.isDark ? Colors.black : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
