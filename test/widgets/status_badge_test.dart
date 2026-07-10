import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dispatchr/features/jobs/job_status.dart';
import 'package:dispatchr/shared/widgets/status_badge.dart';

void main() {
  Widget wrap(Widget child, {Brightness brightness = Brightness.light}) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('StatusBadge', () {
    testWidgets('shows the label for each job status', (tester) async {
      for (final status in JobStatus.values) {
        await tester.pumpWidget(wrap(StatusBadge(status: status)));
        expect(find.text(status.label), findsOneWidget);
      }
    });

    testWidgets('updates its label when status changes', (tester) async {
      await tester.pumpWidget(
        wrap(const StatusBadge(status: JobStatus.pending)),
      );
      expect(find.text('Pending'), findsOneWidget);

      await tester.pumpWidget(
        wrap(const StatusBadge(status: JobStatus.inProgress)),
      );
      await tester.pumpAndSettle();

      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Pending'), findsNothing);
    });

    testWidgets('dense variant still renders the label', (tester) async {
      await tester.pumpWidget(
        wrap(const StatusBadge(status: JobStatus.completed, dense: true)),
      );
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('renders in dark mode without error', (tester) async {
      await tester.pumpWidget(
        wrap(
          const StatusBadge(status: JobStatus.pending),
          brightness: Brightness.dark,
        ),
      );
      expect(find.text('Pending'), findsOneWidget);
    });
  });
}
