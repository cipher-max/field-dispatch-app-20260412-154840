import 'package:app/src/features/dispatch/customer_update_message.dart';
import 'package:app/src/shared/models/job.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds customer update with technician and eta', () {
    final job = Job(
      id: '1',
      customerName: 'Apex Fitness',
      address: '100 Main St',
      jobType: 'HVAC Tune-up',
      status: 'scheduled',
      priority: 'normal',
      technicianName: 'Chris',
      etaWindow: '2:00-4:00 PM',
    );

    final message = buildCustomerUpdateMessage(job);

    expect(
      message,
      'Hi Apex Fitness, Chris is scheduled for your HVAC Tune-up at 2:00-4:00 PM. We will text again if anything changes.',
    );
  });

  test('falls back to safe defaults when assignment is missing', () {
    final job = Job(
      id: '1',
      customerName: 'Beacon Dental',
      address: '200 Oak Ave',
      jobType: 'Plumbing Repair',
      status: 'new',
      priority: 'normal',
    );

    final message = buildCustomerUpdateMessage(job);

    expect(
      message,
      'Hi Beacon Dental, our technician is scheduled for your Plumbing Repair today. We will text again if anything changes.',
    );
  });

  test('uses in-progress copy with ETA when available', () {
    final job = Job(
      id: '2',
      customerName: 'Northside Bakery',
      address: '11 Cherry Ln',
      jobType: 'Electrical Repair',
      status: 'in_progress',
      priority: 'urgent',
      technicianName: 'Morgan',
      etaWindow: '3:15 PM',
    );

    final message = buildCustomerUpdateMessage(job);

    expect(
      message,
      'Hi Northside Bakery, Morgan is on the way for your Electrical Repair and should arrive by 3:15 PM.',
    );
  });

  test('uses completion copy for done jobs', () {
    final job = Job(
      id: '3',
      customerName: 'West Clinic',
      address: '500 River Dr',
      jobType: 'Filter Replacement',
      status: 'done',
      priority: 'normal',
      technicianName: 'Sam',
    );

    final message = buildCustomerUpdateMessage(job);

    expect(
      message,
      'Hi West Clinic, Sam has completed your Filter Replacement. Reply here if you need anything else.',
    );
  });
}
