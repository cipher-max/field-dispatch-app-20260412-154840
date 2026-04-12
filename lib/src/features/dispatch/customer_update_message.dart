import '../../shared/models/job.dart';

String buildCustomerUpdateMessage(Job job) {
  final tech = job.technicianName?.trim();
  final eta = job.etaWindow?.trim();

  final techPart = (tech == null || tech.isEmpty) ? 'our technician' : tech;
  final hasEta = eta != null && eta.isNotEmpty;

  switch (job.status) {
    case 'in_progress':
      final etaPart = hasEta ? ' and should arrive by $eta' : '';
      return 'Hi ${job.customerName}, $techPart is on the way for your ${job.jobType}$etaPart.';
    case 'done':
      return 'Hi ${job.customerName}, $techPart has completed your ${job.jobType}. Reply here if you need anything else.';
    default:
      if (hasEta) {
        return 'Hi ${job.customerName}, $techPart is scheduled for your ${job.jobType} at $eta. We will text again if anything changes.';
      }

      return 'Hi ${job.customerName}, $techPart is scheduled for your ${job.jobType} today. We will text again if anything changes.';
  }
}
