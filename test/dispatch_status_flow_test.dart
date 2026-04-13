import 'package:app/src/features/dispatch/dispatch_status_flow.dart';
import 'package:app/src/features/jobs/domain/job_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nextDispatchStatus follows the standard dispatch lifecycle', () {
    expect(nextDispatchStatus(JobStatus.newJob), JobStatus.scheduled);
    expect(nextDispatchStatus(JobStatus.scheduled), JobStatus.inProgress);
    expect(nextDispatchStatus(JobStatus.inProgress), JobStatus.done);
    expect(nextDispatchStatus(JobStatus.done), isNull);
  });
}
